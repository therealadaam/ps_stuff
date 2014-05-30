<#
.Version
    0.1
    Created script, formated it out.

.Synopsis
   Created by Adam Rabenstein on 5-30-2014.
   http://pastebin.com/ud3cQ2xz
  
.EXAMPLE
   reset_failed_vss_writers

.Todo
    
#>
function write_log {
Param($toWrite)
    $log = $MyInvocation.ScriptName + ".log"
    $time = Get-Date -Format 'dd-MM-yy_HH:MM::ss'
    Add-Content -Value $time -Path $log
    Add-Content -Value $toWrite -Path $log
}

$ServiceArray = @{
    'ASR Writer' = 'VSS';
    'Bits Writer' = 'BITS';
    'Certificate Authority' = 'EventSystem';
    'COM+ REGDB Writer' = 'VSS';
    'DFS Replication service writer' = 'DFSR';
    'Dhcp Jet Writer' = 'DHCPServer';
    'FRS Writer' = 'NtFrs'
    'IIS Config Writer' = 'AppHostSvc';
    'IIS Metabase Writer' = 'IISADMIN';
    'Microsoft Exchange Writer' = 'MSExchangeIS';
    'Microsoft Hyper-V VSS Writer' = 'vmms';
    'MS Search Service Writer' = 'EventSystem';
    'NPS VSS Writer' = 'EventSystem';
    'NTDS' = 'EventSystem';
    'OSearch VSS Writer' = 'OSearch';
    'OSearch14 VSS Writer' = 'OSearch14';
    'Registry Writer' = 'VSS';
    'Shadow Copy Optimization Writer' = 'VSS';
    'Sharepoint Services Writer' = 'SPWriter';
    'SPSearch VSS Writer' = 'SPSearch';
    'SPSearch4 VSS Writer' = 'SPSearch4';
    'SqlServerWriter' = 'SQLWriter';
    'System Writer' = 'CryptSvc';
    'WMI Writer' = 'Winmgmt';
    'TermServLicensing' = 'TermServLicensing';
 }

vssadmin list writers | Select-String -Context 0,4 'Writer name:' | 
Where-Object {$_.Context.PostContext[3].Trim() -ne "Last error: No error"} | 
Select Line | ForEach-Object {$_.Line.tostring().Split("'")[1]} | 
ForEach-Object {
    $temp = $_
    $servicearray |
    ForEach-Object {
        if($_.Name -like $temp){Restart-Service $_.Value -force}
    }
}