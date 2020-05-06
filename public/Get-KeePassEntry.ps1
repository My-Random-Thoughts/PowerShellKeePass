Function Get-KeePassEntry {
<#
    .SYNOPSIS
        Retreive one or more KeePass entries

    .DESCRIPTION
        Retreive one or more KeePass entries using either a wildcard name or full path

    .PARAMETER KeePassDatabase
        Specifies the KeePass database object to search

    .PARAMETER Title
        Specifies the title of the entries to retreive

    .PARAMETER Path
        Specifies the path of the entries to retreive

    .PARAMETER Recursive
        Specifies to also retreive entries from sub groups

    .PARAMETER AsObject
        Specifies to return KeePass PwEntry objects instead of a PSCustomObject

    .PARAMETER ShowPassword
        Specifies to show the password as plain text.  A credential object will always be created

    .EXAMPLE
        Get-KeePassEntry -KeePassDatabase $KeePassDatabase -Title 'Sample*'

    .EXAMPLE
        Get-KeePassEntry -KeePassDatabase $KeePassDatabase -Path '/General' -Recursive -ShowPassword

    .NOTES
        For additional information please see my GitHub wiki page

    .LINK
        https://github.com/My-Random-Thoughts/PowerShellKeePass
#>

    [CmdletBinding(DefaultParameterSetName = '__Default')]
    Param (
        [Parameter(Mandatory = $true)]
        [KeePassLib.PwDatabase]$KeePassDatabase,

        [Parameter(ParameterSetName = 'Title')]
        [string]$Title,

        [Parameter(ParameterSetName = 'Path')]
        [string]$Path,

        [Parameter(ParameterSetName = 'Path')]
        [switch]$Recursive,

        [switch]$AsObject,

        [switch]$ShowPassword
    )

    Begin {
        If ($KeePassDatabase.IsOpen -eq $false) {
            Throw 'The KeePass database specified is not open'
        }

        If (($Path) -and (-not $Path.StartsWith($($KeePassDatabase.RootGroup.Name)))) {
            $Path = "$($KeePassDatabase.RootGroup.Name)/$($Path.Trim('/'))"
        }
    }

    Process {
        $KeePassDatabase.RootGroup.GetEntries($true) | ForEach-Object {

            [string]$itemTitle = ($_.Strings.ReadSafe('Title').ToLower())
            [string]$itemPath  = ($_.ParentGroup.GetFullPath('/', $true).ToLower())

            [boolean]$entryName = ( $itemTitle            -like $Title.ToLower())    # Search just the name
            [boolean]$entryPath = ( $itemPath             -eq   $Path.ToLower())     # Search just the path
            [boolean]$entryFull = ("$itemPath/$itemTitle" -eq   $Path.ToLower())     # Search the full item path

            If (($Recursive.IsPresent) -and (-not $entryFull)) {
                [boolean]$entryPath = (($_.ParentGroup.GetFullPath('/', $true).ToLower()).StartsWith($Path.ToLower()))
            }

            If (((-not $Title) -and (-not $Path)) -or ($entryName) -or ($entryPath) -or ($entryFull)) {
                If ($AsObject.IsPresent) {
                    Write-Output $_
                }
                Else {
                    Write-Output (ConvertFrom-KPObject -KeePassDatabase $KeePassDatabase -KeePassEntry $_ -WithCredential -AsPlainText:$($ShowPassword.IsPresent))
                }
            }
        }
    }
}
