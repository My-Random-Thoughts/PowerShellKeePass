Function New-KeePassPassword {
<#
    .SYNOPSIS
        Create a new secure password

    .DESCRIPTION
        Create a new secure password.  This function does not rely on a database to be currently opened

    .PARAMETER Length
        Specify the length of the password.  Defaults to 32

    .PARAMETER Upper
        Specify to use the uppercase letters.  If nothing is selected, defaults to true

    .PARAMETER Lower
        Specify to use the lowercase letters.  If nothing is selected, defaults to true

    .PARAMETER Digit
        Specify to use the numerical digits.  If nothing is selected, defaults to true

    .PARAMETER Minus
        Specify to use the minus character

    .PARAMETER Underline
        Specify to use the underline character

    .PARAMETER Space
        Specify to use the space character

    .PARAMETER Special
        Specify to use special characters.  These are the printable 7-bit special characters

    .PARAMETER Brackets
        Specify to use bracket characters.  These are: [, ], {, }, (, ), <, >

    .PARAMETER Latin1
        Specify to use the Latin-1 supplement characters.  These are the second Unicode block in the Unicode standard.  This block ranges from U+0080 to U+00FF and contains 128 characters

    .PARAMETER Include
        Specify to include any additional characters not otherwise selected

    .PARAMETER Pattern
        Specify to generate a password using a pattern.  See https://keepass.info/help/base/pwgenerator.html#pattern for more information

    .PARAMETER RandomlyPemute
        Specify to randomise the pattern generated string

    .PARAMETER NoRepeatingCharacters
        Specify to not repeat any characters.  This will show an on screen warning when selected

    .PARAMETER ExcludeLookalike
        Specify to exclude characters that look similar.  This will show an on screen warning when selected

    .PARAMETER ExcludeCharacters
        Specifiy to exclude specific charaters.  This will show an on screen warning when selected

    .PARAMETER AsSecureString
        Specifiy to return the password as a secure string

    .EXAMPLE
        New-KeePassPassword

    .EXAMPLE
        New-KeePassPassword -Length 64 -Upper -Lower -Brackets

    .EXAMPLE
        New-KeePassPassword -Pattern 'h{32}'

    .EXAMPLE
        New-KeePassPassword -Pattern 'h{32}' -ExcludeCharacters 'abcde'

    .NOTES
        For additional information please see my GitHub wiki page

    .LINK
        https://github.com/My-Random-Thoughts/PowerShellKeePass
#>

    [CmdletBinding(DefaultParameterSetName = 'CharSet')]
    Param (
        [Parameter(ParameterSetName = 'CharSet')]
        [int]$Length = 32,

        [Parameter(ParameterSetName = 'CharSet')]
        [switch]$Upper,

        [Parameter(ParameterSetName = 'CharSet')]
        [switch]$Lower,

        [Parameter(ParameterSetName = 'CharSet')]
        [switch]$Digit,

        [Parameter(ParameterSetName = 'CharSet')]
        [switch]$Minus,

        [Parameter(ParameterSetName = 'CharSet')]
        [switch]$Underline,

        [Parameter(ParameterSetName = 'CharSet')]
        [switch]$Space,

        [Parameter(ParameterSetName = 'CharSet')]
        [switch]$Special,

        [Parameter(ParameterSetName = 'CharSet')]
        [switch]$Brackets,

        [Parameter(ParameterSetName = 'CharSet')]
        [switch]$Latin1,

        [Parameter(ParameterSetName = 'CharSet')]
        [string]$Include = '',

        [Parameter(ParameterSetName = 'Pattern', Mandatory = $true)]
        [string]$Pattern,

        [Parameter(ParameterSetName = 'Pattern')]
        [switch]$RandomlyPemute,

        [switch]$NoRepeatingCharacters,

        [switch]$ExcludeLookalike,

        [string]$ExcludeCharacters = '',

        [switch]$AsSecureString
    )

    Begin {
        $genPassword = (New-Object -TypeName 'KeePassLib.Security.ProtectedString')
        $passProfile = (New-Object -TypeName 'KeePassLib.Cryptography.PasswordGenerator.PwProfile')
        $passProfile.GeneratorType = $PSCmdlet.ParameterSetName

        If ($PSCmdlet.ParameterSetName -eq 'CharSet') {
            $setParams = @($PSBoundParameters.Keys | Where-Object {
                $_ -notmatch 'CharactersOccurOnce|ExcludeLookalike|ExcludeCharacters|AsSecureString'
            })
            If ($setParams.Count -le 1) {
                Write-Warning -Message 'At least one character set must be selected, using defaults'
                $Upper = $true
                $Lower = $true
                $Digits = $true
            }

            $passProfile.CharSet = (New-Object -TypeName 'KeePassLib.Cryptography.PasswordGenerator.PwCharSet')
        }

        If ($NoRepeatingCharacters -or $ExcludeLookalike -or $ExcludeCharacters) {
            Write-Warning -Message 'Enabled options are reducing the security of generated passwords'
        }
    }

    Process {
        If ($PSCmdlet.ParameterSetName -eq 'CharSet') {
            $passProfile.Length = $Length
            If ($Upper.IsPresent)     { $passProfile.CharSet.Add([KeePassLib.Cryptography.PasswordGenerator.PwCharSet]::UpperCase) }
            If ($Lower.IsPresent)     { $passProfile.CharSet.Add([KeePassLib.Cryptography.PasswordGenerator.PwCharSet]::LowerCase) }
            If ($Digits.IsPresent)    { $passProfile.CharSet.Add([KeePassLib.Cryptography.PasswordGenerator.PwCharSet]::Digits)    }
            If ($Minus.IsPresent)     { $passProfile.CharSet.Add('-') }
            If ($Underline.IsPresent) { $passProfile.CharSet.Add('_') }
            If ($Space.IsPresent)     { $passProfile.CharSet.Add(' ') }
            If ($Special.IsPresent)   { $passProfile.CharSet.Add([KeePassLib.Cryptography.PasswordGenerator.PwCharSet]::Special)   }
            If ($Brackets.IsPresent)  { $passProfile.CharSet.Add([KeePassLib.Cryptography.PasswordGenerator.PwCharSet]::Brackets)  }
            If ($Latin1.IsPresent)    { $passProfile.CharSet.Add([KeePassLib.Cryptography.PasswordGenerator.PwCharSet]::Latin1S)   }

            Write-Debug -Message "Using the follwing character set: $($passProfile.CharSet.ToString())"
        }
        Else {
            If ($Pattern) { $passProfile.Pattern = $Pattern }
            $passProfile.PatternPermutePassword = $RandomlyPemute.IsPresent
        }

        $passProfile.ExcludeCharacters     = $ExcludeCharacters
        $passProfile.ExcludeLookAlike      = $ExcludeLookalike.IsPresent
        $passProfile.NoRepeatingCharacters = $NoRepeatingCharacters.IsPresent

        $genResult = [KeePassLib.Cryptography.PasswordGenerator.PwGenerator]::Generate([ref]$genPassword, $passProfile, $null, $null)

        If ($genResult -ne 'Success') {
            Throw $genResult
        }

        If ($AsSecureString.IsPresent) {
            Return (ConvertTo-KPSecureString -InputString $genPassword.ReadString())
        }
        Else {
            Return $genPassword.ReadString()
        }
    }

    End {
    }
}
