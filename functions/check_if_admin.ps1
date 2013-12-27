<#
.Version
0.1

.Synopsis
   Created by Adam Rabenstein
   Checks if the current session is being run by an Administrator on the localmachine.
   This is more of a supporting function than anything to be used on it's own. Very helpful
   in other scripts. Returns true if admin, false if not.
.EXAMPLE
   check_if_admin

.Todo
    Would be good to check for domain admin as well...
#>
function check_if_admin
{
    $admins = net localgroup administrators
    if ($admins.Contains("$env:userdomain\$env:USERNAME") ) {
        return $true
    } elseif ($admins.Contains("$env:username")) {
        return $true
    } else {
        return $false
    }
  
}