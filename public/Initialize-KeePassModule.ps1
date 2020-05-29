Function Initialize-KeePassModule {
<#
    .SYNOPSIS
        Initializes the KeePass assembly for use

    .DESCRIPTION
        Initializes the KeePass assembly for use.  Also populates the Popular Password object which is used when calculating password complexity

    .PARAMETER KeePassLocation
        Specifies the location of the KeePass executable file.  Defaults to the default install folder of 'C:\Program Files (x86)\KeePass Password Safe 2\KeePass.exe'

    .EXAMPLE
        Import-KeePassModule

    .EXAMPLE
        Import-KeePassModule -KeePassLocation 'X:\KeePassInstall\KeePass.exe'

    .NOTES
        For additional information please see my GitHub wiki page

    .LINK
        https://github.com/My-Random-Thoughts/PowerShellKeePass
#>

    [CmdletBinding()]
    Param (
        [ValidateScript({ Test-Path -Path $_ })]
        [string]$KeePassLocation = 'C:\Program Files (x86)\KeePass Password Safe 2\KeePass.exe'
    )

    Begin {
        If (-not $KeePassLocation.EndsWith('.exe')) {
            $KeePassLocation = $KeePassLocation.Trim('\') + '\KeePass.exe'
            If (-not (Test-Path -Path $KeePassLocation)) {
                Throw 'KeePass.exe file not found'
            }
        }
    }

    Process {
        Try {
            $kpEXE = [reflection.assembly]::LoadFile($KeePassLocation)

            If ([KeePassLib.Cryptography.PopularPasswords]::IsPopularPassword('password') -eq $false) {
                [KeePassLib.Cryptography.PopularPasswords]::Add(([KeePass.Program]::Resources.GetObject('MostPopularPasswords')), $true)
            }

            Write-Verbose -Message "Loaded version: $($kpEXE.FullName.Substring($kpEXE.FullName.IndexOf('Version=') + 8, 6))"
        }
        Catch {
            Throw $_
        }
    }

    End {
    }
}
