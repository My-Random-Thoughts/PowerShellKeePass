Function Get-KPCustomIcon {
<#
    .SYNOPSIS
        Returns the PwCustomIcon object for a given index number

    .DESCRIPTION
        Returns the PwCustomIcon object for a given index number

    .PARAMETER KeePassDatabase
        Specifies the KeePass database object to search

    .PARAMETER Index
        Index number to return

    .EXAMPLE
        Get-KPCustomIcon -KeePassDatabase $KeePassDatabase -Index 3

    .NOTES
        For additional information please see my GitHub wiki page

    .LINK
        https://github.com/My-Random-Thoughts/PowerShellKeePass
#>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [KeePassLib.PwDatabase]$KeePassDatabase,

        [Parameter(Mandatory = $true)]
        [int]$Index
    )

    ForEach ($icon In $KeePassDatabase.CustomIcons) {
        $UuidIndex = $KeePassDatabase.GetCustomIconIndex($icon.Uuid)
        If ($UuidIndex -eq $Index) {
            Return ($icon -as [KeePassLib.PwCustomIcon])
        }
    }

    Return $null
}
