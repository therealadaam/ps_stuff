<#
.Version
    0.1
    Created script, formated it out.

.Synopsis
   Created by Adam Rabenstein on 5-29-2014.

  
.EXAMPLE
   standard_cleanup_script

.Todo
    Lots
#>
Param([switch]$runWinUtil)

#region Imported Functions
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
#endregion

#remove stupid agents Centennial
if (Test-Path $env:SystemDrive\Centenn.ial) {
    write_log "Removing Centennial agents, services, and folders"    
    #RM services
    remove_service "CentennialIPTransferAgent"
    remove_service "CentennialClientAgent"
    
    Remove-Item $env:SystemDrive\centenn.ial -Recurse -Force
    if ($?) {write_log "Centennial Folder Removed"
    } else {
    write_log "Centennial Folder not Removed"
    }
}

#Acrobat update service removal
remove_service "adobearmservice"
remove_service "Bonjour Service"
remove_service "LightScribeService"
#LiveScribe
remove_service "PenCommService"
#Windows Live ID
remove_service "wlidsvc"

#remove stuff from the windows temp folder.
$WinTemp = "c:\Windows\Temp\*"
Remove-Item -Recurse $WinTemp -Force
if ($?) {write_log "windows temp cleared"
    } else {
    write_log "windows temp not cleared"
    }
#remove from user temp folder
Remove-Item -Recurse "$env:TEMP\*" -Force
if ($?) {write_log "user temp cleared"
    } else {
    write_log "user temp not cleared"
    }

#remove recycle bin items
$objShell = New-Object -ComObject Shell.Application
$objFolder = $objShell.Namespace(0xA)
$objFolder.items() | %{ remove-item $_.path -Recurse -Confirm:$false}
if ($?) {write_log "recycle bin cleared"
    } else {
    write_log "recycle bin not cleared"
    }

#if set run the windows cleanup utility
if ($runWinUtil) {cleanmgr /sagerun:1 | out-Null}