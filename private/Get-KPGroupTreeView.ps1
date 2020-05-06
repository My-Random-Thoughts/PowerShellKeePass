Function Get-KPGroupTreeView {
<#
    .SYNOPSIS
        Helps to draw a tree view of the currently database

    .DESCRIPTION
        Helps to draw a tree view of the currently database.  This will either output to the screen in colour, or output to a text file.

    .PARAMETER KeePassDatabase
        Specifies the KeePass database object to search

    .PARAMETER Group
        Specfies the current group to be shown

    .PARAMETER ShowEntries
        Specfies if entries are being shown

    .PARAMETER Entries
        Specfies the list of entries to show at this level

    .PARAMETER Level
        Specfies the current indent level

    .PARAMETER GroupsVisitedBeforeThisOne
        Specfies the ist of group already visited.  This helps prevent cyclic dependancies

    .PARAMETER LastGroupOfTheLevel
        Specfies if this is the last group of this level

    .PARAMETER LastGroupAtThisLevelFlag
        Specfies if this is the last group at this level

    .PARAMETER OutFile
        Specfies the file to output the results to

    .EXAMPLE
        Get-KPGroupTreeView -KeePassDatabase $KeePassDatabase -Group $KeePassDatabase.RootGroup -Level 0 -LastGroupOfTheLevel $false -GroupsVisitedBeforeThisOne = @{}

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
        [KeePassLib.PwGroup]$Group,

        [switch]$ShowEntries,

        [KeePassLib.PwEntry[]]$Entries,

        [Parameter(Mandatory = $true)]
        [int]$Level,

        [Parameter(Mandatory = $true)]
        [hashtable]$GroupsVisitedBeforeThisOne,

        [Parameter(Mandatory = $true)]
        [bool]$LastGroupOfTheLevel,

        [int[]]$LastGroupAtThisLevelFlag,

        [string]$OutFile
    )

    [string]$padding = ''
    [string[]]$char  = @('   ', "$([char]9474)  ", "$([char]9492)$([char]9472) ", "$([char]9500)$([char]9472) ")

    If ($LastGroupAtThisLevelFlag.Count -le $level) {
        $LastGroupAtThisLevelFlag = $LastGroupAtThisLevelFlag + 0
    }

    For ($i = 0; $i -lt ($level - 1); $i++) {
        If ($LastGroupAtThisLevelFlag[$i] -ne 0) {
            Write-Out -Message $($char[0]) -Colour Cyan -NoNewLine -OutFile $OutFile
            $padding += $($char[0])
        }
        Else {
            Write-Out -Message $($char[1]) -Colour Cyan -NoNewLine -OutFile $OutFile
            $padding += $($char[1])
        }
    }

    If ($level -ne 0) {
        If ($LastGroupAtThisLevelFlag[$level - 1] -eq 1) {
            Write-Out -Message $($char[2]) -Colour Cyan -NoNewLine -OutFile $OutFile
        }
        Else {
            Write-Out -Message $($char[3]) -Colour Cyan -NoNewLine -OutFile $OutFile
        }
    }

    [System.ConsoleColor]$drawColour = 'Yellow'
    [string]$recycleBin = ''
    If (($KeePassDatabase.RecycleBinEnabled -eq $true) -and ($Group.Uuid -eq $KeePassDatabase.RecycleBinUuid)) {
        $drawColour = 'Magenta'
        $recycleBin = '[R] '
    }
    Write-Out -Message "$recycleBin$($Group.Name)" -Colour $drawColour -OutFile $OutFile

    [int]$cnt = 0
    If ($ShowEntries.IsPresent) {
        ForEach ($item In $Entries) {
            $cnt++
            $sybl  = $($char[3])
            $extra = $($char[$(-not $LastGroupAtThisLevelFlag[$level - 1])])
            If ((($Level -eq 0) -or ($Group.Groups.UCount -eq 0)) -and ($Entries.Count -eq $cnt)) { $sybl = $($char[2]) }

            Write-Out -Message $padding$extra$sybl -Colour Cyan -NoNewLine -OutFile $OutFile
            Write-Out -Message "E: $($item.Strings.ReadSafe('Title'))" -Colour Green -OutFile $OutFile
        }
    }

    $groupsVisitedBeforeThisOne.Add($group.Uuid, $null)
    $groupMemberShipCount = $group.Groups.UCount

    If ($groupMemberShipCount -gt 0) {
        $maxSubGroupLevel = 0
        $count = 0

        ForEach($subGroup In $group.Groups) {
            $count++
            $lastGroupOfTheLevel = $false

            If ($count -eq $groupMemberShipCount) {
                $lastGroupOfTheLevel = $true
                $LastGroupAtThisLevelFlag[$level] = 1
            }

            # Prevent cyclic dependancies
            If (-not $groupsVisitedBeforeThisOne.Contains($subGroup.Uuid)) {
                If ($ShowEntries.IsPresent) {
                    $subEntries = $subGroup.Entries
                }

                $subGroupLevel = Get-KPGroupTreeView `
                    -KeePassDatabase $KeePassDatabase `
                    -Group $subGroup `
                    -Level $($Level + 1) `
                    -GroupsVisitedBeforeThisOne $GroupsVisitedBeforeThisOne `
                    -LastGroupOfTheLevel $LastGroupOfTheLevel `
                    -LastGroupAtThisLevelFlag $LastGroupAtThisLevelFlag `
                    -ShowEntries:$ShowEntries.IsPresent `
                    -Entries $subEntries `
                    -OutFile $OutFile

                If ($subGroupLevel -gt $maxSubGroupLevel) {
                    $maxSubGroupLevel = $subGroupLevel
                }
            }
        }
        $level = $maxSubGroupLevel
    }
    Else {
        Return $level    # We've reached the top level group, return it's height
    }
    Return $level
}

Function Write-Out {
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Scope = 'Function')]
    Param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [System.ConsoleColor]$Colour = 'White',

        [switch]$NoNewLine,

        [string]$OutFile
    )

    If ($OutFile) {
        Out-File -FilePath $OutFile -Encoding utf8 -NoNewline:$NoNewLine.IsPresent -Append -Force -InputObject $Message
    }
    Else {
        Write-Host -Object $Message -ForegroundColor $Colour -NoNewline:$NoNewLine.IsPresent
    }
}
