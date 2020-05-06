Function Enable-KeePassRecycleBin {
<#
    .SYNOPSIS
        Enable the recycle bin for the specified KeePass database

    .DESCRIPTION
        Enable the recycle bin for the specified KeePass database

    .PARAMETER KeePassDatabase
        Specifies the KeePass database object to use

    .PARAMETER Group
        Specifies the group to use for the recycle bin.  If not specified, one wil be automatically created

    .PARAMETER CreateNow
        Specify to create the recycle bin group using the default properties

    .EXAMPLE
        Enable-KeePassRecycleBin -KeePassDatabase $KeePassDatabase -CreateNow

    .NOTES
        For additional information please see my GitHub wiki page

    .LINK
        https://github.com/My-Random-Thoughts/PowerShellKeePass
#>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [KeePassLib.PwDatabase]$KeePassDatabase,

        [object]$Group,

        [switch]$CreateNow
    )

    Begin {
            If ($KeePassDatabase.IsOpen -eq $false) {
            Throw 'The KeePass database specified is not open'
        }

        If ($KeePassDatabase.RecycleBinEnabled) {
            Write-Verbose -Message 'Nothing to do, recycle bin already enabled'
            Return
        }
    }

    Process {
        $KeePassDatabase.RecycleBinEnabled = $true
        $KeePassDatabase.RecycleBinChanged = (Get-Date)
        Write-Verbose -Message 'Enabled recycle bin'
        $KeePassDatabase.Save($null)

        If ($CreateNow.IsPresent) {
            [void](Confirm-KPRecycleBin -KeePassDatabase $KeePassDatabase)
        }
    }

    End {
    }
}
