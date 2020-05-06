Function Get-KPKDFOneSecondInteration {
<#
    .SYNOPSIS
        Calculate the parameters required for a one second delay for the key derivation functions

    .DESCRIPTION
        Calculate the parameters required for a one second delay for the key derivation functions

    .PARAMETER KeyDerivationFunction
        Specifies the key derivation function to use

    .PARAMETER UseDefaultValues
        Return the default builtin values instead of calculating one

    .EXAMPLE
        Get-KPKDFOneSecondInteration

    .NOTES
        For additional information please see my GitHub wiki page

    .LINK
        https://github.com/My-Random-Thoughts/PowerShellKeePass
#>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Aes-Kdf', 'Argon2')]
        [string]$KeyDerivationFunction,

        [switch]$UseDefaultValues
    )

    Try {
        $KdfParameters = (New-Object -TypeName 'KeePassLib.Cryptography.KeyDerivation.KdfParameters'([KeePassLib.PwUuid]::Zero))
        Switch ($KeyDerivationFunction) {
            'Aes-Kdf' { $kdfEngine = (New-Object -TypeName 'KeePassLib.Cryptography.KeyDerivation.AesKdf')    }
            'Argon2'  { $kdfEngine = (New-Object -TypeName 'KeePassLib.Cryptography.KeyDerivation.Argon2Kdf') }
            Default   { Throw 'Invalid Key Derivation Function given' }
        }

        If ($UseDefaultValues.IsPresent) {
            $KdfParameters = $kdfEngine.GetDefaultParameters()
        }
        Else {
            $KdfParameters = $kdfEngine.GetBestParameters(1000)
        }

        Return $KdfParameters
    }
    Catch {
        Throw $_
    }
}
