<#
.Version
0.1
Created script, formated it out.
0.2
Added basics for system, processor, os.
0.3

.Synopsis
   Created by Adam Rabenstein on 12-24-2013.   
  
.EXAMPLE
   get_system_info $computers

.Todo
make an itoration function that itorates through an array and then i'd have to combine things later.
    
#>

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
    
        $system = gwmi win32_computersystem -ComputerName $c #get system from wmi
        $processor = gwmi win32_processor -ComputerName $c #get processor from wmi
        $osinfo = gwmi win32_operatingsystem -ComputerName $c #os from wmi
        $printers = Get-WmiObject -Class win32_printer -ComputerName $c
        $profiles = Get-WmiObject -Class win32_userprofile -ComputerName $c
        $drives = Get-WmiObject -Class win32_mappedlogicaldisk -ComputerName $c

        $view = New-Object PsObject -Property @{ #new object to itorate through and allow easier formatting, etc
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
            #PrinterPort = [String]$printers.PortName
            #PrinterShareName = [String]$printers.ShareName
            #PrinterServer = [String]$printers.ServerName
            #PrinterLocal = [String]$printers.Local
            
        }
        $results += $view
    }
    return $results
}