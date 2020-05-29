Function Copy-KeePassEntry {
<#
    .SYNOPSIS
        Copy a KeePass entry, including all properties

    .DESCRIPTION
        Copy a KeePass entry, including all properties.  Either copy to the same parent group or specify a destination group

    .PARAMETER KeePassDatabase
        Specifies the KeePass database object to use

    .PARAMETER DestinationDatabase
        Specfied the destination KeePass database object to move too.  UseReferences can not be used when setting this parameter

    .PARAMETER Entry
        Specifies the entry to copy

    .PARAMETER Destination
        Specifies the destination group of the copy.  If left blank the destination will be the current group

    .PARAMETER AppendCopyToTitle
        Specifies to append the text "- Copy" to the end of the title

    .PARAMETER UseReferences
        Specifies to use KeePass references for the username and password fields

    .PARAMETER IncludeHistory
        Specifies to include the source entry history details

    .EXAMPLE
        Copy-KeePassEntry -KeePassDatabase $KeePassDatabase -Entry 'Sample Entry' -Destination '/Homebanking'

    .EXAMPLE
        Copy-KeePassEntry -KeePassDatabase $KeePassDatabase -Entry 'Sample Entry' -Destination '/Homebanking' -AppendCopyToTitle -UseReferences

    .EXAMPLE
        Copy-KeePassEntry -KeePassDatabase $KeePassDatabase -DestinationDatabase $DestDatabase -Entry 'Sample Entry' -Destination '/Homebanking'

    .NOTES
        For additional information please see my GitHub wiki page

    .LINK
        https://github.com/My-Random-Thoughts/PowerShellKeePass
#>

    [CmdletBinding(DefaultParameterSetName = '__default')]
    Param (
        [Parameter(Mandatory = $true)]
        [KeePassLib.PwDatabase]$KeePassDatabase,

        [Parameter(ParameterSetName = 'DestinationDatabase')]
        [KeePassLib.PwDatabase]$DestinationDatabase = $KeePassDatabase,

        [Parameter(Mandatory = $true)]
        [object]$Entry,

        [object]$Destination,

        [switch]$AppendCopyToTitle,

        [Parameter(ParameterSetName = 'UseReferences')]
        [switch]$UseReferences,

        [switch]$IncludeHistory
    )

    Begin {
        If ($KeePassDatabase.IsOpen     -eq $false) { Throw "The KeePass database '$($KeePassDatabase.Name)' is not open"     }
        If ($DestinationDatabase.IsOpen -eq $false) { Throw "The KeePass database '$($DestinationDatabase.Name)' is not open" }

        [KeePassLib.PwEntry]$retSource      = (Test-KPIsValidEntry -KeePassDatabase $KeePassDatabase -InputObject $Entry       -ErrorAction Stop)
        If (-not $Destination) { $Destination = $retSource.ParentGroup }
        [KeePassLib.PwGroup]$retDestination = (Test-KPIsValidGroup -KeePassDatabase $DestinationDatabase -InputObject $Destination -ErrorAction Stop)
        Write-Verbose -Message "Copying '/$($retSource.ParentGroup.GetFullPath('/', $false))/$($retSource.Strings.ReadSafe('Title'))' to '/$($retDestination.GetFullPath('/', $false))'"
    }

    Process {
        $dupEntry = (New-Object -TypeName 'KeePassLib.PwEntry'($true, $true))
        $dupEntry = $retSource.Duplicate()
        $retDestination.AddEntry($dupEntry, $true, $true)
        $retDestination.Touch($true, $true)

        If ($AppendCopyToTitle.IsPresent) {
            [string]$title = "$($dupEntry.Strings.ReadSafe('Title')) - Copy"
            $dupEntry.Strings.Set('Title', (New-Object -TypeName 'KeePassLib.Security.ProtectedString'($true, $title)))
        }

        If (($KeePassDatabase -eq $DestinationDatabase) -and ($UseReferences.IsPresent)) {
            [string]$username = "{REF:U@I:$($retSource.Uuid.ToHexString())}"
            $dupEntry.Strings.Set('UserName', (New-Object -TypeName 'KeePassLib.Security.ProtectedString'($true, $username)))

            [string]$password = "{REF:P@I:$($retSource.Uuid.ToHexString())}"
            $dupEntry.Strings.Set('Password', (New-Object -TypeName 'KeePassLib.Security.ProtectedString'($true, $password)))
        }

        If (-not $IncludeHistory.IsPresent) {
            $dupEntry.History.Clear()
        }

        $dupEntry.Touch($true, $true)
        $KeePassDatabase.Save($null)
        $DestinationDatabase.Save($null)
    }

    End {
    }
}
