Function Disable-KeePassRecycleBin {
<#
    .SYNOPSIS
        Disable the recycle bin for the specified KeePass database

    .DESCRIPTION
        Disable the recycle bin for the specified KeePass database

    .PARAMETER KeePassDatabase
        Specifies the KeePass database object to use

    .PARAMETER RemoveGroup
        Specify to remove the recycle bin group, deleting all objects within it

    .EXAMPLE
        Disable-KeePassRecycleBin -KeePassDatabase $KeePassDatabase -RemoveGroup

    .NOTES
        For additional information please see my GitHub wiki page

    .LINK
        https://github.com/My-Random-Thoughts/PowerShellKeePass
#>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [KeePassLib.PwDatabase]$KeePassDatabase,

        [switch]$RemoveGroup
    )

    Begin {
        If ($KeePassDatabase.IsOpen -eq $false) {
            Throw 'The KeePass database specified is not open'
        }

        If (-not $KeePassDatabase.RecycleBinEnabled) {
            Write-Verbose -Message 'Nothing to do, recycle bin not enabled'
            Return
        }
    }

    Process {
        If ($RemoveGroup.IsPresent) {
            [KeePassLib.PwGroup]$kpRecycleBin = $($KeePassDatabase.RootGroup.FindGroup($KeePassDatabase.RecycleBinUuid, $true))
            Clear-KeePassRecycleBin -KeePassDatabase $KeePassDatabase
            Remove-KeePassGroup     -KeePassDatabase $KeePassDatabase -Group $kpRecycleBin -Force
            $KeePassDatabase.RecycleBinUuid = [KeePassLib.PwUuid]::Zero
        }

        $KeePassDatabase.RecycleBinEnabled = $false
        $KeePassDatabase.RecycleBinChanged = (Get-Date)
        Write-Verbose -Message 'Disabled recycle bin'
        $KeePassDatabase.Save($null)
    }

    End {
    }
}
