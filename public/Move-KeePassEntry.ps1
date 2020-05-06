Function Move-KeePassEntry {
<#
    .SYNOPSIS
        Move a KeePass entry

    .DESCRIPTION
        Move an entire KeePass entry from one group to another

    .PARAMETER KeePassDatabase
        Specifies the KeePass database object to use

    .PARAMETER Entry
        Specifies the entry to move

    .PARAMETER Destination
        Specifies the destination group of the move

    .EXAMPLE
        Move-KeePassEntry -KeePassDatabase $KeePassDatabase -Entry 'Sample Entry' -Destination '/Homebanking'

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
        [object]$Entry,

        [Parameter(Mandatory = $true)]
        [object]$Destination
    )

    Begin {
        If ($KeePassDatabase.IsOpen -eq $false) {
            Throw 'The KeePass database specified is not open'
        }

        [KeePassLib.PwEntry]$retSource      = (Test-KPIsValidEntry -KeePassDatabase $KeePassDatabase -InputObject $Entry)
        [KeePassLib.PwGroup]$retDestination = (Test-KPIsValidGroup -KeePassDatabase $KeePassDatabase -InputObject $Destination)
        Write-Verbose -Message "Moving '/$($retSource.ParentGroup.GetFullPath('/', $false))/$($retSource.Strings.ReadSafe('Title'))' to '/$($retDestination.GetFullPath('/', $false))'"
    }

    Process {
        $cloneSource = $retSource.CloneDeep()
        $retDestination.AddEntry($cloneSource, $true, $true)
        $retDestination.Touch($true, $true)
        [void]$retSource.ParentGroup.Entries.Remove($retSource)
        $retSource.ParentGroup.Touch($true, $true)
        $KeePassDatabase.Save($null)
    }

    End {
    }
}
