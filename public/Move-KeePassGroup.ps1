Function Move-KeePassGroup {
<#
    .SYNOPSIS
        Move a KeePass group

    .DESCRIPTION
        Move a KeePass group

    .PARAMETER KeePassDatabase
        Specifies the KeePass database object to use

    .PARAMETER DestinationDatabase
        Specfied the destination KeePass database object to move too

    .PARAMETER Group
        Specifies the group to move

    .PARAMETER Destination
        Specifies the destination group of the move

    .EXAMPLE
        Move-KeePassGroup -KeePassDatabase $KeePassDatabase -Entry 'General' -Destination '/Homebanking'

    .EXAMPLE
        Move-KeePassGroup -KeePassDatabase $KeePassDatabase -DestinationDatabase $DestDatabase -Entry 'General' -Destination '/Homebanking'

    .NOTES
        For additional information please see my GitHub wiki page

    .LINK
        https://github.com/My-Random-Thoughts/PowerShellKeePass
#>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [KeePassLib.PwDatabase]$KeePassDatabase,

        [KeePassLib.PwDatabase]$DestinationDatabase = $KeePassDatabase,

        [Parameter(Mandatory = $true)]
        [object]$Group,

        [Parameter(Mandatory = $true)]
        [object]$Destination
    )

    Begin {
        If ($KeePassDatabase.IsOpen     -eq $false) { Throw "The KeePass database '$($KeePassDatabase.Name)' is not open"     }
        If ($DestinationDatabase.IsOpen -eq $false) { Throw "The KeePass database '$($DestinationDatabase.Name)' is not open" }

        [KeePassLib.PwGroup]$retSource      = (Test-KPIsValidGroup -KeePassDatabase $KeePassDatabase     -InputObject $Group      )
        [KeePassLib.PwGroup]$retDestination = (Test-KPIsValidGroup -KeePassDatabase $DestinationDatabase -InputObject $Destination)
        Write-Verbose -Message "Moving '/$($retSource.GetFullPath('/', $false))' to '/$($retDestination.GetFullPath('/', $false))'"
    }

    Process {
        $cloneSource = $retSource.CloneDeep()
        $retDestination.AddGroup($cloneSource, $true, $true)
        $retDestination.Touch($true, $true)

        [void]$retSource.ParentGroup.Groups.Remove($retSource)
        $retSource.ParentGroup.Touch($true, $true)

        $KeePassDatabase.Save($null)
        $DestinationDatabase.Save($null)
    }

    End {
    }
}
