Function Get-KeePassGroup {
<#
    .SYNOPSIS
        Retreive one or more KeePass groups

    .DESCRIPTION
        Retreive one or more KeePass groups using either a wildcard name or full path

    .PARAMETER KeePassDatabase
        Specifies the KeePass database object to search

    .PARAMETER Name
        Specifies the name of the groups to retreive

    .PARAMETER Path
        Specifies the path of the groups to retreive

    .PARAMETER Recursive
        Specifies to also retreive groups from sub-groups

    .PARAMETER AsObject
        Specifies to return KeePass PwGroup objects instead of a PSCustomObject

    .EXAMPLE
        Get-KeePassGroup -KeePassDatabase $KeePassDatabase -Name 'Home*'

    .EXAMPLE
        Get-KeePassGroup -KeePassDatabase $KeePassDatabase -Path '/General' -Recursive

    .NOTES
        For additional information please see my GitHub wiki page

    .LINK
        https://github.com/My-Random-Thoughts/PowerShellKeePass
#>

    [CmdletBinding(DefaultParameterSetName = '__Default')]
    Param (
        [Parameter(Mandatory = $true)]
        [KeePassLib.PwDatabase]$KeePassDatabase,

        [Parameter(ParameterSetName = 'Name')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Path')]
        [string]$Path,

        [Parameter(ParameterSetName = 'Path')]
        [switch]$Recursive,

        [switch]$AsObject
    )

    Begin {
        If ($KeePassDatabase.IsOpen -eq $false) {
            Throw 'The KeePass database specified is not open'
        }

        [KeePassLib.PwGroup[]]$groups = $KeePassDatabase.RootGroup
        If (($Path) -and (-not $Path.StartsWith($($KeePassDatabase.RootGroup.Name)))) {
            $Path = "$($KeePassDatabase.RootGroup.Name)/$($Path.Trim('/'))"
        }
    }

    Process {
        $KeePassDatabase.RootGroup.GetGroups($true) | ForEach-Object {

            [string]$itemName = ($_.Name)
            [string]$itemPath = ($_.GetFullPath('/', $true).ToLower())

            [boolean]$groupName = ( $itemName            -eq $Name.ToLower())    # Search just the name
            [boolean]$groupPath = ( $itemPath            -eq $Path.ToLower())    # Search just the path
            [boolean]$groupFull = ("$itemPath/$itemName" -eq $Path.ToLower())    # Search the full item path

            If (($Recursive.IsPresent) -and (-not $groupFull)) {
                [boolean]$groupPath = (($_.GetFullPath('/', $true).ToLower()).StartsWith($Path.ToLower()))
            }

            If (((-not $Name) -and (-not $Path)) -or ($groupName) -or ($groupPath) -or ($groupFull)) {
                If ($AsObject.IsPresent) {
                    Write-Output $_
                }
                Else {
                    Write-Output (ConvertFrom-KPObject -KeePassDatabase $KeePassDatabase -KeePassGroup $_)
                }
            }
        }
    }

    End {
    }
}
