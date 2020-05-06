Function Remove-KeePassAttachment {
<#
    .SYNOPSIS
        Remove one or more attachments from a KeePass entry

    .DESCRIPTION
        Remove one or more attachments from a KeePass entry

    .PARAMETER KeePassDatabase
        Specifies the KeePass database object to search

    .PARAMETER Uuid
        Specifies the Uuid of the entry to remove from.  This can be either a PwUuid object or the hex representation of it

    .PARAMETER Name
        Specifies one or more attachment names to remove

    .EXAMPLE
        Remove-KeePassAttachment -KeePassDatabase $KeePassDatabase -Uuid '1234567890abcdef1234567890abcdef' -Name @('Attachment1.txt', 'Attachment2.txt')

    .NOTES
        For additional information please see my GitHub wiki page

    .LINK
        https://github.com/My-Random-Thoughts/PowerShellKeePass
#>

    [CmdletBinding(DefaultParameterSetName = '__default')]
    Param (
        [Parameter(Mandatory = $true)]
        [KeePassLib.PwDatabase]$KeePassDatabase,

        [Parameter(Mandatory = $true)]
        [object]$Uuid,

        [Parameter(Mandatory = $true)]
        [string[]]$Name
    )

    Begin {
        If ($KeePassDatabase.IsOpen -eq $false) {
            Throw 'The KeePass database specified is not open'
        }

        [KeePassLib.PwEntry]$currEntry = (Test-KPIsValidEntry -KeePassDatabase $KeePassDatabase -InputObject $Uuid)
        If (-not $currEntry) { Throw 'Invalid Uuid given' }
    }

    Process {
        ForEach ($item In $Name) {
            If (-not $currEntry.Binaries.Get($item)) {
                Write-Warning -Message "Attachment '$item' does not exist, skipping"
                Continue
            }

            [void]$currEntry.Binaries.Remove($item)
        }

        $currEntry.Touch($true)
        $KeePassDatabase.Save($null)
    }

    End {
    }


}
