<#
.Version
    0.1
    Created script, formated it out.

.Synopsis
   Created by Adam Rabenstein on 5-5-2014.

  
.EXAMPLE
   reset_failed_vss_writers

.Todo
    
#>

$writerStates = vssadmin list writers

if (($failedName -eq "ASR Writer") -or 
    ($failedName -eq "COM+ REGDB Writer") -or
    ($failedName -eq "Registry Writer") -or 
    ($failedName -eq "Shadow Copy Optimization Writer")
    ) {Restart-Service vss}