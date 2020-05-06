Function New-KPCompositeKey {
<#
    .SYNOPSIS
        Creates a new database composite key

    .DESCRIPTION
        Creates a new database composite key used for locking and unlocking a secure database file

    .PARAMETER MasterPassword
        If specified, will use a password to help unlock a database

    .PARAMETER KeyFile
        If specified, will use the key file to help unlock a database

    .PARAMETER UseWindowsUserAccount
        If set to $true, will use the currently logged on user account to help unlock a database

    .EXAMPLE
        New-KPCompositeKey -MasterPassword 'Passw0rd'

    .EXAMPLE
        New-KPCompositeKey -KeyFile 'C:\SecureLocation\KeyFile.txt'

    .EXAMPLE
        New-KPCompositeKey -MasterPassword 'Password' -UseWindowsUserAccount

    .EXAMPLE
        New-KPCompositeKey

    .NOTES
        For additional information please see my GitHub wiki page

    .LINK
        https://github.com/My-Random-Thoughts/PowerShellKeePass
#>

    [CmdletBinding()]
    Param (
        [securestring]$MasterPassword = $null,

        [string]$KeyFile = $null,

        [boolean]$UseWindowsUserAccount = $false
    )

    Begin {
        # Check at least one authentication method has been used
        If ((-not $MasterPassword) -and (-not $KeyFile) -and (-not $UseWindowsUserAccount.IsPresent)) {
            Throw 'At least one authentication method must be used'
        }
    }

    Process {
        $compositeKey = (New-Object -TypeName 'KeePassLib.Keys.CompositeKey')

        If ($MasterPassword) {
            $compositeKey.AddUserKey(
                (New-Object -TypeName 'KeePassLib.Keys.KcpPassword'(
                    $(ConvertTo-KPPlainText -InputString $MasterPassword))
                )
            )
        }

        If ($KeyFile) {
            If (Test-Path -Path $KeyFile) {
                $compositeKey.AddUserKey(
                    (New-Object -TypeName 'KeePassLib.Keys.KcpKeyFile'($KeyFile))
                )
            }
        }

#TODO:   If ($CustomKey) {
#            $compositeKey.AddUserKey(([KeePassLib.Keys.KcpCustomKey]::New('null', $null, $false)))
#        }

        If ($UseWindowsUserAccount) {
            $compositeKey.AddUserKey(
                (New-Object -TypeName 'KeePassLib.Keys.KcpUserAccount')
            )
        }

        Return $compositeKey
    }

    End {
    }
}
