Function Set-KeePassRecycleBin {
<#
    .SYNOPSIS
        Sets the recycle bin to the specified group

    .DESCRIPTION
        Sets the recycle bin to the specified group

    .PARAMETER KeePassDatabase
        Specifies the KeePass database object to use

    .PARAMETER RecycleBinGroup
        Specifies the group to use for the recycle bin.  You can not use the root group.

    .EXAMPLE
        Set-KeePassRecycleBin -KeePassDatabase $KeePassDatabase -RecycleBinGroup 'RecycleBin'

    .EXAMPLE
        Set-KeePassRecycleBin -KeePassDatabase $KeePassDatabase -RecycleBinGroup '1234567890abcdef1234567890abcdef'

    .NOTES
        For additional information please see my GitHub wiki page

    .LINK
        https://github.com/My-Random-Thoughts/PowerShellKeePass
#>

    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [Parameter(Mandatory = $true)]
        [KeePassLib.PwDatabase]$KeePassDatabase,

        [Parameter(Mandatory = $true)]
        [object]$RecycleBinGroup
    )

    Begin {
        If ($KeePassDatabase.IsOpen -eq $false) {
            Throw 'The KeePass database specified is not open'
        }

        If ($RecycleBinGroup) {
            [KeePassLib.PwGroup]$newRecycleBin = (Test-KPIsValidGroup -KeePassDatabase $KeePassDatabase -InputObject $RecycleBinGroup)
            If ($newRecycleBin -eq $KeePassDatabase.RootGroup) {
                Throw 'Unable to use the root folder as the recycle bin'
            }
        }
    }

    Process {
        If ($PSCmdlet.ShouldProcess($($newRecycleBin.Name), 'Set As KeePass Recycle Bin')) {
            Confirm-KPRecycleBin -KeePassDatabase $KeePassDatabase -Group $RecycleBinGroup
        }
    }

    End {
    }
}
