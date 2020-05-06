Function Get-KeePassGroupTreeView {
<#
    .SYNOPSIS
        Show a tree view of all the groups and entries of the current database

    .DESCRIPTION
        Show a tree view of all the groups and entries of the current database

    .PARAMETER KeePassDatabase
        Specifies the KeePass database object to use

    .PARAMETER ShowEntries
        Specifies to include the entries in the treeview.  Defaults to just sub-groups

    .PARAMETER OutFile
        Specifies to output the tree diagram to a text file

    .EXAMPLE
        Get-KeePassGroupTreeView -KeePassDatabase $KeePassDatabase

    .EXAMPLE
        Get-KeePassGroupTreeView -KeePassDatabase $KeePassDatabase -ShowEntries -OutFile 'C:\SecureLocation\TreeView.txt'

    .NOTES
        For additional information please see my GitHub wiki page

    .LINK
        https://github.com/My-Random-Thoughts/PowerShellKeePass
#>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [KeePassLib.PwDatabase]$KeePassDatabase,

        [switch]$ShowEntries,

        [string]$OutFile
    )

    Begin {
            If ($KeePassDatabase.IsOpen -eq $false) {
            Throw 'The KeePass database specified is not open'
        }

    }

    Process {
        $gKPGTV = @{
            KeePassDatabase = $KeePassDatabase
            Group = $KeePassDatabase.RootGroup
            Level = 0
            OutFile = $OutFile
            ShowEntries = $ShowEntries.IsPresent
            LastGroupOfTheLevel = $false
            LastGroupAtThisLevelFlag = @()
            GroupsVisitedBeforeThisOne = @{}
        }

        If ($ShowEntries.IsPresent) {
            $gKPGTV += @{ Entries = $($KeePassDatabase.RootGroup.Entries) }
        }

        [void](Get-KPGroupTreeView @gKPGTV)
    }

    End {
    }
}
