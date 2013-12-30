<#
Created by Adam Rabenstein

.Version
0.1
Gets computers from local domain and returns them.
0.2
Gets types now with switches that returns the most 'needed' types of results.
0.3
Added validation and need to finish output feature/function.
0.4
Added Groups and PsObject for the groups, this broke csv and html output for groups.
0.5
Fixed the group output.
0.6
Made search_ad function and commented out stuff from get_ad_list function.
0.7
Created functions for gathering the properties, one function for each type.
0.8
Added PsObjects to the user and computer functions.
0.9
Made the user email addressses and groupMembers a big string for easier export.

.References
http://msdn.microsoft.com/en-us/library/system.directoryservices.directorysearcher.aspx
http://blogs.technet.com/b/heyscriptingguy/archive/2006/11/09/how-can-i-use-windows-powershell-to-get-a-list-of-all-my-computers.aspx


.Synopsis
Gets a list of all the computers/users/etc in the current domain and returns them.

.Todo


.Example
Source the function '. ./get_AD_list.ps1' Then:
get_ad_list -type user -file csv #This outputs a $date_user.csv file.
get_ad_list -type computer #This outputs an object with data

#>

#function to search Active Directory.
function search_ad {
Param(
        [Parameter(Mandatory=$true, 
                    ValueFromPipeline=$false,                    
                    Position=0)]     
        [ValidateSet("computer","user","group")]         
	    $category
    )
    #TODO - allow a choice of domain
    $domain = New-Object System.DirectoryServices.DirectoryEntry
    $sercher = New-Object System.DirectoryServices.DirectorySearcher
    $sercher.SearchRoot = $domain 
    $sercher.Filter = ("(objectCategory=$category)")
    $list = $sercher.FindAll()
    return $list #this returns an array of type 'SearchResult'
}

function get_user_properties {
Param(        
        [Parameter(Mandatory=$true, 
                    ValueFromPipeline=$false,                    
                    Position=0)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]         
	    $list
)
$results =  @() #array fro results
foreach ($u in $list) {
    $props = $u.properties
    $resList = New-Object PsObject -Property @{
        UserName = [string]$props.samaccountname
        DisplayName = [string]$props.displayname
        EmailAddresses = [string[]]$props.proxyaddresses
        LastLogin = [datetime]::FromFileTime($($props.lastlogontimestamp)).ToString('MM-dd-yy')
        Description = [string]$props.description
    }    
    #loads of fun in this fucker. So because of the way PS handles strings and string arrays,
    #this is the best way I know of to make it one big `n deliminated string
    foreach ($m in $resList.EmailAddresses) {       
        if ($resList.EmailAddresses -is [system.array]) { $resList.EmailAddresses  = [string]"$m`n" }
        else {$resList.EmailAddresses = $resList.EmailAddresses + "$m`n"}
    } 
    $results += $resList
}

return $results #returns an array of PsObjects
}

function get_computer_properties {
Param(        
        [Parameter(Mandatory=$true, 
                    ValueFromPipeline=$false,                    
                    Position=0)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()] 
	    $list
)

$results =  @() #array fro results
foreach ($c in $list) {
    $props = $c.properties
    $resList = New-Object PsObject -Property @{
        Name = [string]$props.name        
        LastLogin = [datetime]::FromFileTime($($props.lastlogontimestamp)).ToString('MM-dd-yy')
        OperatingSystem = [string]$props.operatingsystem
        ServicePack = [string]$props.operatingsystemservicepack
        FQDN = [string]$props.dnshostname
    }
    $results += $resList
}
return $results
}

function get_group_properties {
Param(        
        [Parameter(Mandatory=$true, 
                    ValueFromPipeline=$false,                    
                    Position=0)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
	    $list
)
$results = @() #initalize array for results
foreach ($g in $list) { #itorate through list of groups
    $g = $g.properties
    $resList = New-Object PsObject -Property @{ #Create PsObject for switch below
        GroupName = [String]$g.name
        GroupType = [String]$g.grouptype     
        GroupMembers = [String[]]$g.member                                                       
    }
    #loads of fun in this fucker. So because of the way PS handles strings and string arrays,
    #this is the best way I know of to make it one big `n deliminated string
    foreach ($m in $resList.GroupMembers) {       
        if ($resList.GroupMembers -is [system.array]) { $resList.GroupMembers  = [string]"$m`n" }
        else {$resList.GroupMembers = $resList.GroupMembers + "$m`n"}
    }           
    switch ($resList.GroupType) { #Changes the grouptype to human readable format
        "2" {$resList.GroupType = "Global Distro Group"}
        "4" {$resList.GroupType = "Domain Local Distro Group"}
        "8" {$resList.GroupType = "Universal Distro Group"}
        "-2147483646" {$resList.GroupType = "Global Sec Group"}
        "-2147483644" {$resList.GroupType = "Domain Local Sec Group"}
        "-2147483640" {$resList.GroupType = "Universal Sec Group"}
        Default {$resList.GroupType = "Other Group"}
    }
    #$resList
    $results += $resList                
}
return $results
}


#This is the 'main' function. Exports to a file or returns an object.
function get_ad_list {
    Param(        
        [Parameter(Mandatory=$true, 
                    ValueFromPipeline=$false,                    
                    Position=0)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]        
        [ValidateSet("computer","user","group")]        
	    $type,
        [Parameter(Mandatory=$false,
                    ValueFromPipeline=$false,
                    Position=1)]
        [ValidateSet("csv","html")]
        $file
    )
 
    #This will be what 'stays' in the get_ad_list function:
    $list = search_ad($type) 

    #The replaced call to required properties:    
    switch ($type) {
        group { $results = get_group_properties($list) }
        user { $results = get_user_properties($list) }
        computer { $results = get_computer_properties($list) }
    }

    $date = Get-Date -Format "MM-dd-yy_hhmm"
    switch ($file) {
        csv {$results | Export-Csv "$($date)_$($type).csv" -NoTypeInformation}
        html {$results | ConvertTo-Html | Out-File "$($date)_$($type).html"}
        Default {return $results}    
    }
}