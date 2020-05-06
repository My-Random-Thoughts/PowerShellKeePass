Function Move-KeePassGroup {
<#
    .SYNOPSIS
        Move a KeePass group

    .DESCRIPTION
        Move a KeePass group

    .PARAMETER KeePassDatabase
        Specifies the KeePass database object to use

    .PARAMETER Group
        Specifies the group to move

    .PARAMETER Destination
        Specifies the destination group of the move

    .EXAMPLE
        Move-KeePassGroup -KeePassDatabase $KeePassDatabase -Entry 'General' -Destination '/Homebanking'

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
        [object]$Group,

        [Parameter(Mandatory = $true)]
        [object]$Destination
    )

    Begin {
        If ($KeePassDatabase.IsOpen -eq $false) {
            Throw 'The KeePass database specified is not open'
        }

        [KeePassLib.PwGroup]$retSource      = (Test-KPIsValidGroup -KeePassDatabase $KeePassDatabase -InputObject $Group)
        [KeePassLib.PwGroup]$retDestination = (Test-KPIsValidGroup -KeePassDatabase $KeePassDatabase -InputObject $Destination)
        Write-Verbose -Message "Moving '/$($retSource.GetFullPath('/', $false))' to '/$($retDestination.GetFullPath('/', $false))'"
    }

    Process {
        $cloneSource = $retSource.CloneDeep()
        $retDestination.AddGroup($cloneSource, $true, $true)
        $retDestination.Touch($true, $true)
        [void]$retSource.ParentGroup.Groups.Remove($retSource)
        $retSource.ParentGroup.Touch($true, $true)
        $KeePassDatabase.Save($null)
    }

    End {
    }
}
