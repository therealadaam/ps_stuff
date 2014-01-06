﻿<#
.Synopsis
   Created by Adam Rabenstein on 1-6-2014.   
  
.EXAMPLE
   

.Todo
    
#>

#source stuff
. .\functions\get_AD_list.ps1
. .\functions\get_system_info.ps1

#dump AD to csv files
get_ad_list -type computer -file csv
get_ad_list -type user -file csv
get_ad_list -type group -file csv

$computersAD = search_ad("computer")
$computers = $computersAD.properties.name

get_system_info -computers $computers