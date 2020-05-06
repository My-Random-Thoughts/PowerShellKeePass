Function Confirm-KPRecycleBin {
<#
    .SYNOPSIS
        Creates the RecycleBin folder if required

    .DESCRIPTION
        Creates the RecycleBin folder if required.  If the recycle bin is not enabled this function will return $null.

    .PARAMETER KeePassDatabase
        Specifies the KeePass database object to search

    .PARAMETER Group
        Specifies the group to use for the recycle bin.  If not specified, one wil be automatically created

    .EXAMPLE
        Confirm-KPRecycleBin -KeePassDatabase $KeePassDatabase

    .NOTES
        For additional information please see my GitHub wiki page

    .LINK
        https://github.com/My-Random-Thoughts/PowerShellKeePass
#>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [KeePassLib.PwDatabase]$KeePassDatabase,

        [object]$Group
    )

# BEGIN
    If ($KeePassDatabase.IsOpen -eq $false) {
        Throw 'The KeePass database specified is not open'
    }

    If (-not $KeePassDatabase.RecycleBinEnabled) {
        Write-Warning -Message 'Recycle bin not enabled for this database'
        Return $null
    }

    If ($KeePassDatabase.RecycleBinUuid.UuidBytes -ne 0) {
        Write-Verbose -Message 'Recycle bin already set for this database'
        Return $($KeePassDatabase.RootGroup.FindGroup($KeePassDatabase.RecycleBinUuid, $true))
    }

    If ($newRecycleBin -eq $KeePassDatabase.RootGroup) {
        Write-Warning -Message 'Unable to use the root folder as the recycle bin, using default location'
        $Group -eq $null
    }

# PROCESS
    If (-not [string]::IsNullOrEmpty($Group)) {
        Write-Verbose -Message 'Using existing group for the new recycle bin'
        [KeePassLib.PwGroup]$newRecycleBin = (Test-KPIsValidGroup -KeePassDatabase $KeePassDatabase -InputObject $Group)
    }
    Else {
        Write-Verbose -Message 'Creating new recycle bin group'
        $newRecycleBin = [KeePassLib.PwGroup]::New($true, $true, [KeePass.Resources.KPRes]::RecycleBin, [KeePassLib.PwIcon]::TrashBin)
        $KeePassDatabase.RootGroup.AddGroup($newRecycleBin, $true)
    }

    $newRecycleBin.EnableAutoType  = $false
    $newRecycleBin.EnableSearching = $false
    $KeePassDatabase.RecycleBinUuid = $newRecycleBin.Uuid
    $KeePassDatabase.RecycleBinChanged = (Get-Date)
    $KeePassDatabase.Save($null)

    Return $newRecycleBin
}
