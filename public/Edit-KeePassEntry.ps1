Function Edit-KeePassEntry {
<#
    .SYNOPSIS
        Edit an existing KeePass entry

    .DESCRIPTION
        Edit an existing KeePass entry

    .PARAMETER KeePassDatabase
        Specifies the KeePass database object to use

    .PARAMETER Uuid
        Specifies the Uuid of the entry to edit

    .PARAMETER Title
        Specifies a new title for the entry

    .PARAMETER Icon
        Specifies a new icon

    .PARAMETER CustomIcon
        Specifies a new custom icon

    .PARAMETER UserName
        Specifies a new username.  If no username is given, the database default is used

    .PARAMETER Password
        Specifies a new password.  New-KeePassPassword can be used to generate these

    .PARAMETER Url
        Specifies a new Url

    .PARAMETER Notes
        Specifies the notes

    .PARAMETER ExpiryDate
        Specifies a new expiry date for the entry.  Set as ([datetime]::MinValue) to remove an existing expiry date

    .PARAMETER Field
        Specifies one or more additional fields

    .PARAMETER Attachment
        Specifies one or more additional attachments

    .PARAMETER ForgroundColour
        Specifies the foreground colour.  This is only visible within a supported GUI application

    .PARAMETER BackgroundColour
        Specifies the background colour.  This is only visible within a supported GUI application

    .PARAMETER Tag
        Specifies one or more additional tags

    .PARAMETER ClearExistingTags
        Specifies to remove any existing tags

    .PARAMETER OverrideUrl
        Specifies a new override Url

    .EXAMPLE
        Edit-KeePassEntry -KeePassDatabase $KeePassDatabase -Uuid '1234567890abcdef1234567890abcdef' -UserName 'Joe90'

    .EXAMPLE
        Edit-KeePassEntry -KeePassDatabase $KeePassDatabase -Uuid '1234567890abcdef1234567890abcdef' -CustomIcon 1 -ExpiryDate (Get-Date).AddDays(30)

    .EXAMPLE
        Edit-KeePassEntry -KeePassDatabase $KeePassDatabase -Uuid '1234567890abcdef1234567890abcdef' -Tags @('Blue', 'Secure') -ClearExistingTags

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
        [object]$Uuid,

        [string]$Title,

        [Parameter(ParameterSetName = 'icon')]
        [KeePassLib.PwIcon]$Icon,

        [Parameter(ParameterSetName = 'custom')]
        [ValidateScript({ ($_ -is [KeePassLib.PwCustomIcon]) -or ($_ -is [int]) })]
        [object]$CustomIcon,

        [string]$UserName,

        [securestring]$Password,

        [string]$Url,

        [string]$Notes,

        [datetime]$ExpiryDate,

        [System.Collections.DictionaryEntry[]]$Field,

        [string[]]$Attachment,

        [System.Drawing.Color]$ForgroundColour,

        [System.Drawing.Color]$BackgroundColour,

        [string[]]$Tag,

        [switch]$ClearExistingTags,

        [string]$OverrideUrl
    )

    Begin {
        If ($KeePassDatabase.IsOpen -eq $false) {
            Throw 'The KeePass database specified is not open'
        }

        [KeePassLib.PwEntry]$currEntry = (Test-KPIsValidEntry -KeePassDatabase $KeePassDatabase -InputObject $Uuid)
        If (-not $currEntry) { Throw 'Invalid Uuid given' }

        If ($CustomIcon -is [int]) {
            [KeePassLib.PwCustomIcon]$CustomIcon = (Get-KPCustomIcon -KeePassDatabase $KeePassDatabase -Index $CustomIcon)
        }

        If ($Password) {
            $PlainPwd = ConvertTo-KPPlainText -InputString $Password
        }
    }

    Process {
        If ($ClearExistingTags.IsPresent) { $currEntry.Tags.Clear() }

        If ($Notes)            { $currEntry.Notes           = $Notes            }
        If ($Icon)             { $currEntry.IconId          = $Icon             }
        If ($CustomIcon)       { $currEntry.CustomIconUuid  = $CustomIcon.Uuid  }
        If ($ForegroundColour) { $currEntry.ForegroundColor = $ForegroundColour }
        If ($BackgroundColour) { $currEntry.BackgroundColor = $BackgroundColour }
        If ($OverrideUrl)      { $currEntry.OverrideUrl     = $OverrideUrl      }
        If ($Title)            { $currEntry.Strings.Set('Title',    (New-Object -TypeName 'KeePassLib.Security.ProtectedString'($true, $Title   ))) }
        If ($UserName)         { $currEntry.Strings.Set('UserName', (New-Object -TypeName 'KeePassLib.Security.ProtectedString'($true, $UserName))) }
        If ($PlainPwd)         { $currEntry.Strings.Set('Password', (New-Object -TypeName 'KeePassLib.Security.ProtectedString'($true, $PlainPwd))) }
        If ($Url)              { $currEntry.Strings.Set('Url',      (New-Object -TypeName 'KeePassLib.Security.ProtectedString'($true, $Url     ))) }
        If ($Tag.Count -gt 0)  { $currEntry.Tags.AddRange($Tag) }

        If ($ExpiryDate -eq ([datetime]::MinValue)) {
            $currEntry.Expires = $false
        }
        ElseIf ($ExpiryDate -gt ([datetime]::MinValue)) {
            $currEntry.Expires = $true
            $currEntry.ExpiryTime = $ExpiryDate
        }

        If ($Field) {
            ForEach ($item In $Field) {
                $currEntry.Strings.Set($($item.Name), (New-Object -TypeName 'KeePassLib.Security.ProtectedString'($true, $($item.Value))))
            }
        }

        If ($Attachment) {
            Add-KeePassAttachment -KeePassDatabase $KeePassDatabase -Uuid $Uuid -Path $Attachment
        }

        $currEntry.Touch($true)
        $KeePassDatabase.Save($null)
    }

    End {
    }
}
