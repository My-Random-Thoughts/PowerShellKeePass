# PowerShellKeePass
PowerShell 5 module for KeePass automation and manipulation

## Introduction
This module allows for the manipulation of a KeePass database that can be incorporated into scripts and toolsets for automation.  It could also be used as a command line tool if you don't want to use the GUI.  The only requirement for this module is that the latest KeePass version 2.xx is installed.  Get it from https://keepass.info/download.html

The `\tests` folder there is a Pester script that will run through all the functions of the module and ensure that they are all working correctly.

## Getting Started
1. Download and copy the module to the default module path, usually `C:\Program Files\Windows PowerShell\Modules\`
2. Import the module using `Import-Module -Name 'PowerShellKeePass'`
3. Import the KeePass Library using `Import-KeePassModule`.  If you have installed KeePass into its default folder, you can just type it as shown.  If KeePass is installed elsewhere, you'll need to add a path to the command: `Import-KeePassModule -Path 'path\to\KeePass.exe'`
4. Start using the module in your scripts!

## Highlights
### Group TreeView
In case you can't remember the group structure of your KeePass database, you can show the Tree view simple with the command `Get-KeePassGroupTreeView -KeePassDatabase $kpdb`

### Output and `-AsObject`
The default output of the module is to return a PSCustomObject containing everything available for the entires or groups you are requesting, however the default view is to show only the `Title`, `UserName`, `Url` and `LastModified` fields.  However, this is just a view and all other properties of the object are available.

    Title           UserName Url                    LastModified
    -----           -------- ---                    ------------
    Example Entry 1 Ann      http://www.example.com 01/01/2020 00:00:0
    Example Entry 2 Bob      http://keepass.info    01/01/2020 00:00:0

One of the parameters of some functions is the `-AsObject` parameter.  This will return the entry or group details as a KeePass object not a PSCustomObject.  


### Example 1 - New Database
This example will create a new KeePass database and populate it with an example entry.

    Import-Module -Name 'PowerShellKeePass'
    Import-KeePassModule
    $kpdb = (New-KeePassDatabase -FilePath 'C:\Database.kdbx' -MasterPassword 'Passw0rd!23' -KeeFile 'C:\KeeFile.txt')
    New-KeePassEntry -KeePassDatabase $kpdb -Title 'New Entry #1' -UserName 'Bob' -Icon 'Book'
    Close-KeePassDataBase -KeePassDatabase $kpdb

### Example 2 - Open Existing Database
This example will open an existing database and search for a specific entry.

    Import-Module -Name 'PowerShellKeePass'
    Import-KeePassModule
    $kpdb = (Open-KeePassDatabase -FilePath 'C:\Database.kdbx' -MasterPassword 'Passw0rd!23' -KeeFile 'C:\KeeFile.txt')
    Find-KeePassEntry -KeePassDatabase $kpdb -SearchFor 'Example' -Field Title
