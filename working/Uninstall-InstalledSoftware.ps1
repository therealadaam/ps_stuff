[cmdletbinding()]            

param (            

 [parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
 [string]$ComputerName = $env:computername,
 [parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
 [string]$AppGUID
)            

 try {
  $returnval = ([WMICLASS]"\\$computerName\ROOT\CIMV2:win32_process").Create("msiexec `/x$AppGUID `/norestart `/qn")
 } catch {
  write-error "Failed to trigger the uninstallation. Review the error message"
  $_
  exit
 }
 switch ($($returnval.returnvalue)){
  0 { "Uninstallation command triggered successfully" }
  2 { "You don't have sufficient permissions to trigger the command on $Computer" }
  3 { "You don't have sufficient permissions to trigger the command on $Computer" }
  8 { "An unknown error has occurred" }
  9 { "Path Not Found" }
  9 { "Invalid Parameter"}
 }