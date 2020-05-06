# Get public and private function definition files.

$public  = @( Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1"  -ErrorAction SilentlyContinue )
$private = @( Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -ErrorAction SilentlyContinue )
@($Public + $Private) | ForEach-Object { . $_.fullname }

Export-ModuleMember -Function $public.Basename
Import-KeePassModule
