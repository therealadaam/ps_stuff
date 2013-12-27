<#
.Version
    0.1
    Created script, formated it out.

.Synopsis
   Created by Adam Rabenstein on 12-5-2013.
   Gathers a list of domain computers, it excludes all servers.
  
.EXAMPLE
   get_current_domain_computers

.Todo
    Switch for laptops or computers
#>

function get_current_domain_computers() {
    $computers = net view |% {if ($_ -match "^\\\\(\S+)"){$matches[1]}}    
    $wrks = $computers | Where-Object {$_ -like "*wrk*"}
    $laps = $computers | Where-Object {$_ -like "*lap*"}
    $computers = $wrks + $laps
    Write-error "Please use 'Get_AD_list.ps1' this script is dated" -ErrorAction Stop
    return $computers    
}
