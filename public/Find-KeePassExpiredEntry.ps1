Function Find-KeePassExpiredEntry {
<#
    .SYNOPSIS
        Find any expired or expiring KeePass entries

    .DESCRIPTION
        Find any expired or expiring KeePass entries

    .PARAMETER KeePassDatabase
        Specifies the KeePass database object to search

    .PARAMETER ShowExpired
        Specifies to search for expired entries

    .PARAMETER ShowExpiring
        Specifies to search for expiring entries

    .PARAMETER Days
        Specifies the number of days to check for expiring entries.  Valid range is between 1 and 60 days.  Use -1 to shown all future expiry dates

    .PARAMETER AsObject
        Specifies to return KeePass PwEntry objects instead of a PSCustomObject

    .EXAMPLE
        Find-KeePassExpiredEntry -KeePassDatabase $KeePassDatabase -ShowExpired

    .EXAMPLE
        Find-KeePassExpiredEntry -KeePassDatabase $KeePassDatabase -ShowExpiring

    .EXAMPLE
        Find-KeePassExpiredEntry -KeePassDatabase $KeePassDatabase -ShowExpiring

    .NOTES
        For additional information please see my GitHub wiki page

    .LINK
        https://github.com/My-Random-Thoughts/PowerShellKeePass
#>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [KeePassLib.PwDatabase]$KeePassDatabase,

        [Parameter(Mandatory = $true, ParameterSetName = 'expired')]
        [switch]$ShowExpired,

        [Parameter(Mandatory = $true, ParameterSetName = 'expiring')]
        [switch]$ShowExpiring,

        [Parameter(Mandatory = $true, ParameterSetName = 'expiring')]
        [ValidateScript({ $_ -ne 0 })]
        [ValidateRange(-1, 60)]
        [int]$Days,

        [switch]$AsObject
    )

    Begin {
        If ($KeePassDatabase.IsOpen -eq $false) {
            Throw 'The KeePass database specified is not open'
        }

        [KeePassLib.PwGroup]$searchResults = (New-Object -TypeName 'KeePassLib.PwGroup'($true, $true, [KeePass.Resources.KPRes]::Empty, [KeePassLib.PwIcon]::Expired))
        $searchResults.IsVirtual = $true

        [boolean]$dtFuture = $false
        If ($Days -eq -1) { $dtFuture = $true }

        $dtNow = (Get-Date)
        $dtLimit = $dtNow.AddDays([math]::Abs($Days))
    }

    Process {
        $KeePassDatabase.RootGroup.GetEntries($true) | ForEach-Object {
            [KeePassLib.PwEntry]$entry = $_

            If ($entry.Expires) {
                [int]$relNow = $entry.ExpiryTime.CompareTo($dtnow)
                If (
                    (($ShowExpired.IsPresent) -and ($relNow -le 0)) -or
                    (($dtFuture -eq $true) -and ($relNow -gt 0)) -or
                    (($entry.ExpiryTime -le $dtLimit) -and ($relNow -gt 0))) {

                    $searchResults.AddEntry($entry, $false, $false)
                }
            }
        }

        If ($searchResults.Entries.UCount -gt 0) {
            If ($AsObject.IsPresent) {
                Return ($searchResults.Entries)
            }
            Else {
                Return (ConvertFrom-KPObject -KeePassDatabase $KeePassDatabase -KeePassEntry ($searchResults.Entries) -WithCredential -ReplaceColumn 'Url>Expiry')
            }
        }

        Return $null
    }

    End {
    }
}
