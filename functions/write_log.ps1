<#
.Synopsis
   Created by Adam Rabenstein on 1-6-2014.
   Writes output to a log with the scriptname.
  
.EXAMPLE
   write_log "Stuff to write"
#>

function write_log {
Param($toWrite)
    $log = $MyInvocation.ScriptName + ".log"
    $time = Get-Date -Format 'dd-MM-yy_HH:MM::ss'
    Add-Content -Value $time -Path $log
    Add-Content -Value $toWrite -Path $log
}
write_log "Testing"