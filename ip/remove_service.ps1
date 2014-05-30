<#
.Version
    0.1
    Created script, formated it out.

.Synopsis
   Created by Adam Rabenstein on 5-29-2014.

  
.EXAMPLE
   remove_service

.Todo
    
#>
function write_log {
Param($toWrite)
    $log = $MyInvocation.ScriptName + ".log"
    $time = Get-Date -Format 'dd-MM-yy_HH:MM::ss'
    Add-Content -Value $time -Path $log
    Add-Content -Value $toWrite -Path $log
}

function remove_service {
Param($svcName)
    Stop-Service $svcName
    if ($?) { write_log "$svcName Service Stopped"
    } else {
        write_log "$svcName Service not running or bad permissions"
    }
    sc.exe delete $svcName
    if ($?) { write_log "$svcName Service Removed"
    } else {
        write_log "$svcName Service not installed or bad permissions"
    }
}
remove_service "This Service"