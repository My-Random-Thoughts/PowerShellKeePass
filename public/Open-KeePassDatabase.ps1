Function Open-KeePassDatabase {
<#
    .SYNOPSIS
        Opens the specified KeePass database file

    .DESCRIPTION
        Opens the specified KeePass database file

    .PARAMETER FilePath
        Specifies the KeePass database path to open

    .PARAMETER MasterPassword
        If specified, will use a password to help unlock a database

    .PARAMETER KeyFile
        If specified, will use the key file to help unlock a database

    .PARAMETER UseWindowsUserAccount
        If set to $true, will use the currently logged on user account to help unlock a database

    .PARAMETER CompositeKey
        Specifies a fully complete composite key instead of separated values

    .EXAMPLE
        Open-KeePassDatabase -FilePath 'C:\SecureLocation\Database.kdbx' -MasterPassword 'Passw0rd!23' -KeeFile 'C:\SecureLocation\KeeFile.txt'

    .NOTES
        For additional information please see my GitHub wiki page

    .LINK
        https://github.com/My-Random-Thoughts/PowerShellKeePass
#>

    [CmdletBinding(DefaultParameterSetName = '__default')]
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path -Path $_ })]
        [string]$FilePath,

        [Parameter(ParameterSetName = 'separate')]
        [securestring]$MasterPassword,

        [Parameter(ParameterSetName = 'separate')]
        [ValidateScript({ Test-Path -Path $_ })]
        [string]$KeyFile,

        [Parameter(ParameterSetName = 'separate')]
        [switch]$UseWindowsUserAccount,

        [Parameter(ParameterSetName = 'composite')]
        [KeePassLib.Keys.CompositeKey]$CompositeKey
    )

    Begin {
        # Check at least one authentication method has been used
        If ((-not $MasterPassword) -and (-not $KeyFile) -and (-not $UseWindowsUserAccount.IsPresent) -and (-not $CompositeKey)) {
            Throw 'At least one authentication method must be used'
        }

        # Set up the required variables
        $kpDatabase     = (New-Object -TypeName 'KeePassLib.PwDatabase')
        $connectionInfo = (New-Object -TypeName 'KeePassLib.Serialization.IOConnectionInfo')
        $connectionInfo.Path = $FilePath

        If ($PSCmdlet.ParameterSetName -eq 'separate') {
            $CompositeKey = (New-KPCompositeKey -MasterPassword $MasterPassword -KeyFile $KeyFile -UseWindowsUserAccount:$($UseWindowsUserAccount.IsPresent))
        }
    }

    Process {
        Try {
            $kpDatabase.Open($connectionInfo, $CompositeKey, $null)
        }
        Catch [KeePassLib.Keys.InvalidCompositeKeyException] {
            Throw "Incorrect password: $($_.Exception.Message)"
        }
        Catch {
            Throw $_
        }

        Write-Verbose -Message 'Database opened successfully'
        Return $kpDatabase
    }

    End {
    }
}
