<#
.Synopsis
   Created by Adam Rabenstein on 12-24-2013.   

.References
http://4sysops.com/archives/remotely-query-user-profile-information-with-powershell/
http://www.pcreview.co.uk/forums/purpose-state-key-located-users-profiles-t2939114.html
  
.EXAMPLE
get_system_info $computers

.Todo
    
#>
if ($PSVersionTable.PSVersion.Major -lt 3) { #check PS version and import csv_function if needed
    . .\export_csv_append_PSV2.ps1
}

function write_log {
Param($toWrite)
    $log = $MyInvocation.ScriptName + ".log"
    $time = Get-Date -Format 'dd-MM-yy_HH:MM::ss'
    Add-Content -Value $time -Path $log
    Add-Content -Value $toWrite -Path $log
}

function user_printers {
Param(
        $ary,
        $obj
    )
    $num = 0
    foreach ($i in $ary) {       
        $obj | Add-Member -Name "Printer_$($num)_Name" -Value "$($i.name)" -MemberType NoteProperty
        $obj | Add-Member -Name "Printer_$($num)_ShareName" -Value "$($i.ShareName)" -MemberType NoteProperty
        $obj | Add-Member -Name "Printer_$($num)_Server" -Value "$($i.ServerName)" -MemberType NoteProperty
        $obj | Add-Member -Name "Printer_$($num)_Local" -Value "$($i.PortName)" -MemberType NoteProperty
        $obj | Add-Member -Name "Printer_$($num)_Port" -Value "$($i.PortName)" -MemberType NoteProperty
        $num++
    }
}

function user_profiles {
Param(
        $ary,
        $obj
    )
    #main part
    $num = 0
    foreach ($i in $ary) {
        if ($i.special) { continue } #Skip special accounts, networkservice,etc.
        
        #translate SID to username
        try {
            $tmpSID = New-Object System.Security.Principal.SecurityIdentifier($i.sid)
            $tmpUsr = $tmpSID.Translate([System.Security.Principal.NTAccount])
        } catch {
            $tmpUsr = "LookupFailed"
        }
        try {
            #ProfileTime Conversion
            $lut = ([WMI]"").Converttodatetime($i.lastusetime)
            [String]$lut = $lut |Get-Date -Format 'MM-dd-yyyy'
        } catch {
            $lut = [String]"Unknown"
        }

        switch ($i.Status) {
            1 {$status = [string]"Temporary"}
            2 {$status = [string]"Roaming"}
            4 {$status = [string]"Mandatory"}
            8 {$status = [string]"Corrupted Local Profile"}
            12 {$status = [string]"Corrupted Roaming Profile"}
            Default {$status = [string]"Unknown"}
        }
           
        $obj | Add-Member -Name "Profile_$($num)_SID" -Value "$($i.SID)" -MemberType NoteProperty
        $obj | Add-Member -Name "Profile_$($num)_Status" -Value "$($status)" -MemberType NoteProperty
        $obj | Add-Member -Name "Profile_$($num)_LocalPath" -Value "$($i.LocalPath)" -MemberType NoteProperty
        $obj | Add-Member -Name "Profile_$($num)_RoamingPath" -Value "$($i.RoamingPath)" -MemberType NoteProperty
        $obj | Add-Member -Name "Profile_$($num)_LastUse" -Value "$($lut)" -MemberType NoteProperty
        $obj | Add-Member -Name "Profile_$($num)_UserName" -Value "$($tmpUsr.Value)" -MemberType NoteProperty
        $num++
    }
}

function user_drives {
Param(     
	    $ary,
        $obj
    )
    $num = 0
    foreach ($i in $ary) {
        $dFree = [String]"{0:N2} GB" -f ($i.freespace/1GB)
        $dTotal = [String]"{0:N2} GB" -f ($i.size/1GB)
        switch ($i.drivetype) {
            1 {$dType = [string]"No Root Dir"}
            2 {$dType = [string]"Removable Disk"}
            3 {$dType = [string]"Logical Disk"}
            4 {$dType = [string]"Network Drive"}
            5 {$dType = [string]"CD drive"}
            6 {$dType = [string]"RAM disk"}
            Default {$dType = [string]"Unknown Type"}        
        } 
        $obj | Add-Member -Name "Drive_$($num)_Name" -Value "$($i.name)" -MemberType NoteProperty
        $obj | Add-Member -Name "Drive_$($num)_FreeSpace" -Value "$($dFree)" -MemberType NoteProperty
        $obj | Add-Member -Name "Drive_$($num)_TotalSpace" -Value "$($dTotal)" -MemberType NoteProperty
        $obj | Add-Member -Name "Drive_$($num)_Provider" -Value "$($i.providername)" -MemberType NoteProperty
        $obj | Add-Member -Name "Drive_$($num)_Type" -Value "$($dType)" -MemberType NoteProperty
        $num++
    }
}

function computer_network {
Param(       
	    $ary,
        $obj
    )
    $numb = 0
    foreach ($i in $ary) {        
        #if there is more than 1 IP address do stuff
        if ($i.Ipaddress.length -gt 1) {
            $Ip_addr_6 = [String]$i.Ipaddress[1]
            $Ip_addr_4 = [String]$i.Ipaddress[0]
        } else {
            $Ip_addr_4 = [String]$i.Ipaddress
        }        
        $obj | Add-Member -Name "NIC_$($num)_Dhcp" -Value "$($i.dhcpenabled)" -MemberType NoteProperty
        $obj | Add-Member -Name "NIC_$($num)_MAC_addr" -Value "$($i.MACAddress)" -MemberType NoteProperty
        $obj | Add-Member -Name "NIC_$($num)_Ip_addr_4" -Value "$($Ip_addr_4)" -MemberType NoteProperty
        $obj | Add-Member -Name "NIC_$($num)_Ip_addr_6" -Value "$($Ip_addr_6)" -MemberType NoteProperty
        $obj | Add-Member -Name "NIC_$($num)_Gateway" -Value "$($i.DefaultIpGateway)" -MemberType NoteProperty
        $obj | Add-Member -Name "NIC_$($num)_DNS_server_1" -Value "$($i.DNSServerSearchOrder[0])" -MemberType NoteProperty
        $obj | Add-Member -Name "NIC_$($num)_DNS_server_2" -Value "$($i.DNSServerSearchOrder[1])" -MemberType NoteProperty
        $num++
    }    
}

function user_profiles_from_reg {
Param($computer)    

    $objAry = @() #array for results
    $remoteHive = [Microsoft.Win32.RegistryHive]"LocalMachine"
    $regKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($remoteHive,$computer)
    $profileList = $regKey.OpenSubKey(“SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\”,$true)
    $remoteProfiles = $profileList.GetSubKeyNames()  
    foreach ($p in $remoteProfiles) {
         $thisProfile = $regKey.OpenSubKey(“SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$p”,$true)
         $special = $thisProfile.Name.Split('\')[-1].Length -lt 45 #make special for systemaccounts
         $thisObj = New-Object psobject -Property @{
            SID = $thisProfile.name.Split('\')[-1] #Get the last part of the name as the SID.
            LocalPath = $thisProfile.GetValue('ProfileImagePath')
            RoamingPath = $thisProfile.GetValue('CentralProfile')
            Special = $special
            LastUseTime = "N/A for xp/2k3"
            Status = "N/A for xp/2k3"
         }    
    $objAry += $thisObj
    }
    return $objAry
    <#ToDo: Get info for the status
001 = PROFILE_MANDATORY
Profile is mandatory.

002 = PROFILE_USE_CACHE
Update locally Cached profile.

004 = PROFILE_NEW_LOCAL
Using a new local profile.

008 = PROFILE_NEW_CENTRAL
Using a new central profile.

010 = PROFILE_UPDATE_CENTRAL
Need to update central profile.

020 = PROFILE_DELETE_CACHE
Need to delete cached profile.

040 = PROFILE_UPGRADE
Need to upgrade profile.

080 = PROFILE_GUEST_USER
Using guest user profile.

100 = PROFILE_ADMIN_USER
Using administrator profile.

200 = DEFAULT_NET_READY
Default net profile is available & ready.

400 = PROFILE_SLOW_LINK
Identified slow network link.

800 = PROFILE_TEMP_ASSIGNED
Temporary profile loaded.
#>
}

function get_system_info {
Param(
        [Parameter(Mandatory=$false, 
                    ValueFromPipeline=$false,                    
                    Position=0)]        
	    [String[]]$computers = $env:COMPUTERNAME #cast this as a string array and fill by default
    )
    $domain = $env:USERDOMAIN
    $date = Get-Date -Format "MM-dd-yy_hhmm"
    foreach ($c in $computers) {
        Write-Progress -Activity "Getting data" -Status "Working on $c" -PercentComplete ( ($c.Count/$computers.Length) * 100)
        $online = Test-Connection -ComputerName $c -Count 2 -Quiet
        if ($online) {
            
            #Get all the WMI data at once. This will probably take awhile.
            #easy stuff
            $system = gwmi win32_computersystem -ComputerName $c -ErrorAction Stop -ErrorVariable +wmiError
            $processor = gwmi win32_processor -ComputerName $c -ErrorAction Stop -ErrorVariable +wmiError
            $osinfo = gwmi win32_operatingsystem -ComputerName $c -ErrorAction Stop -ErrorVariable +wmiError

            #Not as easy
            $printers = Get-WmiObject -Class win32_printer -ComputerName $c -ErrorAction Stop -ErrorVariable +wmiError
            
            if ($osinfo.Version[0] -ne '6') {
                #call if 2k3 or xp
                $profiles = user_profiles_from_reg -computer $c
                #write_log " No profile info for $c 2k3 and XP is not yet supported."
                #$profiles = [string[]]""
            } else {
                $profiles = Get-WmiObject -Class win32_userprofile -ComputerName $c -ErrorAction Stop -ErrorVariable +wmiError
            }            

            $drives = Get-WmiObject -Class win32_logicaldisk -ComputerName $c -ErrorAction Stop -ErrorVariable +wmiError
            $network = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ComputerName $c -ErrorAction Stop `
                                                                                            -ErrorVariable +wmiError |
                                                                                        where{$_.IPEnabled -eq "True"}

            trap {
                write_log "Error accessing WMI on $c"
                write_log $wmiError
                $wmiError.Clear() #clear erros after writting them
                if ($system.name -ne $c) { continue } #skip pc if nothing basic WMI
            }

            $genInfo = New-Object PsObject -Property @{ #new object to Combine everything
                SystemName = [String]$system.Name
                SystemModel = [String]$system.Model
                SysUser = [String]$system.UserName
                ProcModel = [String]$processor.Caption
                ProcType = [String]$processor.name
                ProcCores = [String]$processor.NumberOfCores
                Ram = [String]"{0:N2}" -f ($system.TotalPhysicalMemory/1GB) #"{0:N2}" gives us a number to 2 decimal places.
                OsName = [String]$osinfo.Caption
                OsServicePack = [String]$osinfo.CSDVersion
                OsArch = [String]$osinfo.OSArchitecture            
            }
            #add information to the array
            user_printers -ary $printers -obj $genInfo
            user_profiles -ary $profiles -obj $genInfo
            user_drives -ary $drives -obj $genInfo
            computer_network -ary $network -obj $genInfo  
            
            #append to the csvFile
            $genInfo | Export-Csv "$($domain)_$($date).csv" -NoTypeInformation -Append
            write_log -toWrite "Computer: $c information added to csv file"
        } else {
            write_log -toWrite "Can't connect to $c"
        }
    }
}