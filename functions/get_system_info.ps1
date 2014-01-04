<#
.Synopsis
   Created by Adam Rabenstein on 12-24-2013.   

.References
http://4sysops.com/archives/remotely-query-user-profile-information-with-powershell/
  
.EXAMPLE
get_system_info $computers

.Todo
    
#>

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
    return $obj
}
$printers = Get-WmiObject -Class win32_printer
#$printerRes = user_printers($printers)

function user_printers_old {
Param(
        [Parameter(Mandatory=$true, 
                    ValueFromPipeline=$false,                    
                    Position=0)]        
	    $ary
    )
    $res = @()
    foreach ($i in $ary) {
        $temp = New-Object psobject -Property @{
            PrinterName = [String]$i.name
            PrinterPort = [String]$i.PortName
            PrinterShareName = [String]$i.ShareName
            PrinterServer = [String]$i.ServerName
            PrinterLocal = [String]$i.Local
        }
        $res += $temp
    }
    return $res
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
        }
        catch {
            $tmpUsr = New-Object psobject -Property @{Value=""}
            $tmpUsr.Value = [String]$i.sid
        }

        #ProfileTime Conversion
        $lut = ([WMI]"").Converttodatetime($i.lastusetime)
        [String]$lut = $lut |Get-Date -Format 'MM-dd-yyyy'

        switch ($i.Status) {
            1 {$status = [string]"Temporary"}
            2 {$status = [string]"Roaming"}
            4 {$status = [string]"Mandatory"}
            8 {$status = [string]"Corrupted Local Profile"}
            12 {$status = [string]"Corrupted Roaming Profile"}
            Default {$status = [string]"Local"}
        }
           
        $obj | Add-Member -Name "Profile_$($num)_SID" -Value "$($i.SID)" -MemberType NoteProperty
        $obj | Add-Member -Name "Profile_$($num)_Status" -Value "$($status)" -MemberType NoteProperty
        $obj | Add-Member -Name "Profile_$($num)_LocalPath" -Value "$($i.LocalPath)" -MemberType NoteProperty
        $obj | Add-Member -Name "Profile_$($num)_RoamingPath" -Value "$($i.RoamingPath)" -MemberType NoteProperty
        $obj | Add-Member -Name "Profile_$($num)_LastUse" -Value "$($lut)" -MemberType NoteProperty
        $obj | Add-Member -Name "Profile_$($num)_UserName" -Value "$($tmpUsr.Value)" -MemberType NoteProperty

        

        $num++
    }
    <# Old stuff
    $temp = New-Object psobject -Property @{
            ProfileSID = [String]$i.SID
            ProfileStatus = $i.Status
            ProfileLocalPath = [String]$i.LocalPath
            ProfileRamingPath = [String]$i.RoamingPath
            ProfileLastUse = [String]$lut
            ProfileUsername = [String]$tmpUsr.Value
        } 
    #>


    #Switch for ProfileStatus
    

    return $obj
}

function user_profiles_old {
Param(
        [Parameter(Mandatory=$true, 
                    ValueFromPipeline=$false,                    
                    Position=0)]        
	    $ary
    )
    $res = @()
    foreach ($i in $ary) {
        if ($i.special) { continue } #Skip special accounts, networkservice,etc.
        
        #translate SID to username
        try {
            $tmpSID = New-Object System.Security.Principal.SecurityIdentifier($i.sid)
            $tmpUsr = $tmpSID.Translate([System.Security.Principal.NTAccount])
        }
        catch {
            $tmpUsr = New-Object psobject -Property @{Value=""}
            $tmpUsr.Value = [String]$i.sid
        }

        #ProfileTime Conversion
        $lut = ([WMI]"").Converttodatetime($i.lastusetime)
        [String]$lut = $lut |Get-Date -Format 'MM-dd-yyyy'
        

        $temp = New-Object psobject -Property @{
            ProfileSID = [String]$i.SID
            ProfileStatus = $i.Status
            ProfileLocalPath = [String]$i.LocalPath
            ProfileRamingPath = [String]$i.RoamingPath
            ProfileLastUse = [String]$lut
            ProfileUsername = [String]$tmpUsr.Value
        }        
        #Switch for ProfileStatus
        switch ($temp.ProfileStatus) {
            1 {$temp.ProfileStatus = [string]"Temporary"}
            2 {$temp.ProfileStatus = [string]"Roaming"}
            4 {$temp.ProfileStatus = [string]"Mandatory"}
            8 {$temp.ProfileStatus = [string]"Corrupted Local Profile"}
            12 {$temp.ProfileStatus = [string]"Corrupted Roaming Profile"}
            Default {$temp.ProfileStatus = [string]"Local"}
        }
        $res += $temp
    }
    return $res
}

function user_drives {
Param(
        [Parameter(Mandatory=$true, 
                    ValueFromPipeline=$false,                    
                    Position=0)]        
	    $ary
    )
    $res = @()
    foreach ($i in $ary) {
        $temp = New-Object psobject -Property @{
            DriveName = [String]$i.name
            DriveFree = [String]"{0:N2} GB" -f ($i.freespace/1GB)
            DriveTotal = [String]"{0:N2} GB" -f ($i.size/1GB)
            DriveProvider = [String]$i.providername
            DriveType = $i.drivetype
        }
        switch ($temp.drivetype) {
            1 {$temp.drivetype = [string]"No Root Dir"}
            2 {$temp.drivetype = [string]"Removable Disk"}
            3 {$temp.drivetype = [string]"Logical Disk"}
            4 {$temp.drivetype = [string]"Network Drive"}
            5 {$temp.drivetype = [string]"CD drive"}
            6 {$temp.drivetype = [string]"RAM disk"}
            Default {$temp.drivetype = [string]"Unknown Type"}
        }

        $res += $temp
    }
    return $res
}

function computer_network {
Param(
        [Parameter(Mandatory=$true, 
                    ValueFromPipeline=$false,                    
                    Position=0)]        
	    $ary
    )
    
    foreach ($i in $ary) {
        $temp = New-Object psobject -Property @{
            DHCP = [String]$i.dhcpenabled
            NIC_Mac = [String]$i.MACAddress
            Ip_addr_4 = [String[]]$i.ipaddress
            Ip_addr_6 = [String]""
            Gateway = [String]$i.DefaultIpGateway
            DNS_server = [String]$i.DNSServerSearchOrder[0]
            DNS_server2 = [String]$i.DNSServerSearchOrder[1]
        }
        #if there is more than 1 IP address do stuff
        if ($temp.Ip_addr_4.length -gt 1) {
            $temp.Ip_addr_6 = [String]$temp.Ip_addr_4[1]
            $temp.Ip_addr_4 = [String]$temp.Ip_addr_4[0]
        } else {
            $temp.Ip_addr_4 = [String]$temp.Ip_addr_4
        }        

        $res += $temp
    }
    return $res
}

function get_system_info {
Param(
        [Parameter(Mandatory=$false, 
                    ValueFromPipeline=$false,                    
                    Position=0,
                    ParameterSetName='Computers')]        
	    [String[]]$computers = "Localhost" #cast this as a string array and fill by default
    )
    $results = @() #initalize array for results

    foreach ($c in $computers) {
        Write-Progress -Activity "Getting data" -Status "Working on $c" -PercentComplete ( ($c.Count/$computers.Length) * 100)
        #Get all the WMI data at once. This will probably take awhile.
        #easy stuff
        $system = gwmi win32_computersystem -ComputerName $c
        $processor = gwmi win32_processor -ComputerName $c
        $osinfo = gwmi win32_operatingsystem -ComputerName $c

        #Not as easy
        $printers = Get-WmiObject -Class win32_printer -ComputerName $c
        $profiles = Get-WmiObject -Class win32_userprofile -ComputerName $c
        $drives = Get-WmiObject -Class win32_logicaldisk -ComputerName $c
        $network = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ComputerName $c |`
            where{$_.IPEnabled -eq "True"}

        #call functions
        #$printerRes = user_printers($printers)
        #$profileRes = user_profiles($profiles)
        $drivesRes = user_drives($drives)
        $networkRes = computer_network($network)

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

        user_printers -ary $printers -obj $genInfo
        user_profiles -ary $profiles -obj $genInfo
        #the replacement:


        #glob everything into a big array
        #$results += $genInfo  
        <#      
        $results +=$drivesRes
        $results += $profileRes
        $results += $printerRes
        $results += $networkRes
        #>
        
        $domain = $env:USERDOMAIN
        $date = Get-Date -Format "MM-dd-yy_hhmm"
        #append to the csvFile
        $genInfo | Export-Csv "$($domain)_$($date).csv" -NoTypeInformation -Append
    }
    
    return $results
}