<#
.Version
    0.1
    Created script, formated it out.

.Synopsis
   Created by Adam Rabenstein on 12-5-2013.
   Test-connections for the computers given.
  
.EXAMPLE
   test_if_cps_online

.Todo
    
#>
function test_if_cps_online ($pcList) {
    foreach ($pc in $pcList) {
    Test-Connection $pc -Count 2
    }
}