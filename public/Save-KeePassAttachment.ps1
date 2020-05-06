Function Save-KeePassAttachment {
<#
    .SYNOPSIS
        Save one or more attachments from a KeePass entry

    .DESCRIPTION
        Save one or more attachments from a KeePass entry

    .PARAMETER KeePassDatabase
        Specifies the KeePass database object to search

    .PARAMETER Uuid
        Specifies the Uuid of the entry to save from.  This can be either a PwUuid object or the hex representation of it

    .PARAMETER Name
        Specifies one or more attachment names to save

    .PARAMETER Path
        Specifies the path to save the requested attachments

    .PARAMETER OverwriteExisting
        Specifies to overwrite an existing file if one already exists

    .PARAMETER RenameDuplicates
        Specifies to rename the attachment name if one already exists

    .EXAMPLE
        Save-KeePassAttachment -KeePassDatabase $KeePassDatabase -Uuid '1234567890abcdef1234567890abcdef' -Name @('Attachment1.txt', 'Attachment2.txt')

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
        [string[]]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path -Path $_ })]
        [string]$Path,

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
        ForEach ($item In $Name) {
            If (-not $currEntry.Binaries.Get($item)) {
                Write-Warning -Message "Attachment '$item' does not exist, skipping"
                Continue
            }

            $fileName =    ([KeePassLib.Utility.UrlUtil]::GetFileName($item))
            $fileBase =    ([KeePassLib.Utility.UrlUtil]::StripExtension($fileName))
            $fileExt  = ".$([KeePassLib.Utility.UrlUtil]::GetExtension($fileName))"

            If (Test-Path -Path "$path\$fileName") {
                If ($RenameDuplicates.IsPresent) {
                    [int]$renameTry = 0
                    While ($true) {
                        [string]$newName = "$fileBase-$renameTry$fileExt"
                        If (-not (Test-Path -Path "$path\$newName")) {
                            $fileName = $newName
                            Break
                        }
                        $renameTry++
                    }
                    Write-Warning -Message "Duplicate found, renamed new file to '$fileName'"
                }
                ElseIf (-not $OverwriteExisting.IsPresent) {
                    Write-Warning -Message "File name '$fileName' already exists, skipping"
                    Continue
                }
            }

            Try {
                [System.IO.File]::WriteAllBytes("$Path\$fileName", $($currEntry.Binaries.Get($item).ReadData()))
                Get-ChildItem -Path "$Path\$fileName"
            }
            Catch {
                Write-Error $_
            }
        }
    }

    End {
    }
}
