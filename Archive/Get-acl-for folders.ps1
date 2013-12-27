<#
.Version
0.1 - Adam Rabenstein
.Synopsis
   A command that will get the acls for a list of folders 
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get_all_acls
{
   Param
    (
        # A list of folders
        [Parameter(Mandatory=$true,                
                   Position=0)]
        $folders,

        # Param2 help description
        [switch]
        $Recursive,

        #
        [switch]
        $Directory
    )   
$folders = dir D:\ -Recurse -Directory #if you want to just do directories put this
foreach ($folder in $folders) { ## for each is a programming thing, basically it makes an array that is $folders, for each item in the array
                                        # it does the following:
    Get-Acl -Path $folder.FullName #You need the .fullname property or it won't show up correctly, it doesn't pipe as expected.
    }
}