Function ConvertTo-KPSecureString {
<#
    .SYNOPSIS
        Converts plain text to a secure string

    .DESCRIPTION
        Converts plain text to a secure string.  This is just a simple wrapper around ConvertTo-SecureString

    .PARAMETER InputString
        Specifies the string to convert to a secure string

    .EXAMPLE
        ConvertTo-KPSecureString -InputString 'Password'

    .NOTES
        For additional information please see my GitHub wiki page

    .LINK
        https://github.com/My-Random-Thoughts/PowerShellKeePass
#>

    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Scope = 'Function')]
    Param (
        [Parameter(Mandatory = $true)]
        [string]$InputString
    )

    If ($InputString) {
        Return (ConvertTo-SecureString -String $InputString -AsPlainText -Force)
    }
    Return $null
}
