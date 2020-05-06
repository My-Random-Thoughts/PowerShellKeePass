Function Test-KPIsValidEntry {
<#
    .SYNOPSIS
        Check to see if an impit object is a valid KeePass entry

    .DESCRIPTION
        Check to see if an impit object is a valid KeePass entry.  Returns the KeePass PwEntry object is valid

    .PARAMETER KeePassDatabase
        Specifies the KeePass database object to search

    .PARAMETER InputObject
        Specifies the object to check.

    .EXAMPLE
        Test-KPIsValidEntry -KeePassDatabase $KeePassDatabase -InputObject 'Sample Entry'

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
            'PwEntry' {
                Return $InputObject
            }

            'PwUuid' {
                [KeePassLib.PwEntry]$getUuid = ($KeePassDatabase.RootGroup.FindEntry($InputObject, $true))
                If (-not [string]::IsNullOrEmpty($getUuid)) {
                    Write-Verbose -Message 'Found valid entry using Uuid'
                    Write-Verbose "> $(($getUuid).Uuid.UuidBytes)"
                    Return ($getUuid -as [KeePassLib.PwEntry])
                }
                Else {
                    Throw 'Could not find a match for given uuid'
                }
            }

            'string' {
                [KeePassLib.PwEntry[]]$findItem = @(Find-KeePassEntry -KeePassDatabase $KeePassDatabase -SearchFor $InputObject -Field 'All' -AsObject)
                [KeePassLib.PwEntry[]]$getItem  =  (Get-KeePassEntry  -KeePassDatabase $KeePassDatabase -Path      $InputObject              -AsObject)

                If (-not [string]::IsNullOrEmpty($getItem)) {
                    Return $getItem
                }

                If ([string]::IsNullOrEmpty($findItem)) {
                    Throw 'Could not find exact match for given entry'
                }

                If ($findItem.Count -eq 1) {
                    Write-Verbose -Message "Found exact entry"
                    Return ($findItem[0] -as [KeePassLib.PwEntry])
                }
                Else {
                    ForEach ($item In $findItem) {
                        If ($item.Strings.ReadSafe('Title') -eq $InputObject) {
                            Write-Verbose -Message "Found valid entry"
                            Return ($item -as [KeePassLib.PwEntry])
                        }
                    }
                    Throw 'Could not find exact match for given entry'
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
