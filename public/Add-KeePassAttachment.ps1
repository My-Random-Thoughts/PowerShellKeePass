Function Add-KeePassAttachment {
<#
    .SYNOPSIS
        Add one or more attachments to a KeePass entry

    .DESCRIPTION
        Add one or more attachments to a KeePass entry

    .PARAMETER KeePassDatabase
        Specifies the KeePass database object to search

    .PARAMETER Uuid
        Specifies the Uuid of the entry to add to.  This can be either a PwUuid object or the hex representation of it

    .PARAMETER Path
        Specifies one or more attachment paths to add

    .PARAMETER OverwriteExisting
        Specifies an added attachment will overwrite any existing attachment with the same name

    .PARAMETER RenameDuplicates
        Specifies an added attachment will be renamed to avoid a duplication with any existing attachment with the same name

    .EXAMPLE
        Add-KeePassAttachment -KeePassDatabase $KeePassDatabase -Uuid '1234567890abcdef1234567890abcdef' -Path @('Attachment1.txt', 'Attachment2.txt') -OverwriteExisting

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
        [string[]]$Path,

        [Parameter(ParameterSetName = 'overwrite')]
        [switch]$OverwriteExisting,

        [Parameter(ParameterSetName = 'rename')]
        [switch]$RenameDuplicates
    )

    Begin {
        If ($KeePassDatabase.IsOpen -eq $false) {
            Throw 'The KeePass database specified is not open'
        }

        [KeePassLib.PwEntry]$currEntry = (Test-KPIsValidEntry -KeePassDatabase $KeePassDatabase -InputObject $Uuid)
        If (-not $currEntry) { Throw 'Invalid Uuid given' }
    }

    Process {
        ForEach ($item In $Path) {
            If (-not (Test-Path -Path $item)) {
                Write-Warning -Message "File not found: '$item', skipping"
                Continue
            }

            $fileName =    ([KeePassLib.Utility.UrlUtil]::GetFileName($item))
            $fileBase =    ([KeePassLib.Utility.UrlUtil]::StripExtension($fileName))
            $fileExt  = ".$([KeePassLib.Utility.UrlUtil]::GetExtension($fileName))"

            If ($currEntry.Binaries.Get($fileName)) {
                If ($RenameDuplicates.IsPresent) {
                    [int]$renameTry = 0
                    While ($true) {
                        [string]$newName = "$fileBase-$renameTry$fileExt"
                        If ($null -eq $currEntry.Binaries.Get($newName)) {
                            $fileName = $newName
                            Break
                        }
                        $renameTry++
                    }
                    Write-Warning -Message "Duplicate found, renamed new file to '$fileName'"
                }
                ElseIf (-not $OverwriteExisting.IsPresent) {
                    Write-Warning -Message "Attachment name '$fileName' already exists, skipping"
                    Continue
                }
            }

            Try {
                [byte[]]$fileBytes = [System.IO.File]::ReadAllBytes($item)
                If ($null -ne $fileBytes) {
                    $protectedBinary = (New-Object -TypeName 'KeePassLib.Security.ProtectedBinary'($false, $fileBytes))
                    $currEntry.Binaries.Set($fileName, $protectedBinary)
                }
            }
            Catch {
                Write-Error $_
            }
        }

        $currEntry.Touch($true)
        $KeePassDatabase.Save($null)
    }

    End {
    }
}
