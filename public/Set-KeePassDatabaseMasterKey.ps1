Function Set-KeePassDatabaseMasterKey {
<#
    .SYNOPSIS
        Set the specified KeePass databases master key

    .DESCRIPTION
        Set the specified KeePass databases master key

    .PARAMETER KeePassDatabase
        Specifies the KeePass database object to set

    .PARAMETER MasterPassword
        If specified, will use a password to help unlock a database

    .PARAMETER KeyFile
        If specified, will use the key file to help unlock a database

    .PARAMETER UseWindowsUserAccount
        If set to $true, will use the currently logged on user account to help unlock a database

    .EXAMPLE
        Set-KeePassDatabaseMasterKey -KeePassDatabase $KeePassDatabase -MasterPassword 'Passw0rd!23' -KeeFile 'C:\SecureLocation\KeeFile.txt'

    .NOTES
        For additional information please see my GitHub wiki page

    .LINK
        https://github.com/My-Random-Thoughts/PowerShellKeePass
#>

    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [Parameter(Mandatory = $true)]
        [KeePassLib.PwDatabase]$KeePassDatabase,

        [securestring]$MasterPassword,

        [ValidateScript({ Test-Path -Path $_ })]
        [string]$KeyFile,

        [switch]$UseWindowsUserAccount
    )

    Begin {
        If ($KeePassDatabase.IsOpen -eq $false) {
            Throw 'The KeePass database specified is not open'
        }
    }

    Process {
        Try {
            If ($PSCmdlet.ShouldProcess('Database Master Key', 'Setting new master key')) {
                $KeePassDatabase.MasterKey = (New-KPCompositeKey -MasterPassword $MasterPassword -KeyFile $KeyFile -UseWindowsUserAccount $UseWindowsUserAccount.IsPresent)
                $KeePassDatabase.MasterKeyChanged = (Get-Date)
                $KeePassDatabase.Save($null)
                Write-Verbose -Message 'Master password has been changed'
            }
        }
        Catch {
            Throw $_
        }
    }

    End {
    }
}
