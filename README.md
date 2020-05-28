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
In case you can't remember the group structure of your KeePass database, you can show the Tree view simple with the command `Get-KeePassGroupTreeView -KeePassDatabase $kpdb`.  The treeview for the default KeePass database is...

    ExampleDatabase
    │  ├─ E: Sample Entry
    │  └─ E: Sample Entry #2
    ├─ General
    ├─ Windows
    ├─ Network
    ├─ Internet
    ├─ eMail
    └─ Homebanking

### Output and `-AsObject`
The default output of the module is to return a PSCustomObject containing everything available for the entires or groups you are requesting, however the default view is to show only the `Title`, `UserName`, `Url` and `LastModified` fields.  However, this is just a view and all other properties of the object are available.

    Title           UserName   Url                                        LastModified
    -----           --------   ---                                        ------------
    Sample Entry    User Name  https://keepass.info/                      01/01/2020 00:00:00
    Sample Entry #2 Michael321 https://keepass.info/help/kb/testform.html 01/01/2020 00:00:00

The full details of an object would look something like this

    Uuid            : 68D516A7434D4744AC09F68501B5765F
    Title           : Sample Entry
    UserName        : User Name
    Password        : ********
    PasswordQuality : Very Weak (14 bits)
    Url             : https://keepass.info/
    Notes           : Notes
    FullPath        : Database
    Icon            : Key
    CustomIcon      :
    Created         : 00/00/2020 00:00:00
    LastAccessed    : 00/00/2020 00:00:00
    LastModified    : 00/00/2020 00:00:00
    Expiry          : N/A
    LocationChanged : 00/00/2020 00:00:00
    Touched         :
    UsageCount      : 0
    Fields          : {}
    Binaries        : {}
    SizeKB          : 1
    Foreground      : Color [Empty]
    Background      : Color [Empty]
    Tags            : {}
    OverrideUrl     :
    AutoType        : KeePassLib.Collections.AutoTypeConfig
    Credential      : System.Management.Automation.PSCredential
    KeePassObject   : KeePassLib.PwEntry

One of the parameters of some functions is the `-AsObject` parameter.  This will return the entry or group details as a KeePass object not a PSCustomObject.  

    Uuid                 : KeePassLib.PwUuid
    ParentGroup          : KeePassLib.PwGroup
    LocationChanged      : 28/05/2020 15:04:24
    Strings              : {[Notes, KeePassLib.Security.ProtectedString], [Password, KeePassLib.Security.Prote...}
    Binaries             : {}
    AutoType             : KeePassLib.Collections.AutoTypeConfig
    History              : {}
    IconId               : Key
    CustomIconUuid       : KeePassLib.PwUuid
    ForegroundColor      : Color [Empty]
    BackgroundColor      : Color [Empty]
    CreationTime         : 28/05/2020 15:04:24
    LastModificationTime : 28/05/2020 15:04:24
    LastAccessTime       : 28/05/2020 15:04:24
    ExpiryTime           : 28/05/2020 15:03:42
    Expires              : False
    UsageCount           : 0
    OverrideUrl          :
    Tags                 : {}
    CustomData           : {}
    Touched              :


### Example 1 - New Database
This example will create a new KeePass database and populate it with an example entry.

    Import-Module -Name 'PowerShellKeePass'
    Import-KeePassModule
    $kpdb = (New-KeePassDatabase -FilePath 'C:\ExampleDatabase.kdbx' -MasterPassword 'Passw0rd!23' -KeeFile 'C:\KeeFile.txt')
    New-KeePassEntry -KeePassDatabase $kpdb -Title 'New Entry #1' -UserName 'Bob' -Icon 'Book'
    Close-KeePassDataBase -KeePassDatabase $kpdb

### Example 2 - Open Existing Database
This example will open an existing database and search for a specific entry.

    Import-Module -Name 'PowerShellKeePass'
    Import-KeePassModule
    $kpdb = (Open-KeePassDatabase -FilePath 'C:\ExampleDatabase.kdbx' -MasterPassword 'Passw0rd!23' -KeeFile 'C:\KeeFile.txt')
    Find-KeePassEntry -KeePassDatabase $kpdb -SearchFor 'Sample Entry' -Field Title
