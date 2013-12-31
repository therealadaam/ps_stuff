<#
.Version
    0.1
    Created script, formated it out.

.Synopsis
   Created by Adam Rabenstein on 12-24-2013.   
  
.EXAMPLE
   get_system_info $computers

.Todo
    
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

        $view = New-Object PsObject -Property @{ #new object to itorate through and allow easier formatting, etc
        SystemName = [String]$system.Name
        SystemModel = [String]$system.Model
        SysUser = [String]$system.UserName
        ProcModel = [String]$processor.Caption
        ProcType = [String]$processor.name
        ProcCores = [String]$processor.NumberOfCores
        Ram = [String]"{0:N2}" -f ($system.TotalPhysicalMemory/1GB) #This is some good magic. The "{0:N2}" gives us a number to 2 decimal places.
        OsName = [String]$osinfo.Caption
        OsServicePack = [String]$osinfo.CSDVersion
        OsArch = [String]$osinfo.OSArchitecture
        }
        $results += $view
    }
    return $results
}