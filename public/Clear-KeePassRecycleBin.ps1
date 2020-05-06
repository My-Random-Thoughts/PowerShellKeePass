Function Clear-KeePassRecycleBin {
<#
    .SYNOPSIS
        Empty the recycle bin for the specified KeePass database

    .DESCRIPTION
        Empty the recycle bin for the specified KeePass database

    .PARAMETER KeePassDatabase
        Specifies the KeePass database object to use

    .EXAMPLE
        Clear-KeePassRecycleBin -KeePassDatabase $KeePassDatabase

    .NOTES
        For additional information please see my GitHub wiki page

    .LINK
        https://github.com/My-Random-Thoughts/PowerShellKeePass
#>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [KeePassLib.PwDatabase]$KeePassDatabase
    )

    Begin {
        If ($KeePassDatabase.IsOpen -eq $false) {
            Throw 'The KeePass database specified is not open'
        }

        If (-not $KeePassDatabase.RecycleBinEnabled)              { Return $null }
        If (     $KeePassDatabase.RecycleBinUuid.UuidBytes -eq 0) { Return $null }
        [KeePassLib.PwGroup]$kpRecycleBin = $($KeePassDatabase.RootGroup.FindGroup($KeePassDatabase.RecycleBinUuid, $true))
    }

    Process {
        $kpRecycleBin.DeleteAllObjects($KeePassDatabase)
        $KeePassDatabase.RecycleBinChanged = (Get-Date)
        $KeePassDatabase.Save($null)
    }

    End {
    }
}
