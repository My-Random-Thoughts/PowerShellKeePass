Function Set-KeePassDatabaseSetting {
<#
    .SYNOPSIS
        Set the KeePass database settings

    .DESCRIPTION
        Set the KeePass database settings when the default settings are not enough.  Only those settings specified will be set.

    .PARAMETER KeePassDatabase
        Specifies the KeePass database object to search

    .PARAMETER Name
        Specifiy the name of the database

    .PARAMETER Description
        Specify the description of the database

    .PARAMETER DefaultUserName
        Specify the default username for new entries

    .PARAMETER Colour
        Specify the database colour

    .PARAMETER EncryptionCipher
        Specify the database encryption cipher

    .PARAMETER UseAesKdf
        Specify the database key derivation function as AES

    .PARAMETER UseAgron2Kdf
        Specify the database key derivation function as Argon2

    .PARAMETER KeyIterations
        Specify the KDF interations.  Set this to -1 to have KeePass calculate this value

    .PARAMETER Argon2Memory
        Specify the Argon2 memory usage

    .PARAMETER Argon2Parallelism
        Specify the Argon2 parallelism usage

    .PARAMETER Compression
        Specify the database compression algorithm

    .PARAMETER UseRecycleBin
        Specify to use the Recycle Bin

    .PARAMETER EntryTemplateGroup
        Specify the ????

    .PARAMETER HistoryMaxItems
        Specify the limit of history items per entry

    .PARAMETER HistoryMaxSizeMB
        Specify the limit of the history size per entry

    .PARAMETER RecommendChangeMasterPassword
        Specify the number of days to recommend changing the master password

    .PARAMETER ForceChangeMasterPassword
        Specify the number of days to force changing the master password

    .PARAMETER ForceChangeMasterPasswordNextTime
        Specify the forcing the master password to change next time

    .EXAMPLE
        Set-KeePassDatabaseSetting -KeePassDatabase $KeePassDatabase -Name 'Secure Password Database' -Colour Blue -Compression GZip

    .EXAMPLE
        Set-KeePassDatabaseSetting -KeePassDatabase $KeePassDatabase -UseAesKdf -KeyIterations -1 -Verbose

    .NOTES
        For additional information please see my GitHub wiki page

    .LINK
        https://github.com/My-Random-Thoughts/PowerShellKeePass
#>

    [CmdletBinding(DefaultParameterSetName = '__default', SupportsShouldProcess)]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingUserNameAndPassWordParams', '', Scope = 'Function')]    # False positive
    Param (
        [Parameter(Mandatory = $true)]
        [KeePassLib.PwDatabase]$KeePassDatabase,

        [string]$Name,

        [string]$Description,

        [string]$DefaultUserName,

        [ValidateSet('None', 'Blue', 'Green', 'Red', 'Yellow')]
        [string]$Colour,

        [ValidateSet('AES/Rijndael', 'ChaCha20')]
        [string]$EncryptionCipher,

        [Parameter(ParameterSetName = 'Aes')]
        [switch]$UseAesKdf,

        [Parameter(ParameterSetName = 'Ar2')]
        [switch]$UseAgron2Kdf,

        [int]$KeyIterations,

        [Parameter(ParameterSetName = 'Ar2')]
        [int]$Argon2Memory,

        [Parameter(ParameterSetName = 'Ar2')]
        [int]$Argon2Parallelism,

        [ValidateSet('GZip', 'None')]
        [string]$Compression,

        [boolean]$UseRecycleBin,

        [object]$EntryTemplateGroup,

        [int]$HistoryMaxItems,

        [int]$HistoryMaxSizeMB,

        [int]$RecommendChangeMasterPassword,

        [int]$ForceChangeMasterPassword,

        [switch]$ForceChangeMasterPasswordNextTime
    )

    Begin {
        If ($KeePassDatabase.IsOpen -eq $false) {
            Throw 'The KeePass database specified is not open'
        }

        [string]$KeyDerivationFunction = $null
        If ($UseAesKdf.IsPresent)    { $KeyDerivationFunction = 'Aes-Kdf' }
        If ($UseAgron2Kdf.IsPresent) { $KeyDerivationFunction = 'Argon2'  }

        # Get current Security values
        [string]$currCipher = (([KeePassLib.Cryptography.Cipher.CipherPool]::GlobalPool).GetCipher($KeePassDatabase.DataCipherUuid).DisplayName)

        [object]$currKdfParameters = $KeePassDatabase.KdfParameters
        [KeePassLib.PwUuid]$engineUuid = ($currKdfParameters).GetByteArray('$UUID')
        ForEach ($engine in ([KeePassLib.Cryptography.KeyDerivation.KdfPool]::Engines)) {
            If ($engineUuid -eq $engine.Uuid) {
                [string]$currKdfEngineName = $engine.Name
                [uint64]$kdfParam_R = $currKdfParameters.GetUInt64('R', 0)    # Aes: Rounds
                [uint64]$kdfParam_I = $currKdfParameters.GetUInt64('I', 0)    # Ar2: Interations
                [uint64]$kdfParam_M = $currKdfParameters.GetUInt64('M', 0)    # Ar2: Memory
                [uint32]$kdfParam_P = $currKdfParameters.GetUInt32('P', 0)    # Ar2: Parallelism
            }
        }

        If ([string]::IsNullOrEmpty($KeyDerivationFunction)) {
            $KeyDerivationFunction = $currKdfEngineName
        }

        If (($KeyIterations -eq -1) -and (($Argon2Memory -gt 0) -or ($Argon2Parallelism -gt 0))) {
            Write-Warning -Message 'Argon2Memory and Argon2Parallelism will be ignored.  KeyIterations has been set to -1'
        }

        If ($KeyIterations -eq -1) {
            If ([string]::IsNullOrEmpty($KeyDerivationFunction)) { $KeyDerivationFunction = $currKdfEngineName }
            Write-Verbose -Message "Please wait, calculating 1 second delay for $KeyDerivationFunction..."
            $generatedKdfParameters = (Get-KPKDFOneSecondInteration -KeyDerivationFunction $KeyDerivationFunction)
        }

        If ($EntryTemplateGroup) {
            If ($EntryTemplateGroup -eq 'None') {
                [KeePassLib.PwUuid]$EntryTemplateGroup = ([KeePassLib.PwUuid]::Zero)
            } Else {
                [KeePassLib.PwUuid]$EntryTemplateGroup = (Test-KPIsValidGroup -KeePassDatabase $KeePassDatabase -InputObject $EntryTemplateGroup).Uuid
            }
        }

        If ($HistoryMaxSizeMB -gt 0) {
            $HistoryMaxSizeMB = ($HistoryMaxSizeMB * 1mb)
        }

        $lookupTable = @{
        #   Parameter Name                    =  KeePass Name|Separate change property.
            Name                              = 'Name|NameChanged'
            Description                       = 'Description|DescriptionChanged'
            DefaultUserName                   = 'DefaultUserName|DefaultUserNameChanged'
            Colour                            = 'X'    #
            EncryptionCipher                  = 'X'    #
            UseAesKdf                         = 'X'    #
            UseAgron2Kdf                      = 'X'    #
            KeyIterations                     = 'X'    #
            Argon2Memory                      = 'X'    #
            Argon2Parallelism                 = 'X'    #
            UseRecycleBin                     = 'X|RecycleBinChanged'
            Compression                       = 'Compression'
            EntryTemplateGroup                = 'EntryTemplatesGroup|EntryTemplatesGroupChanged'
            HistoryMaxItems                   = 'HistoryMaxItems'
            HistoryMaxSizeMB                  = 'HistoryMaxSize'
            RecommendChangeMasterPassword     = 'MasterKeyChangeRec'
            ForceChangeMasterPassword         = 'MasterKeyChangeForce'
            ForceChangeMasterPasswordNextTime = 'MasterKeyChangeForceOnce'
        }
    }

    Process {
        ForEach ($param In $PSBoundParameters.Keys) {
            If ([string]::IsNullOrEmpty($($lookupTable[$param]))) { Continue }

            $paramValue = (Get-Variable -Name $param -ValueOnly)
            $lookupItem, $changed = $($lookupTable[$param]).Split('|')

            Switch ($param) {
                'Colour' {
                    If ($paramValue -eq 'None') { [System.Drawing.Color]$nColour = 0 } Else { [System.Drawing.Color]$nColour = $paramValue }
                    If ($KeePassDatabase.Color.Name -ne $nColour.Name) {
                        If ($PSCmdlet.ShouldProcess('Database Settings', "Changing $param to $paramValue")) {
                            $KeePassDatabase.Color = $nColour
                        }
                    }
                }

                'UseRecycleBin' {
                    If ($paramValue -eq $true) {
                        Enable-KeePassRecycleBin -KeePassDatabase $KeePassDatabase
                    }
                    Else {
                        Disable-KeePassRecycleBin -KeePassDatabase $KeePassDatabase
                    }
                }

                'EncryptionCipher' {
                    If ($EncryptionCipher -ne ($currCipher.Split(' ')[0])) {
                        If ($PSCmdlet.ShouldProcess('Database Settings', "Changing $param to $paramValue")) {
                            $globalPool = ([KeePassLib.Cryptography.Cipher.CipherPool]::GlobalPool)
                            1..($globalPool.EngineCount) | ForEach-Object {
                                If (($globalPool.Item($_ -1).DisplayName) -like "$EncryptionCipher*") {
                                    $KeePassDatabase.DataCipherUuid = (([KeePassLib.Cryptography.Cipher.CipherPool]::GlobalPool).Item($_ - 1).CipherUuid)
                                }
                            }
                        }
                    }
                }

                {($_ -eq 'UseAesKdf') -or
                 ($_ -eq 'UseArgon2')} {
                    If ($currKdfEngineName -ne $KeyDerivationFunction) {
                        If ($PSCmdlet.ShouldProcess('Database Settings', "Changing $param to $paramValue")) {
                            [KeePassLib.PwUuid]$engineUuid = (([KeePassLib.Cryptography.KeyDerivation.KdfPool]::Engines) | Where-Object { $_.Name -eq $KeyDerivationFunction}).Uuid
                            $KeePassDatabase.KdfParameters = (Get-KPKDFOneSecondInteration -KeyDerivationFunction $KeyDerivationFunction -UseDefaultValues)
                            If ($KeyIterations -eq -1) {
                                $KeePassDatabase.KdfParameters = $generatedKdfParameters
                            }
                        }
                    }
                }

                'KeyIterations' {
                    If ($KeyIterations -eq -1) {
                        $KeePassDatabase.KdfParameters = $generatedKdfParameters
                    }
                    Else {
                        If (($KeyIterations -ne $kdfParam_R) -and ($KeyIterations -ne $kdfParam_I)) {
                            If ($PSCmdlet.ShouldProcess('Database Settings', "Changing $param to $paramValue")) {
                                Switch ($KeyDerivationFunction) {
                                    'Aes-Kdf' { $KeePassDatabase.KdfParameters.SetUInt64('R', ($KeyIterations -as [uint64])) }
                                    'Argon2'  { $KeePassDatabase.KdfParameters.SetUInt64('I', ($KeyIterations -as [uint64])) }
                                    Default   { Throw "Invalid KeyDerivationFunction: $KeyDerivationFunction" }
                                }
                            }
                        }
                    }
                }

                'Argon2Memory' {
                    If ($KeyIterations -eq -1) { Continue }
                    $Argon2Memory = ($Argon2Memory * 1MB)
                    If ($Argon2Memory -ne $kdfParam_M) {
                        If ($PSCmdlet.ShouldProcess('Database Settings', "Changing $param to $paramValue")) {
                            $KeePassDatabase.KdfParameters.SetUInt64('M', ($Argon2Memory -as [uint64]))
                        }
                    }
                }

                'Argon2Parallelism' {
                    If ($KeyIterations -eq -1) { Continue }
                    If ($Argon2Parallelism -ne $kdfParam_P) {
                        If ($PSCmdlet.ShouldProcess('Database Settings', "Changing $param to $paramValue")) {
                            $KeePassDatabase.KdfParameters.SetUInt32('P', ($Argon2Parallelism -as [uint32]))
                        }
                    }
                }

                Default {
                    If ($KeePassDatabase.$lookupItem -ne $paramValue) {
                        If ($PSCmdlet.ShouldProcess('Database Settings', "Changing $param to $paramValue")) {
                            $KeePassDatabase.$lookupItem = $paramValue
                            If ($changed) { $KeePassDatabase.$changed = (Get-Date) }
                        }
                    }
                }
            }
        }

        $KeePassDatabase.SettingsChanged = (Get-Date)
        $KeePassDatabase.Save($null)
    }

    End {
    }
}
