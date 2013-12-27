<#
Created by Adam Rabenstein

.Version
0.1 - inputs array and has simple list of users

.References

.Synopsis
Used to gather a list of all the online users.

.Todo
Make into a Cmdlet
Make the output pretty

.Example
get_online_users atcwrk33,atcwrk34

#>


function get_online_users {
Param(
[Parameter(Mandatory=$true)]
$computers
)

    foreach ($computer in $computers) {   
        try {
                #Setting the ea so it catches WMI errors
                $ErrorActionPreference = "stop"
                $usersOnline += Get-WmiObject -Class Win32_ComputerSystem -ComputerName $computer |select username,name                      
            }
        catch [System.UnauthorizedAccessException] {$unathorized += "$computer,"}
        catch [System.Exception] {$cantReach += "$computer,"}
        finally {$ErrorActionPreference = "continue"}      
       
    }    
    return "Unauthorized on :$unathorized`nCan't reach: $cantReach`n$usersOnline"
}
