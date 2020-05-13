Function Remove-KeePassGroup {
<#
    .SYNOPSIS
        Delete a KeePass group and all entries and sub-groups

    .DESCRIPTION
        Delete a KeePass group and all entries and sub-groups

    .PARAMETER KeePassDatabase
        Specifies the KeePass database object to use

    .PARAMETER Group
        Specifies the entry to remove

    .PARAMETER Force
        Bypass the recycle bin and permanently delete the group.  This option is automatically set if the recycle bin is not enabled or the object is already in the recycle bin.

    .EXAMPLE
        Remove-KeePassGroup -KeePassDatabase $KeePassDatabase -group 'Homebanking'

    .EXAMPLE
        Remove-KeePassGroup -KeePassDatabase $KeePassDatabase -group 'Homebanking' -Force

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
        [object]$Group,

        [switch]$Force
    )

    Begin {
        If ($KeePassDatabase.IsOpen -eq $false) {
            Throw 'The KeePass database specified is not open'
        }

        [KeePassLib.PwGroup]$kpRecycleBin = ($KeePassDatabase.RootGroup.FindGroup($KeePassDatabase.RecycleBinUuid, $true))
        [KeePassLib.PwGroup]$retSource    = (Test-KPIsValidGroup -KeePassDatabase $KeePassDatabase -InputObject $Group)

        If ($null -eq $retSource.ParentGroup) { Throw 'Can not remove root or virtual groups' }

        If     (-not $KeePassDatabase.RecycleBinEnabled) { $Force = $true }    # Is the recycle bin enabled
        ElseIf ($retSource.Uuid -eq $kpRecycleBin.Uuid)  { $Force = $true }    # Is selected group the recycle bin
        ElseIf ($retSource.IsContainedIn($kpRecycleBin)) { $Force = $true }    # Are we deleting within the recycle bin
        ElseIf ($kpRecycleBin.IsContainedIn($retSource)) { $Force = $true }    # Is the recycle bin within the group we are deleting
    }

    Process {
        [void]$retSource.ParentGroup.Groups.Remove($retSource)
        [string]$groupPath = "/$($retSource.GetFullPath('/', $false))"

        If ($Force -eq $true) {
            If ($PSCmdlet.ShouldProcess($groupPath, 'Permanently deleting')) {
                $retSource.DeleteAllObjects($KeePassDatabase)
                $deletedObject = (New-Object -TypeName 'KeePassLib.PwDeletedObject'($retSource.Uuid, $(Get-Date)))
                $KeePassDatabase.DeletedObjects.Add($deletedObject)
            }
        }
        Else {
            If ($PSCmdlet.ShouldProcess($groupPath, 'Moving to recycle bin')) {
                $kpRecycleBin = (Confirm-KPRecycleBin -KeePassDatabase $KeePassDatabase)
                Try {
                    $kpRecycleBin.AddGroup($retSource, $true, $true)
                }
                Catch {
                    $retSource.ParentGroup.AddGroup($retSource)
                    Write-Warning -Message $($_.Exception.Message)
                }

                $retSource.Touch($false)
            }
        }

        $KeePassDatabase.Save($null)
    }

    End {
    }
}
