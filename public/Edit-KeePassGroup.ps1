Function Edit-KeePassGroup {
<#
    .SYNOPSIS
        Edit an existing KeePass group

    .DESCRIPTION
        Edit an existing KeePass group

    .PARAMETER KeePassDatabase
        Specifies the KeePass database object to use

    .PARAMETER Uuid
        Specifies the Uuid of the group to edit

    .PARAMETER Name
        Specifies a new name for the group

    .PARAMETER Icon
        Specifies a new icon

    .PARAMETER CustomIcon
        Specifies a new custom icon

    .PARAMETER Notes
        Specifies the notes

    .PARAMETER ExpiryDate
        Specifies a new expiry date for the group.  Set as ([datetime]::MinValue) to remove an existing expiry date

    .PARAMETER AutoTypeBehavior
        Specifies the Auto-Type behavior.  Valid valies are: 'Inherit', 'Enabled', 'Disabled'

    .PARAMETER SearchingBehavior
        Specifies the searching behavior.  Valid valies are: 'Inherit', 'Enabled', 'Disabled'

    .PARAMETER AutoTypeSequence
        Specifies the Auto-Type sequence from the parent group.  'Inherit', 'Override'

    .PARAMETER AutoTypeOverride
        Specifies the Auto-Type overrise sequence

    .EXAMPLE
        Edit-KeePassGroup -KeePassDatabase $KeePassDatabase -Uuid '1234567890abcdef1234567890abcdef' -Name 'Linux'

    .EXAMPLE
        Edit-KeePassGroup -KeePassDatabase $KeePassDatabase -Uuid '1234567890abcdef1234567890abcdef' -CustomIcon 1 -ExpiryDate (Get-Date).AddDays(30)

    .EXAMPLE
        Edit-KeePassGroup -KeePassDatabase $KeePassDatabase -Uuid '1234567890abcdef1234567890abcdef' -AutoTypeBehavior 'Inherit'

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

        [string]$Name,

        [Parameter(ParameterSetName = 'icon')]
        [KeePassLib.PwIcon]$Icon,

        [Parameter(ParameterSetName = 'custom')]
        [ValidateScript({ ($_ -is [KeePassLib.PwCustomIcon]) -or ($_ -is [int]) })]
        [object]$CustomIcon,

        [string]$Notes,

        [datetime]$ExpiryDate,

        [ValidateSet('Inherit', 'Enabled', 'Disabled')]
        [string]$AutoTypeBehavior,

        [ValidateSet('Inherit', 'Enabled', 'Disabled')]
        [string]$SearchingBehavior,

        [ValidateSet('Inherit', 'Override')]
        [string]$AutoTypeSequence,

        [string]$AutoTypeOverride
    )

    Begin {
        If ($KeePassDatabase.IsOpen -eq $false) {
            Throw 'The KeePass database specified is not open'
        }

        [KeePassLib.PwGroup]$currGroup = (Test-KPIsValidGroup -KeePassDatabase $KeePassDatabase -InputObject $Uuid)
        If (-not $currGroup) { Throw 'Invalid Uuid given' }

        If ($CustomIcon -is [int]) {
            [KeePassLib.PwCustomIcon]$CustomIcon = (Get-KPCustomIcon -KeePassDatabase $KeePassDatabase -Index $CustomIcon)
        }
    }

    Process {
        If ($Name)       { $currGroup.Name           = $Name  }
        If ($Notes)      { $currGroup.Notes          = $Notes }
        If ($Icon)       { $currGroup.IconId         = $Icon  }
        If ($CustomIcon) { $currGroup.CustomIconUuid = $CustomIcon.Uuid }

        If ($ExpiryDate -eq ([datetime]::MinValue)) {
            $currGroup.Expires = $false
        }
        ElseIf ($ExpiryDate -gt ([datetime]::MinValue)) {
            $currGroup.Expires = $true
            $currGroup.ExpiryTime = $ExpiryDate
        }

        If ($AutoTypeBehavior) {
            Switch ($AutoTypeBehavior) {
                'Inherit'  { $currGroup.EnableAutoType = $null  }
                'Enabled'  { $currGroup.EnableAutoType = $true  }
                'Disabled' { $currGroup.EnableAutoType = $false }
            }
        }

        If ($SearchingBehavior) {
            Switch ($AutoTypeBehavior) {
                'Inherit'  { $currGroup.EnableAutoType = $null  }
                'Enabled'  { $currGroup.EnableAutoType = $true  }
                'Disabled' { $currGroup.EnableAutoType = $false }
            }
        }

        If ($AutoTypeSequence) {
            If ($AutoTypeSequence -eq 'Inherit') {
                $currGroup.DefaultAutoTypeSequence = $null
            }
            Else {
                If ($AutoTypeOverride) {
                    $currGroup.DefaultAutoTypeSequence = $AutoTypeOverride
                }
            }
        }

        $currGroup.Touch($true)
        $KeePassDatabase.Save($null)
    }

    End {
    }
}
