# Fix-Perms
# Iterates over all child directories, and adds the user, with the same name as the directory, to the ACL with modify rights
# Usage:
# Fix-Perms “C:\Path\To\Directory”
# Or, for the current directory
# Fix-Perms “.”

# our parameters, throw a warning if we get none
param (
[string] $dirpath = $(throw “Please specify the full path to the directory!”)
)

# get list of all child directories, in the current directory
$directories = dir $dirpath | where {$_.PsIsContainer}

# iterate over the directories
foreach ($dir in $directories)
{
# echo out what the full directory is that we’re working on now
write-host Working on $dir.fullname using $dir.name

# setup the inheritance and propagation as we want it
$inheritance = [system.security.accesscontrol.InheritanceFlags]“ContainerInherit, ObjectInherit”
$propagation = [system.security.accesscontrol.PropagationFlags]“None”

# get the existing ACLs for the directory
$acl = get-acl $dir.fullname

# add our user (with the same name as the directory) to have modify perms
$aclrule = new-object System.Security.AccessControl.FileSystemAccessRule($dir.name, “FullControl”, $inheritance, $propagation, “Allow”)

# check if given user is Valid, this will barf if not
$sid = $aclrule.IdentityReference.Translate([System.Security.Principal.securityidentifier])

# add the ACL to the ACL rules
$acl.AddAccessRule($aclrule)

# set the acls
set-acl -aclobject $acl -path $dir.fullname
}

