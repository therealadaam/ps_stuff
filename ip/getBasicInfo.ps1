<#
Created by Adam Rabenstein

.Version
0.1 - 2-20-13

.References
http://msdn.microsoft.com/en-us/library/windows/desktop/aa394586(v=vs.85).aspx
http://blogs.technet.com/b/heyscriptingguy/archive/2009/02/09/how-can-i-list-all-group-policy-objects-in-a-domain.aspx
http://blogs.technet.com/b/heyscriptingguy/archive/2009/02/12/how-can-i-generate-a-list-of-my-group-policy-objects.aspx
http://social.technet.microsoft.com/Forums/en-US/winserverpowershell/thread/de1431b6-190c-4779-8b44-b2c33b22fc15/


Group Policy info for 2k8 and win7:
http://technet.microsoft.com/en-us/library/ee461027.aspx


.Synopsis
Gather the following information:
User Name
Mail Address -Email or Physical?
Profile Path
User Drive
Group Memberships
Mailbox Size

.Todo
Make into a cmdlet.
Add support for legacy AD usage.
get-


Create a list of IP's and hostnames... determine the Domain Controllers and role holders, 
look for devices and their information with port 9100 open, 
save the group policy reports for later analysis,
perhaps dump 'just' ther 'ERROR' items from the event logs on all machines identified as role holders 
enumerate file shares
grab shares, hardware details, and errors from all machines enumerated in the domain if possible.

.Example
getInfo

#>
#source functions that are used
. .\Ps\functions\get_online_users.ps1
. .\Ps\functions\get_AD_list.ps1

#Set vars as needed
$username = $env:USERNAME
$domain = $env:USERDOMAIN
$computer = $env:COMPUTERNAME


#Computer specific mapped drives, can add a -cn option to put into a foreach loop
$mappedDrives = Get-WmiObject -Class win32_mappedlogicaldisk | 
select Name,ProviderName

#this is AD/LDAP usernames, all of them - can select only localaccounts with a where clause
$usernames = Get-WmiObject -Class win32_account | 
Select Caption,Name,Description,SIDtype

#Get user profiles for the current computer. 
#Can be expanded to function that inputs list of computers.
$userProfile = Get-WmiObject -Class win32_userprofile |
Select LocalPath,RoamingPath

#Get the event logs for computer, from there we can copy or back them up, or clear them.
$logs = Get-WmiObject -Class win32_nteventlogfile -ComputerName $computer

#Can get EVERY event from the computer(s)
$events = Get-WmiObject -Class win32_ntlogevent -ComputerName $computer

#another way of gathering the actual events, can filter, sort, order, do a lot more powerful stuff.
Get-EventLog -LogName $logToGet -ComputerName $computer

#http://www.petri.co.il/getting-mailbox-sizes-in-powershell.htm
#Needs to have Exchange connection to server
Get-MailboxStatistics | 
where {$_.ObjectClass –eq “Mailbox”} | 
Sort-Object TotalItemSize –Descending | 
ft @{label=”User”;expression={$_.DisplayName}},
@{label=”Total Size (MB)”;expression={$_.TotalItemSize.Value.ToMB()}},
@{label=”Items”;expression={$_.ItemCount}},
@{label=”Storage Limit”;expression={$_.StorageLimitStatus}} -auto


#Finding the printers/Default printer etc
#http://msdn.microsoft.com/en-us/library/windows/desktop/aa394363(v=vs.85).aspx
$printers = Get-WmiObject -Class win32_printer -ComputerName $computer
$printerDefault = $printers | Where {$_.Default -eq $true}