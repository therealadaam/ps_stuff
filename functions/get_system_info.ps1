<#
.Synopsis
   Created by Adam Rabenstein on 12-24-2013.   

.References
http://4sysops.com/archives/remotely-query-user-profile-information-with-powershell/
  
.EXAMPLE
get_system_info $computers

.Todo
    
#>

function printers {
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

function profiles {
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

function drives {
Param(
        [Parameter(Mandatory=$true, 
                    ValueFromPipeline=$false,                    
                    Position=0)]        
	    $ary
    )
    
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
        
        #Get all the WMI data at once. This will probably take awhile.
        $system = gwmi win32_computersystem -ComputerName $c
        $processor = gwmi win32_processor -ComputerName $c
        $osinfo = gwmi win32_operatingsystem -ComputerName $c
        $printers = Get-WmiObject -Class win32_printer -ComputerName $c
        $profiles = Get-WmiObject -Class win32_userprofile -ComputerName $c
        $drives = Get-WmiObject -Class win32_mappedlogicaldisk -ComputerName $c

        #call functions
        $printerRes = printers($printers)
        $profileRes = profiles($profiles)

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
        $results += $genInfo
    }
    return $results
}