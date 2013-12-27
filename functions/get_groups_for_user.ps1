<#
Created by Adam Rabenstein

.Version
0.1

.References
http://msdn.microsoft.com/en-us/library/windows/desktop/aa394084(v=vs.85).aspx

.Synopsis
Input username, get list of groups user is in, along with username.

.Todo
Expand and allow string[] input
Make output a bit 'prettier'

.Example
get_groups_for_user arabenstein

#>

function get_groups_for_user {
Param(
[Parameter(Mandatory=$true)]
$username
)
$groups = Get-WmiObject -Class win32_groupuser | 
where PartComponent -Match $username |
#might need to remove this section for speed of script running...change to non-slow one
select @{name="group";expression={$_.GroupComponent}}, @{name="user";expression={$_.PartComponent}}

for ($i=0;$i -lt $groups.Count;$i++) {    
    [String]$user = $groups[$i].user.Split(',')[1].split('=')[1].replace('"','')
    [String]$group = $groups[$i].group.Split(',')[1].split('=')[1].replace('"','')
    [String[]]$list += "$user $group"
}


return $list

}