# By Martin Liversage - martin@liversage.com

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$allProtocols = @{
    'SSL20' = 'SSL 2.0';
    'SSL30' = 'SSL 3.0';
    'TLS10' = 'TLS 1.0';
    'TLS11' = 'TLS 1.1';
    'TLS12' = 'TLS 1.2'
}

function GetSChannelServerProtocolState([String] $protocol) {
    $registryName = $allProtocols.Item($protocol)
    $registryValue = Get-ItemProperty -Path Registry::HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$registryName\Server -Name Enabled -ErrorAction SilentlyContinue
    if ($registryValue -eq $null) {
        return 'Default';
    }
    elseif ($registryValue.Enabled -eq 0) {
        return 'Disabled';
    }
    return 'Enabled';
}

<#

.SYNOPSIS

Get the server status of the secure channel protocols.

.DESCRIPTION

The Get-SChannelServerProtocol retrieves information from the registry about the
server status of the secure channel protocols (SSL, TLS).

The status can be either Enabled or Disabled. If no status is specified in the
registry the status is Default which means that the protocol may or may not be
enabled depending on the version of the operating system.

Only the server status which affects Internet Information Services is retrieved.
The client status which affects web browsers is not retrieved.

.PARAMETER Protocols

A single protocol name or an array of protocol names to retrieve the server
status for. Valid protocol names are SSL20, SSL30, TLS10, TLS11 and TLS12. If no
protocols are specified the server status of all protocols are retrieved.

.OUTPUTS

PSObject with properties Protocol and Status.

.EXAMPLE

Get the server status of all the secure channel protocols:

Get-SChannelServerProtocol

.EXAMPLE

Get the server status of the SSL 2.0 and SLL 3.0 protocols:

Get-SChannelServerProtocol -Protocols SSL20, SSL30

.LINK

http://support.microsoft.com/kb/245030

#>

function Get-SChannelServerProtocol {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, HelpMessage = 'Specifies the secure channel protocols.')]
        [ValidateSet('SSL20', 'SSL30', 'TLS10', 'TLS11', 'TLS12')]
        [String[]] $Protocols = @('SSL20', 'SSL30', 'TLS10', 'TLS11', 'TLS12')
    )
    PROCESS {
        $Protocols | ForEach-Object -Process { New-Object -TypeName PSObject -Property @{ Protocol = $_; Status = GetSChannelServerProtocolState($_) } }
    }
}

<#

.SYNOPSIS

Set the server status of the secure channel protocols.

.DESCRIPTION

The Set-SChannelServerProtocol writes information to the registry to configure
the server status of the secure channel protocols (SSL, TLS).

The status can be either Enabled, Disabled or Default. Default means that no
status is specified in the registry and the protocol may or may not be enabled
depending on the version of the operating system.

Only the server status which affects Internet Information Services is
configured. The client status which affects web browsers is not configured.

.PARAMETER Protocols

A single protocol name or an array of protocol names to set the server status
for. Valid protocol names are SSL20, SSL30, TLS10, TLS11 and TLS12.

.PARAMETER Status

The server status to set for all the protocols specified. Valid status names are
Enabled, Disabled and Default.

.PARAMETER RestartWithoutConfirmation

If specified restarts the computer immediately without confirmation.

.EXAMPLE

Set the server status the SSL 3.0 protocol to disabled:

Set-SChannelServerProtocol -Protocols SSL30 -Status Disabled

.EXAMPLE

Set the server status the SSL 2.0 and SSL 3.0 protocols to disabled and restarts
the computer without confirmation:

Set-SChannelServerProtocol -Protocols SSL20, SSL30 -Status Disabled -RestartWithoutConfirmation

.NOTES

Administrative rights are required to change the status of the secure channel
protocols.

A computer restart is required before any changes will be effective.

.LINK

http://support.microsoft.com/kb/245030

#>

function Set-SChannelServerProtocol {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'Specifies the secure channel protocols.')]
        [ValidateSet('SSL20', 'SSL30', 'TLS10', 'TLS11', 'TLS12')]
        [String[]] $Protocols,
        [Parameter(Mandatory = $true, Position = 1, HelpMessage = 'Specifies the status of the secure channel protocols.')]
        [ValidateSet('Default', 'Disabled', 'Enabled')]
        [String] $Status,
        [Parameter(HelpMessage = 'Restarts the computer without confirmation.')]
        [Switch] $RestartWithoutConfirmation
    )
    PROCESS {
        Foreach ($protocol in $Protocols) {
            $registryName = $allProtocols.Item($protocol)
            $registryKey = "Registry::HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$registryName\Server"
            if ($Status -eq 'Default') {
                Remove-Item -Path $registryKey -Force
            }
            else {
                $enabled = @{ 'Disabled' = 0; 'Enabled' = 1 }[$Status]
                $null = New-Item -Path $registryKey -Force
                Set-ItemProperty -Path $registryKey -Name Enabled -Type DWord -Value $enabled
            }
        }

        Write-Host 'A computer restart is required before the change will be effective.'
        if ($RestartWithoutConfirmation) {
            Restart-Computer
        }
        else {
            Restart-Computer -Confirm
        }
    }
}

Export-ModuleMember -Function Get-SChannelServerProtocol, Set-SChannelServerProtocol
