# Copyright (c) Microsoft. All rights reserved.
# This code is licensed under the Microsoft Public License.
# THIS CODE IS PROVIDED *AS IS* WITHOUT WARRANTY OF
# ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY
# IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR
# PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT.

[byte]$BMCResponderAddress = 0x20
[byte]$GetLANInfoCmd = 0x02
[byte]$GetChannelInfoCmd = 0x42
[byte]$SetSystemInfoCmd = 0x58
[byte]$GetSystemInfoCmd = 0x59
[byte]$DefaultLUN = 0x00
[byte]$IPMBProtocolType = 0x01
[byte]$8023LANMediumType = 0x04
[byte]$MaxChannel = 0x0b
[byte]$EncodingAscii = 0x00
[byte]$MaxSysInfoDataSize = 19

$CompletionCodes = @(
"C0h Node Busy. Command could not be processed because command processing resources are temporarily unavailable.",
"C1h Invalid Command. Used to indicate an unrecognized or unsupported command.",
"C2h Command invalid for given LUN.",
"C3h Timeout while processing command. Response unavailable.",
"C4h Out of space. Command could not be compl eted because of a lack of storage space required to execute the given command operation.",
"C5h Reservation Canceled or Invalid Reservation ID.",
"C6h Request data truncated.",
"C7h Request data length invalid.",
"C8h Request data field length limit exceeded.",
"C9h Parameter out of range. One or more parameters in the data field of the Request are out of range. This is different from ‘Invalid data field’ (CCh) code in that it indicates that the erroneous field(s) has a contiguous range of poss ible values.",
"CAh Cannot return number of requested data bytes.",
"CBh Requested Sensor, data, or record not present.",
"CCh Invalid data field in Request",
"CDh Command illegal for specified sensor or record type.",
"CEh Command response could not be provided.",
"CFh Cannot execute duplicated request. This completion code is for devices which cannot return the response that was returned for the original instance of the request. Such devices should provide separate commands that allow the completion status of the original request to be determined. An Event Receiver does not use this completion code, but returns the 00h completion code in the response to (valid) duplicated requests.",
"D0h Command response could not be provided. SDR Repository in  update mode.",
"D1h Command response could not be provided. Device in firmware update mode.",
"D2h Command response could not be provided. BMC initialization or initialization agent in progress.",
"D3h Destination unavailable. Cannot deliver request  to selected destination. E.g. this code can be returned if a request message is targeted to SMS, but receive message queue reception is disabled for the particular channel.",
"D4h Cannot execute command due to insufficient privilege level or other security-based restriction (e.g. disabled for ‘firmware firewall’).",
"D5h Cannot execute command. Command, or request parameter(s), not supported in present state. ",
"D6h Cannot execute command. Parameter is illegal because command sub-function has been disabled or is unavailable (e.g. disabled for ‘firmware firewall’).")

function Convert-CompletionCodeToText([byte] $code) {
    if ($code -gt 0xD6) {
        return "Unknown error: $code"
    }
    return $CompletionCodes[$code - 0xC0]
}

function Get-NetFn ([byte] $Command) {
    [byte]$TransportNetFn = 0x0c
    [byte]$AppNetFn = 0x06

    switch ($Command) {
        $GetLANInfoCmd { $TransportNetFn }
        default { $AppNetFn }
    }
}

function Invoke-IPMIRequestResponse {
    [CmdletBinding(DefaultParametersetName="CimSession")]
    Param (
        [Parameter(ParameterSetName="CimSession",Position=0)]
        [Microsoft.Management.Infrastructure.CimSession] $CimSession,
        [byte]$Command,
        [byte]$LUN = $DefaultLUN,
        [byte[]]$RequestData,
        [byte]$ResponderAddress = $BMCResponderAddress)

    Process {
        $ErrorActionPreference = "SilentlyContinue"

        if ($CimSession -eq $null) {
            $CimSession = New-CimSession
        }

        $ipmi = Get-CimInstance -Namespace root/wmi -CimSession $CimSession Microsoft_IPMI
        $ErrorActionPreference = "Stop"

        if ($null -eq $ipmi) {
            Write-Error "Microsoft IPMI Driver not running on specified system"
        }

        $arguments = @{Command=$Command;LUN=$LUN;NetworkFunction=$(Get-NetFn $command);RequestData=$RequestData;RequestDataSize=[uint32]$RequestData.Length;ResponderAddress=$ResponderAddress}
        Write-Debug "InvokeIPMI -command $command -lun $lun -netfn $(Get-NetFn $command) -requestData $requestData -ResponderAddress $responderaddress"
        $out = Invoke-CimMethod -InputObject $ipmi -CimSession $CimSession RequestResponse -Arguments $arguments
        if ($out.CompletionCode -ne 0) {
            Write-Error ("IPMI Command failed (0x{0:x}): {1}" -f $out.CompletionCode,(Convert-CompletionCodeToText $out.CompletionCode))
        }
        $out.ResponseData
        Write-Debug "InvokeIPMI -responsedata $($out.responseData)"
    }
}

function Get-IPMISystemInfoHelper ([byte] $Parameter) {
    [string]$outString = ""
    [byte]$set = 0
    [byte[]]$requestData = @(0,$Parameter,$set,0)
    Write-Debug "GetSystemInfoCmd -Parameter $parameter -Set $set -RequestData $requestData"
    $out = Invoke-IPMIRequestResponse -CimSession $CimSession -Command $GetSystemInfoCmd -RequestData $requestData
    $encoding = $out[3]
    $length = $out[4]
    $startIndex = 5
    while($length -gt 0) {
        for($i=$startIndex;$i -lt $MaxSysInfoDataSize; $i++) {
            switch ($encoding) {
                $EncodingAscii { $outString += [char]($out[$i]) }
                default { Write-Error "Unsupported Encoding type for Get System Info command: $encoding" }
            }
            $length--
            if ($length -eq 0) {
                break
            }
        }
        if ($length -eq 0) {
            break
        }
        Write-Debug "GetSystemInfoCmd -outstring $outstring"
        $set++
        $out = Invoke-IPMIRequestResponse -CimSession $CimSession -Command $GetSystemInfoCmd -RequestData @(0,$Parameter,$set,0)
        $startIndex = 3
    }
    $outString
}

function Set-IPMISystemInfoHelper ([byte] $Parameter, [string] $Text) {

    #if ($Text.Length -gt 32) {
    #    $Text = $Text.Substring(0,32) # IPMI only requires 2 16-byte blocks, although 3 is recommended
    #}

    [byte]$set = 0
    [System.Text.Encoding] $encoding = [System.Text.Encoding]::ASCII
    [byte[]] $bytes = $encoding.GetBytes($text)
    [byte]$length = $bytes.Length
    [byte[]] $requestData = @($Parameter, $set, $EncodingAscii, $length)
    $startIndex = 5
    $textIndex = 0
    Write-Debug "Set-IPMISystemInfoHelper -Parameter $Parameter -Text '$text' -Length $length"

    if ($length -eq 0) {
        $out = Invoke-IPMIRequestResponse -CimSession $CimSession -Command $SetSystemInfoCmd -RequestData $requestData
        return
    }

    while($length -gt 0) {
        for($i=$startIndex;$i -lt $MaxSysInfoDataSize; $i++) {
            $requestData += $bytes[$textIndex++]
            $length--
            if ($length -eq 0) {
                break
            }
        }
        Write-Debug "SetSystemInfoCmd -Parameter $parameter -Set $set -RequestData $requestData"
        $out = Invoke-IPMIRequestResponse -CimSession $CimSession -Command $SetSystemInfoCmd -RequestData $requestData
        if ($length -eq 0) {
            break
        }
        $set++
        $requestData = @($Parameter, $set)
        $startIndex = 3
    }
}

function Set-IPMIOSInfo {
    <#
    .Synopsis
        Store OS information into BMC
    .Description
        Store OS information from the running OS into BMC system information store.  On success, nothing is returned.
    .Example
        Set-IPMIOSInfo -RunningOS -CimSession $remoteSystem
    .Parameter CimSession
        Used to execute this cmdlet against a remote system.  See New-CimSession cmdlet on creating a CimSession.
        If not specified, cmdlet is executed against local machine.  Administrator rights required to execute IPMI commands.
    .Parameter PrimaryOS
        Specifies that the operation is only against the Primary OS parameter.
        If neither PrimaryOS nor RunningOS are specified, the operation is against both.
    .Parameter RunningOS
        Specifies that the operation is only against the Running OS parameter.
        If neither PrimaryOS nor RunningOS are specified, the operation is against both.
    .Parameter Clear
        Specified that the operation clears the information from the BMC.
        If neither PrimaryOS nor RunningOS are specified, the operation is against both.
    #>
    [CmdletBinding(DefaultParametersetName="CimSession")]
    Param (
        [Parameter(ParameterSetName="CimSession",Position=0)]
        [Microsoft.Management.Infrastructure.CimSession] $CimSession,
        [switch] $PrimaryOS = $false,
        [switch] $RunningOS = $false,
        [switch] $Clear = $false)

    Process {
        $ErrorActionPreference = "Stop"

        if (-not $Clear) {
            if ($CimSession -eq $null) {
                $CimSession = New-CimSession
            }
            $os = Get-CimInstance -CimSession $CimSession Win32_OperatingSystem
            $osName = $os.Caption
        }

        if ($PrimaryOS -eq $false -and $RunningOS -eq $false) {
            $PrimaryOS = $true
            $RunningOS = $true
        }
        
        if ($PrimaryOS) { Set-IPMISystemInfoHelper -Parameter 3 $osName }
        if ($RunningOS) { Set-IPMISystemInfoHelper -Parameter 4 $osName }
    }
}

function Get-IPMISystemInfo {
    <#
    .Synopsis
        Retrieve the current System Information stored in the BMC
    .Description
        Retrieve the current System Information stored in the BMC
    .Example
        Get-IPMISystemInfo -CimSession $remoteSystem
    .Parameter CimSession
        Used to execute this cmdlet against a remote system.  See New-CimSession cmdlet on creating a CimSession.
        If not specified, cmdlet is executed against local machine.  Administrator rights required to execute IPMI commands.
    #>
    [CmdletBinding(DefaultParametersetName="CimSession")]
    Param (
        [Parameter(ParameterSetName="CimSession",Position=0)]
        [Microsoft.Management.Infrastructure.CimSession] $CimSession)

    Process {
        $ErrorActionPreference = "Stop"

        $system = New-Object System.Management.Automation.PSObject
        $system.PSObject.TypeNames[0] = "System.Management.Automation.PSCustomObject.IPMI_SystemInfo"

        Write-Debug "Get firmware version"
        $versionString = Get-IPMISystemInfoHelper -Parameter 1
        $system | Add-Member -MemberType NoteProperty -Name FirmwareVersion -Value $VersionString
        
        Write-Debug "Get system name"
        $systemName = Get-IPMISystemInfoHelper -Parameter 2
        $system | Add-Member -MemberType NoteProperty -Name SystemName -Value $systemName

        Write-Debug "Get primary OS"
        $primaryOS = Get-IPMISystemInfoHelper -Parameter 3
        $system | Add-Member -MemberType NoteProperty -Name PrimaryOS -Value $primaryOS

        Write-Debug "Get running OS"
        $runningOS = Get-IPMISystemInfoHelper -Parameter 4
        $system | Add-Member -MemberType NoteProperty -Name RunningOS -Value $runningOS
        $system
    }
}

function Get-IPMILANConfig {
    <#
    .Synopsis
        Retrieve the current LAN Configuration stored in the BMC
    .Description
        Retrieve the current LAN Configuration stored in the BMC
    .Example
        Get-IPMILANConfig -CimSession $remoteSystem
    .Parameter CimSession
        Used to execute this cmdlet against a remote system.  See New-CimSession cmdlet on creating a CimSession.
        If not specified, cmdlet is executed against local machine.  Administrator rights required to execute IPMI commands.
    #>
    [CmdletBinding(DefaultParametersetName="CimSession")]
    Param (
        [Parameter(ParameterSetName="CimSession",Position=0)]
        [Microsoft.Management.Infrastructure.CimSession] $CimSession)

    Process {
        $ErrorActionPreference = "Stop"

        #find channel for 802.3 LAN
        $LANChannel = 0
        $foundChannel = $false
        for (;$LANChannel -le $MaxChannel;$LANChannel++) {
            $out = Invoke-IPMIRequestResponse -CimSession $CimSession -Command $GetChannelInfoCmd -RequestData @($LANChannel)
            if ($out[2] -eq $8023LANMediumType) {
                $foundChannel = $true
                break;
            }
        }
        if (-not $foundChannel) {
            Write-Error "Could not locate channel for LAN info"
        }
        
        $lanConfig = New-Object System.Management.Automation.PSObject
        $lanConfig.PSObject.TypeNames[0] = "System.Management.Automation.PSCustomObject.IPMI_LANConfig"

        Write-Debug "Get ipv4address"
        $out = Invoke-IPMIRequestResponse -CimSession $CimSession -Command $GetLANInfoCmd -RequestData @($LANChannel,3,0,0)
        if ($out.Length -eq 6) {
            $ipv4address = "$($out[2]).$($out[3]).$($out[4]).$($out[5])"
        }
        $lanConfig | Add-Member -MemberType NoteProperty -Name IPv4Address -Value $ipv4address

        Write-Debug "Get subnet mask"
        $out = Invoke-IPMIRequestResponse -CimSession $CimSession -Command $GetLANInfoCmd -RequestData @($LANChannel,6,0,0)
        if ($out.Length -eq 6) {
            $subnetMask = "$($out[2]).$($out[3]).$($out[4]).$($out[5])"
        }
        $lanConfig | Add-Member -MemberType NoteProperty -Name SubnetMask -Value $subnetMask

        Write-Debug "Get mac address"
        $out = Invoke-IPMIRequestResponse -CimSession $CimSession -Command $GetLANInfoCmd -RequestData @($LANChannel,5,0,0)
        if ($out.Length -eq 8) {
            $MACaddress = "{0:x}:{1:x}:{2:x}:{3:x}:{4:x}:{5:x}" -f $out[2],$out[3],$out[4],$out[5],$out[6],$out[7]
        }
        $lanConfig | Add-Member -MemberType NoteProperty -Name MACAddress -Value $MACaddress


        $lanConfig
    }
}

Export-ModuleMember Get-IPMISystemInfo,Set-IPMIOSInfo,Get-IPMILANConfig