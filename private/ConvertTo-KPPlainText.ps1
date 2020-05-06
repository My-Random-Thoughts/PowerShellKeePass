Function ConvertTo-KPPlainText {
<#
    .SYNOPSIS
        Convert a secure string into a plain test string

    .DESCRIPTION
        Convert a secure string into a plain test string.  The secure string must have been created by the current user on the current machine

    .PARAMETER InputString
        Specifies the input string to convert

    .EXAMPLE
        ConvertTo-KPPlainText -InputString $SecureStringObject

    .NOTES
        For additional information please see my GitHub wiki page

    .LINK
        https://github.com/My-Random-Thoughts/PowerShellKeePass
#>

    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Scope = 'Function')]
    Param (
        [Parameter(Mandatory = $true)]
        [securestring]$InputString
    )

    [string]$Password = (ConvertFrom-SecureString -SecureString $InputString)
    Return ((New-Object System.Net.NetworkCredential('Null', $(ConvertTo-SecureString -String $Password), 'Null')).Password)
}
