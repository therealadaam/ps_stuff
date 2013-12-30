
function get_os_by_ad {

$category = "computer"

#allow a choice of domain
$domain = New-Object System.DirectoryServices.DirectoryEntry
$sercher = New-Object System.DirectoryServices.DirectorySearcher
$sercher.SearchRoot = $domain 
$sercher.Filter = ("(objectCategory=$category)")
$list = $sercher.FindAll()

#list properties that are wanted (mostly name I'd think...)
#$computerNames = $list.Properties.name

foreach ($l in $list) {
	new-object -name $pcs -typename psobject -property @{
		Name = $l.properties.name.tostring()
		OS = $l.properties.operatingsystem.tostring()
	}
}
}
