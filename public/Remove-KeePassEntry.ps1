Function Remove-KeePassEntry {
<#
    .SYNOPSIS
        Delete a KeePass entry

    .DESCRIPTION
        Delete a KeePass entry

    .PARAMETER KeePassDatabase
        Specifies the KeePass database object to use

    .PARAMETER Entry
        Specifies the entry to remove

    .PARAMETER Force
        Bypass the recycle bin and permanently delete the entry.  This option is automatically set if the recycle bin is not enabled or the object is already in the recycle bin.

    .EXAMPLE
        Remove-KeePassEntry -KeePassDatabase $KeePassDatabase -Entry 'Sample Entry'

    .EXAMPLE
        Remove-KeePassEntry -KeePassDatabase $KeePassDatabase -Entry 'Sample Entry' -Force

    .NOTES
        For additional information please see my GitHub wiki page

    .LINK
        https://github.com/My-Random-Thoughts/PowerShellKeePass
#>

    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [Parameter(Mandatory = $true)]
        [KeePassLib.PwDatabase]$KeePassDatabase,

        [Parameter(Mandatory = $true)]
        [object]$Entry,

        [switch]$Force
    )

    Begin {
        If ($KeePassDatabase.IsOpen -eq $false) {
            Throw 'The KeePass database specified is not open'
        }

        [KeePassLib.PwGroup]$kpRecycleBin = ($KeePassDatabase.RootGroup.FindGroup($KeePassDatabase.RecycleBinUuid, $true))
        [KeePassLib.PwEntry]$retSource    = (Test-KPIsValidEntry -KeePassDatabase $KeePassDatabase -InputObject $Entry)

        If     (-not $KeePassDatabase.RecycleBinEnabled)             { $Force = $true }    # Is the recycle bin enabled
        ElseIf ($retSource.ParentGroup.Uuid -eq $kpRecycleBin.Uuid)  { $Force = $true }    # Is parent group the recycle bin
        ElseIf ($retSource.ParentGroup.IsContainedIn($kpRecycleBin)) { $Force = $true }    # Are we deleting within the recycle bin
    }

    Process {
        [void]$retSource.ParentGroup.Entries.Remove($retSource)
        [string]$entryPath = "/$($retSource.ParentGroup.GetFullPath('/', $false))/$($retSource.Strings.ReadSafe('Title'))"

        If ($Force -eq $true) {
            If ($PSCmdlet.ShouldProcess($entryPath, 'Permanently deleting')) {
                $deletedObject = (New-Object -TypeName 'KeePassLib.PwDeletedObject'($retSource.Uuid, $(Get-Date)))
                $KeePassDatabase.DeletedObjects.Add($deletedObject)
            }
        }
        Else {
            If ($PSCmdlet.ShouldProcess($entryPath, 'Moving to recycle bin')) {
                $kpRecycleBin = (Confirm-KPRecycleBin -KeePassDatabase $KeePassDatabase)
                $kpRecycleBin.AddEntry($retSource, $true, $true)
                $retSource.Touch($false)
            }
        }

        $KeePassDatabase.Save($null)
    }

    End {
    }
}
