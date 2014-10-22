PowerShell
==========

_PowerShell cmdlets and scripts_

SChannelServerProtocol
----------------------

Allows you to get and set the server status of the secure channel protocols (SSL and TLS in IIS).

To install the module execute the following command in PowerShell:

```PowerShell
Import-Module .\SChannelServerProtocol.psm1
```

To get help:

```PowerShell
Get-Help Get-SChannelServerProtocol
Get-Help Set-SChannelServerProtocol
```

To turn off SSL 3.0 in IIS (to protect against the [POODLE](http://en.wikipedia.org/wiki/POODLE) attack):

```PowerShell
Set-SChannelServerProtocol -Protocols SSL30 -Status Disabled
```

This requires administrative rights and a computer restart is necessary.
