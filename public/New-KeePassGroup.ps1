Function New-KeePassGroup {
<#
    .SYNOPSIS
        Create a new KeePass group

    .DESCRIPTION
        Create a new KeePass group.  Use Edit-KeePassGroup to specify more options

    .PARAMETER KeePassDatabase
        Specifies the KeePass database object to use

    .PARAMETER Name
        Specify the name of the group

    .PARAMETER ParentGroup
        Specify the parent group of the group, defaults to the root folder

    .PARAMETER Icon
        Specify the icon of the group, defaults to the parents icons

    .PARAMETER Notes
        Specify any notes for the group, defaults to blank

    .PARAMETER ExpiryDate
        Specify the expiry date of the group, defaults to never

    .PARAMETER PassThru
        Specify to return the object on the pipeline

    .EXAMPLE
        New-KeePassGroup -KeePassDatabase $KeePassDatabase -Name 'SuperSecretGroup' -ParentGroup '/Homebanking'

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
        [string]$Name,

        [object]$ParentGroup = $KeePassDatabase.RootGroup,

        [KeePassLib.PwIcon]$Icon,

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

        [KeePassLib.PwGroup]$KeePassGroup = (New-Object -TypeName 'KeePassLib.PwGroup')
        $retCheck = (Test-KPIsValidGroup -KeePassDatabase $KeePassDatabase -InputObject $ParentGroup)
        If ($null -ne $retCheck) { [KeePassLib.PwGroup]$newParentGroup = $retCheck }
    }

    Process {
        $KeePassGroup.Name = $Name
        $KeePassGroup.Uuid = [KeePassLib.PwUuid]::New($true)

        If ($null -ne $Icon)  { $KeePassGroup.IconId = $Icon }
        If ($null -ne $Notes) { $KeePassGroup.Notes  = $Notes }
        If ($ExpiryDate -gt ([datetime]::MinValue)) {
            $KeePassGroup.Expires = $true
            $KeePassGroup.ExpiryTime = $ExpiryDate
        }

        $newParentGroup.AddGroup($KeePassGroup, $true, $false)
        $newParentGroup.Touch($true, $true)
        $KeePassDatabase.Save($null)
        Write-Verbose -Message "Added new group: $Name"

        If ($PassThru.IsPresent) {
            Return $KeePassGroup    # Always return as a [KeePassLib.PwGroup] object
        }
    }

    End {
    }
}
