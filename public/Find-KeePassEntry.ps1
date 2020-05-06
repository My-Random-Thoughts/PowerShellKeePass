Function Find-KeePassEntry {
<#
    .SYNOPSIS
        Searches for one or more KeePass entries

    .DESCRIPTION
        Searches for one or more KeePass entries

    .PARAMETER KeePassDatabase
        Specifies the KeePass database object to search

    .PARAMETER SearchFor
        Specifies the string to search for

    .PARAMETER Field
        Specifies the field to search in.  Valid options are 'All', 'Notes', 'Other', 'Password', 'StringName', 'Tag', 'Title', 'Url', 'UserName', 'Uuid'

    .PARAMETER ExcludeExpired
        Specifies to exclude any expired entries in the search results

    .PARAMETER SearchInGroupNames
        Specifies to search in group names

    .PARAMETER SearchInGroupPaths
        Specifies to search in group paths.  If this is enabled, SearchInGroupNames is automatically enabled

    .PARAMETER SearchRoot
        Specifies a root group to search from

    .PARAMETER AsObject
        Specifies to return KeePass PwEntry objects instead of a PSCustomObject

    .EXAMPLE
        Find-KeePassEntry -KeePassDatabase $KeePassDatabase -SearchFor 'Sample Entry' -Field 'Title'

    .EXAMPLE
        Find-KeePassEntry -KeePassDatabase $KeePassDatabase -SearchFor 'Sample Entry' -ExcludeExpired -AsObject

    .NOTES
        For additional information please see my GitHub wiki page

    .LINK
        https://github.com/My-Random-Thoughts/PowerShellKeePass
#>

    [CmdletBinding(DefaultParameterSetName = '__default')]
    Param (
        [Parameter(Mandatory = $true)]
        [KeePassLib.PwDatabase]$KeePassDatabase,

        [string]$SearchFor,

        [ValidateSet('All', 'Notes', 'Other', 'Password', 'StringName', 'Tag', 'Title', 'Url', 'UserName', 'Uuid')]
        [string[]]$Field = 'All',

        [switch]$ExcludeExpired,

        [Parameter(ParameterSetName = 'Name')]
        [switch]$SearchInGroupNames,

        [Parameter(ParameterSetName = 'Path')]
        [switch]$SearchInGroupPaths,

        [object]$SearchRoot = ($KeePassDatabase.RootGroup),

        [switch]$AsObject
    )

    Begin {
        If ($KeePassDatabase.IsOpen -eq $false) {
            Throw 'The KeePass database specified is not open'
        }

        [KeePassLib.PwGroup]$SearchRoot    = (Test-KPIsValidGroup -KeePassDatabase $KeePassDatabase -InputObject $SearchRoot)
        [KeePassLib.PwGroup]$searchResults = (New-Object -TypeName 'KeePassLib.PwGroup'($true, $true, [KeePass.Resources.KPRes]::SearchGroupName, [KeePassLib.PwIcon]::EMailSearch))
        $searchParameters = (New-Object -TypeName 'KeePassLib.SearchParameters')
        $searchResults.IsVirtual = $true
    }

    Process {
        $searchParameters.SearchInNotes       = (($Field -eq 'All') -or ($Field -contains 'Notes'     ))
        $searchParameters.SearchInOther       = (($Field -eq 'All') -or ($Field -contains 'Other'     ))
        $searchParameters.SearchInPasswords   = (($Field -eq 'All') -or ($Field -contains 'Password'  ))
        $searchParameters.SearchInStringNames = (($Field -eq 'All') -or ($Field -contains 'StringName'))
        $searchParameters.SearchInTags        = (($Field -eq 'All') -or ($Field -contains 'Tag'       ))
        $searchParameters.SearchInTitles      = (($Field -eq 'All') -or ($Field -contains 'Title'     ))
        $searchParameters.SearchInUrls        = (($Field -eq 'All') -or ($Field -contains 'Url'       ))
        $searchParameters.SearchInUserNames   = (($Field -eq 'All') -or ($Field -contains 'UserName'  ))
        $searchParameters.SearchInUuids       = (($Field -eq 'All') -or ($Field -contains 'Uuid'      ))

        $searchParameters.SearchString        = $SearchFor
        $searchParameters.ExcludeExpired      = $ExcludeExpired.IsPresent
        $searchParameters.SearchInGroupNames  = ($SearchInGroupNames.IsPresent -or $SearchInGroupPaths.IsPresent)
        $searchParameters.SearchInGroupPaths  = $SearchInGroupPaths.IsPresent

        [void]$SearchRoot.SearchEntries($searchParameters, $searchResults.Entries)

        If ($searchResults.Entries.UCount -gt 0) {
            If ($AsObject.IsPresent) {
                Return ($searchResults.Entries)
            }
            Else {
                Return (ConvertFrom-KPObject -KeePassDatabase $KeePassDatabase -KeePassEntry ($searchResults.Entries) -WithCredential)
            }
        }

        Return $null
    }

    End {
    }
}
