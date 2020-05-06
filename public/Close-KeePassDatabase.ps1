Function Close-KeePassDatabase {
<#
    .SYNOPSIS
        Close the currently open KeePass database

    .DESCRIPTION
        Close the currently open KeePass database.  This should be called everytime you have finished using the database

    .PARAMETER KeePassDatabase
        Specifies the KeePass database object to close

    .EXAMPLE
        Close-KeePassDatabase -KeePassDatabase $KeePassDatabase

    .NOTES
        For additional information please see my GitHub wiki page

    .LINK
        https://github.com/My-Random-Thoughts/PowerShellKeePass
#>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [KeePassLib.PwDatabase]$KeePassDatabase
    )

    Begin {
        If ($KeePassDatabase.IsOpen -eq $false) {
            Throw 'The KeePass database specified is not open'
        }
    }

    Process {
        Try {
            $KeePassDatabase.Close()
            $KeePassDatabase = $null
            Write-Verbose 'Database closed successfully'
        }
        Catch {
            Throw $_
        }
    }

    End {
    }
}
