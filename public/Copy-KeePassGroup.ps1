Function Copy-KeePassGroup {
<#
    .SYNOPSIS
        Copy a KeePass group, including all child entries and groups

    .DESCRIPTION
        Copy a KeePass group, including all child entries and groups

    .PARAMETER KeePassDatabase
        Specifies the KeePass database object to use

    .PARAMETER Group
        Specifies the group to copy

    .PARAMETER Destination
        Specifies the destination group of the copy

    .PARAMETER AppendCopyToTitle
        Specifies to append the text "- Copy" to the end of the title for each entry

    .PARAMETER UseReferences
        Specifies to use KeePass references for the username and password fields for each entry

    .PARAMETER IncludeHistory
        Specifies to include the source entry history details for each entry

    .EXAMPLE
        Copy-KeePassGroup -KeePassDatabase $KeePassDatabase -Entry 'General' -Destination '/Homebanking'

    .EXAMPLE
        Copy-KeePassGroup -KeePassDatabase $KeePassDatabase -Entry 'General' -Destination '/Homebanking' -AppendCopyToTitle -UseReferences

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
        [object]$Destination,

        [switch]$AppendCopyToTitle,

        [switch]$UseReferences,

        [switch]$IncludeHistory
    )

    Begin {
        If ($KeePassDatabase.IsOpen -eq $false) {
            Throw 'The KeePass database specified is not open'
        }

        [KeePassLib.PwGroup]$retSource      = (Test-KPIsValidGroup -KeePassDatabase $KeePassDatabase -InputObject $Group       -ErrorAction Stop)
        [KeePassLib.PwGroup]$retDestination = (Test-KPIsValidGroup -KeePassDatabase $KeePassDatabase -InputObject $Destination -ErrorAction Stop)
        Write-Verbose -Message "Copying '/$($retSource.GetFullPath('/', $false))' to '/$($retDestination.GetFullPath('/', $false))'"
    }

    Process {
        $dupGroup = (New-Object -TypeName 'KeePassLib.PwGroup')
        $dupGroup = $retSource.Duplicate()
        $retDestination.AddGroup($dupGroup, $true, $true)
        $retDestination.Touch($true, $true)

        ForEach ($dupEntry In $dupGroup.GetEntries($true)) {
            If ($AppendCopyToTitle.IsPresent) {
                [string]$title = "$($dupEntry.Strings.ReadSafe('Title')) - Copy"
                $dupEntry.Strings.Set('Title', (New-Object -TypeName 'KeePassLib.Security.ProtectedString'($true, $title)))
            }

#TODO:
#            If ($UseReferences.IsPresent) {
#                [string]$username = "{REF:U@I:$($retSource.Uuid.ToHexString())}"
#                $dupEntry.Strings.Set('UserName', (New-Object -TypeName 'KeePassLib.Security.ProtectedString'($true, $username)))
#
#                [string]$password = "{REF:P@I:$($retSource.Uuid.ToHexString())}"
#                $dupEntry.Strings.Set('Password', (New-Object -TypeName 'KeePassLib.Security.ProtectedString'($true, $password)))
#            }

            If (-not $IncludeHistory.IsPresent) {
                $dupEntry.History.Clear()
            }

            $dupEntry.Touch($true, $false)
        }
        $dupGroup.Touch($true, $true)
        $KeePassDatabase.Save($null)
    }

    End {
    }
}
