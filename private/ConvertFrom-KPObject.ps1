Function ConvertFrom-KPObject {
<#
    .SYNOPSIS
        Convert one or more PwEntry or PWGroup objects into a readable PSCustomObject

    .DESCRIPTION
        Convert one or more PwEntry or PWGroup objects into a readable PSCustomObject.  By default only four columns are shown in a table, but there are 27 values for PwEntry and 21 for PwGroup

    .PARAMETER KeePassDatabase
        Specifies the KeePass database object to search

    .PARAMETER KeePassDatabase
        Specifies the KeePass database object to search

    .PARAMETER KeePassEntry
        Specifies one or more PwEntry objects to convert

    .PARAMETER KeePassGroup
        Specifies one or more PwGroup objects to convert

    .PARAMETER WithCredential
        If specifying a PwEntry, also return the username and password as a PowerShell credential object

    .PARAMETER AsPlainText
        If specifying a PwEntry, also return the password as plain text

    .PARAMETER ReplaceColumn
        Used internally.  Replace a default shown column with the specified one

    .EXAMPLE
        ConvertFrom-KPObject -KeePassDatabase $KeePassDatabase -KeePassEntry $KeePassEntry -WithCredential -AsPlainText

    .NOTES
        For additional information please see my GitHub wiki page

    .LINK
        https://github.com/My-Random-Thoughts/PowerShellKeePass
#>

    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Scope = 'Function')]
    Param (
        [Parameter(Mandatory = $true)]
        [KeePassLib.PwDatabase]$KeePassDatabase,

        [Parameter(ParameterSetName = 'Entry', Mandatory = $true)]
        [KeePassLib.PwEntry[]]$KeePassEntry,

        [Parameter(ParameterSetName = 'Group', Mandatory = $true)]
        [KeePassLib.PwGroup[]]$KeePassGroup,

        [Parameter(ParameterSetName = 'Entry')]
        [switch]$WithCredential,

        [Parameter(ParameterSetName = 'Entry')]
        [switch]$AsPlainText,

        [Parameter(DontShow)]
        [string]$ReplaceColumn
    )

    Begin {
        # Set default object property display
        If ($PSCmdlet.ParameterSetName -eq 'Entry') {
            $defaultSet = @('Title', 'UserName', 'Url', 'LastModified')
        }
        Else {
            $defaultSet = @('Name', 'FullPath', 'EntryCount', 'GroupCount')
        }

        If (-not [string]::IsNullOrEmpty($ReplaceColumn)) {
            $del, $add = $ReplaceColumn.Split('>')
            $defaultSet.SetValue($add, $defaultSet.IndexOf($del))
        }

        $defaultPropertySet = (New-Object -TypeName 'System.Management.Automation.PSPropertySet'('DefaultDisplayPropertySet', [string[]]$defaultSet))
        $PSMemberInfo       = [System.Management.Automation.PSMemberInfo[]]@($defaultPropertySet)
    }

    Process {
        If ($PSCmdlet.ParameterSetName -eq 'Entry') {
            ForEach ($entry In $KeePassEntry) {
                [string]$username = $($entry.Strings.ReadSafe('UserName'))
                [string]$clrPassW = $($entry.Strings.ReadSafe('Password'))
                [string]$passQual = ([KeePassLib.Cryptography.QualityEstimation]::EstimatePasswordBits($clrPassW))

                If ($entry.Strings.GetSafe('Password').IsEmpty -eq $true) {
                    [string]$password = '(none)'
                    [string]$passQual = '(n/a)'
                }
                Else {
                    [string]$password = '********'
                    If ($AsPlainText.IsPresent) { $password = $clrPassW }
                    If ($WithCredential.IsPresent) {
                        If ([string]::IsNullOrEmpty($username)) { $username = '(none)' }
                        $entryCredential = (New-Object -TypeName 'pscredential' -ArgumentList @( $username, $clrPassW | ConvertTo-SecureString -AsPlainText -Force))
                    }
                }

                $keePassObject = ([pscustomobject][ordered]@{
                    'Uuid'            = $entry.Uuid.ToHexString()
                    'Title'           = $entry.Strings.ReadSafe('Title')
                    'UserName'        = $entry.Strings.ReadSafe('UserName')
                    'Password'        = $password
                    'PasswordQuality' = $passQual    # Also set below
                    'Url'             = $entry.Strings.ReadSafe('URL')
                    'Notes'           = $entry.Strings.ReadSafe('Notes')
                    'FullPath'        = $entry.ParentGroup.GetFullPath('/', $true)
                    'Icon'            = ''    # Set below
                    'CustomIcon'      = ''    # Set below
                    'Created'         = $entry.CreationTime
                    'LastAccessed'    = $entry.LastAccessTime
                    'LastModified'    = $entry.LastModificationTime
                    'Expiry'          = ''    # Set below
                    'LocationChanged' = $entry.LocationChanged
                    'Touched'         = $entry.Touched
                    'UsageCount'      = $entry.UsageCount
                    'Fields'          = @()    # Set below
                    'Binaries'        = @($entry.Binaries)
                    'SizeKB'          = $(($entry.GetSize() / 1KB) -as [int])
                    'Foreground'      = $entry.ForegroundColor
                    'Background'      = $entry.BackgroundColor
                    'Tags'            = $entry.Tags
                    'OverrideUrl'     = $entry.OverrideUrl
                    'AutoType'        = $entry.AutoType
                    'Credential'      = $entryCredential
                    'KeePassObject'   = $entry
                })

                # PASSWORD QUALITY
                # Table from: https://keepass.info/help/kb/pw_quality_est.html#trl
                If ($passQual -ne '(n/a)') {
                    [float]$Quality = $(([math]::Min([float]$passQual, [double]128) / [float]128.0))
                    If     ($Quality -le 0.2) { $keePassObject.PasswordQuality =   "Very Weak ($passQual bits)" }
                    ElseIf ($Quality -le 0.4) { $keePassObject.PasswordQuality =        "Weak ($passQual bits)" }
                    ElseIf ($Quality -le 0.6) { $keePassObject.PasswordQuality =    "Moderate ($passQual bits)" }
                    ElseIf ($Quality -le 0.8) { $keePassObject.PasswordQuality =      "Strong ($passQual bits)" }
                    Else                      { $keePassObject.PasswordQuality = "Very Strong ($passQual bits)" }
                }

                # ICON / CUSTOMICON
                If ($entry.CustomIconUuid -ne ([KeePassLib.PwUuid]::Zero)) {
                    $keePassObject.Icon       = ''
                    $keePassObject.CustomIcon = $KeePassDatabase.GetCustomIconIndex($entry.CustomIconUuid)
                }
                Else {
                    $keePassObject.Icon       = $entry.IconId
                    $keePassObject.CustomIcon = ''
                }

                # EXPIRY
                If ($entry.Expires -eq 'True') {
                    $keePassObject.Expiry = $entry.ExpiryTime
                }
                Else {
                    $keePassObject.Expiry = 'N/A'
                }

                # FIELDS
                $entry.Strings | `
                    Where-Object { $_.Key -notmatch 'Notes|Password|Title|Url|UserName' } | `
                    ForEach-Object {
                        $keePassObject.Fields += [pscustomobject]@{
                            Name = $_.Key
                            Value = $entry.Strings.ReadSafe($_.key)
                        }
                    }


                $keePassObject.PSObject.TypeNames.Insert(0, 'KeePassEntry.Output')
                $keePassObject | Add-Member -MemberType MemberSet -Name PSStandardMembers -Value $PSMemberInfo
                Write-Output $keePassObject
            }
        }
        Else {
            ForEach ($group In $KeePassGroup) {
                $keePassObject = ([pscustomobject][ordered]@{
                    'Uuid'                    = $group.Uuid.ToHexString()
                    'Name'                    = $group.Name
                    'Notes'                   = $group.Notes
                    'FullPath'                = $group.GetFullPath('/', $true)
                    'IconId'                  = $group.IconId
                    'CustomIconIndex'         = $KeePassDatabase.GetCustomIconIndex($group.CustomIconUuid)
                    'Groups'                  = $group.Groups
                    'GroupCount'              = $group.Groups.UCount
                    'Entries'                 = $group.Entries
                    'EntryCount'              = $group.Entries.UCount
                    'Created'                 = $group.CreationTime
                    'LastAccessed'            = $group.LastAccessTime
                    'LastModified'            = $group.LastModificationTime
                    'Expiry'                  = ''    # Set below
                    'LocationChanged'         = $group.LocationChanged
                    'Touched'                 = $group.Touched
                    'UsageCount'              = $group.UsageCount
                    'EnableAutoType'          = ''    # Set below
                    'EnableSearching'         = ''    # Set below
                    'DefaultAutoTypeSequence' = ''    # Set below
                    'KeePassObject'           = $group
                })

                If ($group.Expires -eq 'False') { $keePassObject.Expiry = $group.ExpiryTime } Else { $keePassObject.Expiry = 'N/A' }

                @('EnableAutoType','EnableSearching','DefaultAutoTypeSequence') | ForEach-Object {
                    If ($($group.$_.Length) -eq 0) { $keePassObject.$_ = 'Inherited' } Else { $keePassObject.$_ = $($group.$_) }
                }

                $keePassObject.PSObject.TypeNames.Insert(0, 'KeePassEntry.Output')
                $keePassObject | Add-Member -MemberType MemberSet -Name PSStandardMembers -Value $PSMemberInfo
                Write-Output $keePassObject
            }
        }
    }

    End {
    }
}
