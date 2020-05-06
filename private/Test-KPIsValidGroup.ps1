Function Test-KPIsValidGroup {
<#
    .SYNOPSIS
        Check to see if an impit object is a valid KeePass group

    .DESCRIPTION
        Check to see if an impit object is a valid KeePass group.  Returns the KeePass PwGroup object is valid

    .PARAMETER KeePassDatabase
        Specifies the KeePass database object to search

    .PARAMETER InputObject
        Specifies the object to check.

    .EXAMPLE
        Test-KPIsValidGroup -KeePassDatabase $KeePassDatabase -InputObject 'New Group 2'

    .EXAMPLE
        Test-KPIsValidGroup -KeePassDatabase $KeePassDatabase -InputObject '/Homebanking/New Group'

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
        [object]$InputObject
    )

    Begin {
        If ($KeePassDatabase.IsOpen -eq $false) {
            Throw 'The KeePass database specified is not open'
        }
    }

    Process {
        Switch ($InputObject.GetType().Name) {
            'PwGroup' {
                Return $InputObject
            }

            'PwUuid' {
                [KeePassLib.PwGroup]$getUuid = ($KeePassDatabase.RootGroup.FindGroup($InputObject, $true))
                If (-not [string]::IsNullOrEmpty($getUuid)) {
                    Write-Verbose -Message 'Found valid entry using Uuid'
                    Write-Verbose "> $(($getUuid).Uuid.UuidBytes)"
                    Return ($getUuid -as [KeePassLib.PwGroup])
                }
                Else {
                    Throw 'Could not find a match for given uuid'
                }
            }

            'string' {
                $getName = @(Get-KeePassGroup -KeePassDatabase $KeePassDatabase -Name $InputObject -AsObject)
                $getPath = @(Get-KeePassGroup -KeePassDatabase $KeePassDatabase -Path $InputObject -AsObject)

                If ($getName.Count -eq 1) {
                    Write-Verbose -Message 'Found valid group using name'
                    Return ($getName[0] -as [KeePassLib.PwGroup])
                }
                ElseIf ($getPath.Count -eq 1) {
                    Write-Verbose -Message 'Found valid group using path'
                    Return ($getPath[0] -as [KeePassLib.PwGroup])
                }
                Else {
                    Throw 'Could not find exact match for given group name or path'
                }
            }

            Default {
                Throw "Unknown Type: $($InputObject.GetType().Name)"
            }
        }
    }

    End {
    }
}
