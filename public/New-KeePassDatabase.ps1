Function New-KeePassDatabase {
<#
    .SYNOPSIS
        Creates a new KeePass database file

    .DESCRIPTION
        Creates a new KeePass database file, optionally removing all the default example entries

    .PARAMETER FilePath
        Specifies the path to create the KeePass database file

    .PARAMETER MasterPassword
        If specified, will use a password to help unlock a database

    .PARAMETER KeyFile
        If specified, will use the key file to help unlock a database

    .PARAMETER UseWindowsUserAccount
        If set to $true, will use the currently logged on user account to help unlock a database

    .EXAMPLE
        New-KeePassDatabase -FilePath 'C:\SecureLocation\Database.kdbx' -MasterPassword 'Passw0rd!23' -KeeFile 'C:\SecureLocation\KeeFile.txt'

    .NOTES
        For additional information please see my GitHub wiki page

    .LINK
        https://github.com/My-Random-Thoughts/PowerShellKeePass
#>

    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [ValidateScript({ -not (Test-Path -Path $_) })]
        [string]$FilePath,

        [securestring]$MasterPassword,

        [ValidateScript({ Test-Path -Path $_ })]
        [string]$KeyFile,

        [switch]$UseWindowsUserAccount
    )

    Begin {
        # Check at least one authentication method has been used
        If ((-not $MasterPassword) -and (-not $KeyFile) -and (-not $UseWindowsUserAccount.IsPresent)) {
            Throw 'At least one authentication method must be used'
        }

        # Set up the required variables
        $PwDatabase     = (New-Object -TypeName 'KeePassLib.PwDatabase')
        $compositeKey   = (New-KPCompositeKey -MasterPassword $MasterPassword -KeyFile $KeyFile -UseWindowsUserAccount:$($UseWindowsUserAccount.IsPresent))
        $connectionInfo = (New-Object -TypeName 'KeePassLib.Serialization.IOConnectionInfo')
        $connectionInfo.Path = $FilePath
    }

    Process {
        Try {
            If ($PSCmdlet.ShouldProcess($FilePath, 'Creating new KeePass database')) {
                $PwDatabase.New($connectionInfo, $compositeKey) | Out-Null
                $PwDatabase.Save($null)
                Write-Verbose -Message 'KeePass database created successfully'

                $KeePassDatabase = (Open-KeePassDatabase -FilePath $FilePath -CompositeKey $compositeKey)
                Return $KeePassDatabase
            }
        }
        Catch {
            Throw $_
        }
    }

    End {
    }
}
