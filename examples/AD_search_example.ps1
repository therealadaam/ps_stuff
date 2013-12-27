#Example of how to do directory searches of AD.

$strFilter = "(Name=lyle*)" # Can also use (& (attrib=thing)(attrib2=thing))

$objDomain = New-Object System.DirectoryServices.DirectoryEntry
#$objOU = New-Object System.DirectoryServices.DirectoryEntry("LDAP://OU=Finance,dc=fabrikam,dc=com")

$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
$objSearcher.SearchRoot = $objDomain #Needs to be a DirectoryEntry object!
$objSearcher.PageSize = 1000
$objSearcher.Filter = $strFilter
$objSearcher.SearchScope = "Subtree" #Subtree (goes through everything), Base (only that area), OneLevel (go down one level)

$colProplist = "name"
foreach ($i in $colPropList){$objSearcher.PropertiesToLoad.Add($i)}

$colResults = $objSearcher.FindAll()

foreach ($objResult in $colResults)
    {$objItem = $objResult.Properties; $objItem.name}