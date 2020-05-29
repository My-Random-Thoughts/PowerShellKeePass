Remove-Variable -Name * -ErrorAction SilentlyContinue
Remove-Module -Name 'PowerShellKeePass' -Force -ErrorAction SilentlyContinue
Clear-Host

# Variable Setup
While ($true) {
    [string]$dbName = "$env:temp\PowerShellKeePass.$([guid]::NewGuid())"
    If (-not (Test-Path -Path $dbName)) { Break }
}

Import-Module -Name 'PowerShellKeePass'
[string]$path = ((Get-Module -Name 'PowerShellKeePass').ModuleBase)
. "$path\private\Test-KPIsValidEntry.ps1"    # Required for tests when
. "$path\private\Test-KPIsValidGroup.ps1"    # editing entries and groups


Describe -Name 'PowerShellKeePass Tests' -Fixture {
    [object]$script:kpDB = $null
    BeforeAll -ScriptBlock {
        Initialize-KeePassModule
    }

    Context -Name 'Create New Databases' -Fixture {
        It -Name 'Create New KeePass Database Using A Password' -Test {
            $script:kpDB = (New-KeePassDatabase -FilePath "$($dbName)-Password.kdbx" -MasterPassword (ConvertTo-SecureString -String 'Passw0rd!' -AsPlainText -Force))
            $script:kpDB | Should -BeOfType 'KeePassLib.PwDatabase'
        }

        It -Name 'Create New KeePass Database Using A Key File' -Test {
            $script:kpDB = (New-KeePassDatabase -FilePath "$($dbName)-KeyFile.kdbx" -KeyFile "$env:windir\win.ini")
            $script:kpDB | Should -BeOfType 'KeePassLib.PwDatabase'
        }

        It -Name 'Create New KeePass Database Using A Windows User Account' -Test {
            $script:kpDB = (New-KeePassDatabase -FilePath "$($dbName)-WinAccount.kdbx" -UseWindowsUserAccount)
            $script:kpDB | Should -BeOfType 'KeePassLib.PwDatabase'
        }
    }

    Context -Name 'Create Groups' -Fixture {
        $groups = @(
            @{Name = 'Group 01';  Parent = ''}
            @{Name = 'Group 02';  Parent = ''}
            @{Name = 'Group 03';  Parent = ''}
            @{Name = 'Group 11';  Parent = '/Group 01'}
            @{Name = 'Group 12';  Parent = '/Group 01'}
            @{Name = 'Group 13';  Parent = '/Group 01'}
            @{Name = 'Group 21';  Parent = '/Group 02'}
            @{Name = 'Group 22';  Parent = '/Group 02'}
            @{Name = 'Group 221'; Parent = '/Group 02/Group 22'}
        )

        It -Name 'Creating "<Name>" Under "<Parent>"' -TestCases $groups -Test {
            Param (
                [string]$Name,
                [string]$Parent
            )
            New-KeePassGroup -KeePassDatabase $script:kpDB -Name $Name -ParentGroup $Parent -PassThru | Should -BeOfType 'KeePassLib.PwGroup'
        }
    }

    Context -Name 'Create Entries' -Fixture {
        $entries = @(
            @{ Title = 'Sample Entry 01'; Parent = '';                             Icon = 'Key';      Username = 'User 01'; Password = 'Password';                  Url = 'http://www.example.com' }
            @{ Title = 'Sample Entry 02'; Parent = '';                             Icon = 'World';    Username = 'User 02'; Password = '12345';                     Url = 'https://keepass.info/'  }
            @{ Title = 'Sample Entry 03'; Parent = '/Group 01';                    Icon = 'Warning';  Username = 'User 03'; Password = 'fhg9nmy4g';                 Url = 'http://www.example.com' }
            @{ Title = 'Sample Entry 04'; Parent = '/Group 01';                    Icon = 'Identity'; Username = 'User 04'; Password = 'fhg9n';                     Url = 'http://www.example.com' }
            @{ Title = 'Sample Entry 05'; Parent = '/Group 02';                    Icon = 'Parts';    Username = 'User 05'; Password = 'fhg9n%^my4g7m7e&*ghfmdgfd'; Url = 'http://www.example.com' }
            @{ Title = 'Sample Entry 06'; Parent = '/Group 02';                    Icon = 'Notepad';  Username = 'User 06'; Password = 'fhg9n%^my4';                Url = 'http://www.example.com' }
            @{ Title = 'Sample Entry 07'; Parent = '/Group 02/Group 22';           Icon = 'Digicam';  Username = 'User 07'; Password = 'fhg9nmy4g7m7egh';           Url = 'http://www.example.com' }
            @{ Title = 'Sample Entry 08'; Parent = '/Group 02/Group 22';           Icon = 'Energy';   Username = 'User 08'; Password = 'fhg9nmy4g7m7eghfmdgf';      Url = 'http://www.example.com' }
            @{ Title = 'Sample Entry 09'; Parent = '/Group 02/Group 22/Group 221'; Icon = 'Scanner';  Username = 'User 09'; Password = '';                          Url = 'http://www.example.com' }
        )

        It -Name 'Creating "<Title>" Under "<Parent>"' -TestCases $entries -Test {
            Param (
                [string]$Title,
                [string]$Parent,
                [string]$Icon,
                [string]$Username,
                [string]$Password,
                [string]$Url
            )
            If ($Password) { $securePassword = (ConvertTo-SecureString -String $Password -AsPlainText -Force) }
            New-KeePassEntry -KeePassDatabase $script:kpDB -Title $Title -ParentGroup $Parent -Icon $Icon -UserName $Username -Password $securePassword -Url $Url -PassThru | Should -BeOfType 'KeePassLib.PwEntry'
        }
    }

    Context -Name 'Set Database Properties' -Fixture {

        It -Name 'Set Database Name' -Test {
            { Set-KeePassDatabaseSetting -KeePassDatabase $script:kpDB -Name 'PowerShellKeePass' } | Should -Not -Throw
        }
        It -Name 'Set Database Colour and KDF to 1 second' -Test {
            { Set-KeePassDatabaseSetting -KeePassDatabase $script:kpDB -Colour Blue -UseAesKdf -KeyIterations -1 } | Should -Not -Throw
        }

        It -Name 'Set Database Key Interations to 10' -Test {
            { Set-KeePassDatabaseSetting -KeePassDatabase $script:kpDB -KeyIterations 10 } | Should -Not -Throw
        }
    }

    Context -Name 'Move Entries About' -Fixture {
        $moveEntries = @(
            @{ Source = 'Sample Entry 01'; Destination = '/Group 01/Group 11' }
            @{ Source = 'Sample Entry 02'; Destination = '/Group 01/Group 12' }
            @{ Source = 'Sample Entry 03'; Destination = '/Group 02/Group 22' }
            @{ Source = 'Sample Entry 05'; Destination = '/Group 01' }
            @{ Source = 'Sample Entry 07'; Destination = '/Group 01' }
        )

        It -Name 'Move "<Source>" to "<Destination>"' -TestCases $moveEntries -Test {
            Param (
                [string]$Source,
                [string]$Destination
            )
            { Move-KeePassEntry -KeePassDatabase $script:kpDB -Entry $Source -Destination $Destination } | Should -Not -Throw
        }
    }

    Context -Name 'Copy Entries About' -Fixture {
        $copyEntries = @(
            @{ Source = 'Sample Entry 02'; Destination = '/Group 02';                    AppendCopyToTitle = $true; UseReferences = $true;  IncludeHistory = $true  }
            @{ Source = 'Sample Entry 02'; Destination = '/Group 01/Group 11';           AppendCopyToTitle = $true; UseReferences = $false; IncludeHistory = $true  }
            @{ Source = 'Sample Entry 02'; Destination = '/Group 02/Group 22';           AppendCopyToTitle = $true; UseReferences = $false; IncludeHistory = $false }
            @{ Source = 'Sample Entry 02'; Destination = '/Group 02/Group 22/Group 221'; AppendCopyToTitle = $true; UseReferences = $true;  IncludeHistory = $false }
        )

        It -Name 'Copy "<Source>" To "<Destination>"' -TestCases $copyEntries -Test {
            Param (
                [string]$Source,
                [string]$Destination,
                [boolean]$AppendCopyToTitle,
                [boolean]$UseReferences,
                [boolean]$IncludeHistory
            )
            { Copy-KeePassEntry -KeePassDatabase $script:kpDB -Entry $Source -Destination $Destination -AppendCopyToTitle:$AppendCopyToTitle -UseReferences:$UseReferences -IncludeHistory:$IncludeHistory } | Should -Not -Throw
        }
    }

    Context -Name 'Delete Entries' -Fixture {
        $deleteEntries = @(
            @{ Entry = '/Group 02/Sample Entry 02 - Copy';                    Force = $true  }
            @{ Entry = '/Group 01/Group 11/Sample Entry 02 - Copy';           Force = $true  }
            @{ Entry = '/Group 02/Group 22/Sample Entry 02 - Copy';           Force = $false }
            @{ Entry = '/Group 02/Group 22/Group 221/Sample Entry 02 - Copy'; Force = $false }
        )

        It -Name 'Delete "<Entry>"' -TestCases $deleteEntries -Test {
            Param (
                [string]$Entry,
                [boolean]$Force
            )
            { Remove-KeePassEntry -KeePassDatabase $script:kpDB -Entry $Entry -Force:$Force } | Should -Not -Throw
        }
    }

    Context -Name 'Edit Entries' -Fixture {
        $editEntries = @(
            @{ Entry = 'Sample Entry 04';                    NewTitle = 'Renamed Entry 01'; NewUsername = 'Bob';  NewPassword = '';                NewIcon = 'Key'   }
            @{ Entry = '/Group 01/Sample Entry 05';          NewTitle = 'Renamed Entry 02'; NewUsername = '';     NewPassword = '';                NewIcon = 'Clock' }
            @{ Entry = '/Group 02/Sample Entry 06';          NewTitle = '';                 NewUsername = '';     NewPassword = 'SecurePassw0rd!'; NewIcon = 'Key'   }
            @{ Entry = '/Group 02/Group 22/Sample Entry 03'; NewTitle = 'Sample Entry 10';  NewUsername = 'John'; NewPassword = 'Passw0rd123';     NewIcon = 'Disk'  }
        )

        It -Name 'Editing "<Entry>"' -TestCases $editEntries -Test {
            Param (
                $Entry,
                $NewTitle,
                $NewUsername,
                $NewPassword,
                $NewIcon
            )
            $Uuid = (Test-KPIsValidEntry -KeePassDatabase $script:kpDB -InputObject $Entry).Uuid
            If ($NewPassword) { $securePassword = (ConvertTo-SecureString -String $NewPassword -AsPlainText -Force) }
            { Edit-KeePassEntry -KeePassDatabase $script:kpDB -Uuid $Uuid -Title $NewTitle -UserName $NewUsername -Password $securePassword -Icon $NewIcon} | Should -Not -Throw
        }

        It -Name 'Adding Attachment To "<NewTitle>"' -TestCases $editEntries -Test {
            Param (
                $Entry,
                $NewTitle
            )
            If ([string]::IsNullOrEmpty($NewTitle)) { $NewTitle = $Entry }
            $Uuid = (Test-KPIsValidEntry -KeePassDatabase $script:kpDB -InputObject $NewTitle).Uuid
            { Add-KeePassAttachment -KeePassDatabase $script:kpDB -Uuid $Uuid -Path "$env:windir\win.ini" -OverwriteExisting } | Should -Not -Throw
        }

        It -Name 'Exporting Attachment From "<NewTitle>"' -TestCases $editEntries -Test {
            Param (
                $Entry,
                $NewTitle
            )
            If ([string]::IsNullOrEmpty($NewTitle)) { $NewTitle = $Entry }
            $Uuid = (Test-KPIsValidEntry -KeePassDatabase $script:kpDB -InputObject $NewTitle).Uuid
            { Save-KeePassAttachment -KeePassDatabase $script:kpDB -Uuid $Uuid -Name 'win.ini' -Path $($env:Temp) -OverwriteExisting } | Should -Not -Throw
        }

        It -Name 'Remove Attachment From "<NewTitle>"' -TestCases $editEntries -Test {
            Param (
                $Entry,
                $NewTitle
            )
            If ([string]::IsNullOrEmpty($NewTitle)) { $NewTitle = $Entry }
            $Uuid = (Test-KPIsValidEntry -KeePassDatabase $script:kpDB -InputObject $NewTitle).Uuid
            { Remove-KeePassAttachment -KeePassDatabase $script:kpDB -Uuid $Uuid -Name 'win.ini' } | Should -Not -Throw
        }
    }

    Context -Name 'Move Groups About' -Fixture {
        $moveGroups = @(
            @{ Source = '/Group 01/Group 12'; Destination = '/Group 03' }
            @{ Source = '/Group 02/Group 21'; Destination = '/Group 03' }
        )

        It -Name 'Move "<Source>" to "<Destination>"' -TestCases $moveGroups -Test {
            Param (
                [string]$Source,
                [string]$Destination
            )
            { Move-KeePassGroup -KeePassDatabase $script:kpDB -Group $Source -Destination $Destination } | Should -Not -Throw
        }
    }

    Context -Name 'Copy Groups About' -Fixture {
        $copyGroups = @(
            @{ Source = '/Group 03/Group 12'; Destination = '/Group 01'; AppendCopyToTitle = $false; UseReferences = $false; IncludeHistory = $true  }
            @{ Source = '/Group 03/Group 21'; Destination = '/Group 02'; AppendCopyToTitle = $false; UseReferences = $false; IncludeHistory = $false }
        )

        It -Name 'Copy "<Source> To "<Destination>"' -TestCases $copyGroups -Test {
            Param (
                [string]$Source,
                [string]$Destination,
                [boolean]$AppendCopyToTitle,
                [boolean]$UseReferences,
                [boolean]$IncludeHistory
            )
            { Copy-KeePassGroup -KeePassDatabase $script:kpDB -Group $Source -Destination $Destination -AppendCopyToTitle:$AppendCopyToTitle -UseReferences:$UseReferences -IncludeHistory:$IncludeHistory } | Should -Not -Throw
        }

    }

    Context -Name 'Delete Groups' -Fixture {
        $deleteGroups = @(
            @{ Group = '/Group 03/Group 12'; Force = $true  }
            @{ Group = '/Group 03/Group 21'; Force = $true  }
            @{ Group = '/Group 01/Group 12'; Force = $false }
            @{ Group = '/Group 02/Group 21'; Force = $false }
        )

        It -Name 'Delete "<Group>"' -TestCases $deleteGroups -Test {
            Param (
                [string]$Group,
                [boolean]$Force
            )
            { Remove-KeePassGroup -KeePassDatabase $script:kpDB -Group $Group -Force:$Force } | Should -Not -Throw
        }
    }

    Context -Name 'Edit Groups' -Fixture {
        $editEntries = @(
            @{ Group = 'Group 01';                    NewName = 'Folder 01';    NewIcon = 'PaperQ'; NewNotes = 'Renamed from Group to Folder' }
            @{ Group = 'Folder 01/Group 13';          NewName = 'Group 12';     NewIcon = 'Clock';  NewNotes = '12 --> 13' }
            @{ Group = 'Group 02/Group 22/Group 221'; NewName = 'Group 222';    NewIcon = 'Key';    NewNotes = '' }
            @{ Group = 'Group 03';                    NewName = 'The Last One'; NewIcon = 'Note';   NewNotes = @'
This
is
a
multi
line
note
'@ }
        )

        It -Name 'Editing "<Group>"' -TestCases $editEntries -Test {
            Param (
                $Group,
                $NewName,
                $NewIcon,
                $NewNotes
            )
            $Uuid = (Test-KPIsValidGroup -KeePassDatabase $script:kpDB -InputObject $Group).Uuid
            { Edit-KeePassGroup -KeePassDatabase $script:kpDB -Uuid $Uuid -Name $NewName -Icon $NewIcon -Notes $NewNotes } | Should -Not -Throw
        }
    }

    Context -Name 'Various Tests' -Fixture {
        It -Name 'Empty The Recycle Bin' -Test {
            { Clear-KeePassRecycleBin -KeePassDatabase $script:kpDB } | Should -Not -Throw
        }

        It -Name 'Disable The Recycle Bin' -Test {
            { Disable-KeePassRecycleBin -KeePassDatabase $script:kpDB -RemoveGroup } | Should -Not -Throw
        }
    }

    Context -Name 'Show Current Tree View' -Fixture {
        Get-KeePassGroupTreeView -KeePassDatabase $script:kpDB -ShowEntries
    }

    Context -Name 'Database File Clean Up' -Fixture {
        It -Name 'Close KeePass Database' -Test {
            { Close-KeePassDatabase -KeePassDatabase $script:kpDB } | Should -Not -Throw
        }

        It -Name 'Delete Test Files' -Test {
            { Remove-Item -Path "$dbName-Password.kdbx"   -Force } | Should -Not -Throw
            { Remove-Item -Path "$dbName-KeyFile.kdbx"    -Force } | Should -Not -Throw
            { Remove-Item -Path "$dbName-WinAccount.kdbx" -Force } | Should -Not -Throw
            { Remove-Item -Path "$env:Temp\win.ini"       -Force } | Should -Not -Throw    # Attachment test file
        }
    }
}
