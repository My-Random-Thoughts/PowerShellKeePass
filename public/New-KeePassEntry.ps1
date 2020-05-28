Function New-KeePassEntry {
<#
    .SYNOPSIS
        Create a new KeePass entry

    .DESCRIPTION
        Create a new KeePass entry.  Use Edit-KeePassEntry to specify more options

    .PARAMETER KeePassDatabase
        Specifies the KeePass database object to use

    .PARAMETER Title
        Specify the title of the entry

    .PARAMETER ParentGroup
        Specify the parent group of the entry, defaults to the root folder

    .PARAMETER Icon
        Specify the icon of the entry, defaults to the parents icons

    .PARAMETER UserName
        Specify the username of the entry, defaults to the database default

    .PARAMETER Password
        Specify the password of the entry, defaults to blank

    .PARAMETER Url
        Specify the Url of the entry, defaults to blank

    .PARAMETER Notes
        Specify any notes for the entry, defaults to blank

    .PARAMETER ExpiryDate
        Specify the expiry date of the entry, defaults to never

    .PARAMETER PassThru
        Specify to return the object on the pipeline

    .EXAMPLE
        New-KeePassEntry -KeePassDatabase $KeePassDatabase -Title 'SuperSecretLogin' -Url 'http://www.example.com'

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
        [string]$Title,

        [object]$ParentGroup = $KeePassDatabase.RootGroup,

        [KeePassLib.PwIcon]$Icon,

        [string]$UserName,

        [securestring]$Password,

        [string]$Url,

        [string]$Notes,

        [datetime]$ExpiryDate,

        [switch]$PassThru
    )

    Begin {
        If ($KeePassDatabase.IsOpen -eq $false) {
            Throw 'The KeePass database specified is not open'
        }

        If ([string]::IsNullOrEmpty($ParentGroup)) {
            $ParentGroup = $KeePassDatabase.RootGroup
        }

        [KeePassLib.PwGroup]$newParentGroup = (Test-KPIsValidGroup -KeePassDatabase $KeePassDatabase -InputObject $ParentGroup)
        [KeePassLib.PwEntry]$KeePassEntry = (New-Object -TypeName 'KeePassLib.PwEntry'($true, $true))

        If ($Password) {
            $PlainPwd = ConvertTo-KPPlainText -InputString $Password
        }

        If (-not $UserName) { $UserName = ($KeePassDatabase.DefaultUserName) }
    }

    Process {
        If ($PSCmdlet.ShouldProcess($Title, 'Creating new entry')) {
            $KeePassEntry.Strings.Set('Title',    (New-Object -TypeName 'KeePassLib.Security.ProtectedString'($true, $Title   )))
            $KeePassEntry.Strings.Set('UserName', (New-Object -TypeName 'KeePassLib.Security.ProtectedString'($true, $UserName)))
            $KeePassEntry.Uuid = [KeePassLib.PwUuid]::New($true)

            If ($Icon)     { $KeePassEntry.IconId = $Icon  }
            If ($Notes)    { $KeePassEntry.Strings.Set('Notes',    (New-Object -TypeName 'KeePassLib.Security.ProtectedString'($true, $Notes   ))) }
            If ($PlainPwd) { $KeePassEntry.Strings.Set('Password', (New-Object -TypeName 'KeePassLib.Security.ProtectedString'($true, $PlainPwd))) }
            If ($Url)      { $KeePassEntry.Strings.Set('Url',      (New-Object -TypeName 'KeePassLib.Security.ProtectedString'($true, $Url     ))) }

            If ($ExpiryDate -gt ([datetime]::MinValue)) {
                $KeePassEntry.Expires = $true
                $KeePassEntry.ExpiryTime = $ExpiryDate
            }

            $newParentGroup.AddEntry($KeePassEntry, $true, $false)
            $newParentGroup.Touch($true, $true)
            $KeePassDatabase.Save($null)
            Write-Verbose -Message "Added new entry: $Title"

            If ($PassThru.IsPresent) {
                Return $KeePassEntry    # Always return as a [KeePassLib.PwEntry] object
            }
        }
    }

    End {
    }
}
