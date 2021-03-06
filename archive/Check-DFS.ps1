<#

#>

function Test-DFS {
	[CmdletBinding()]
	Param(
	[Parameter(Mandatory=$true)]	
	$srv1 = "C:\",
    [Parameter(Mandatory=$true)]	
	$srv2 = "C:\",
    [Parameter(Mandatory=$true)]	
	$profilesPath = (ls "C:\profiles")
	)
    
    Write-Host "Checking to see if $srv1 and $srv2 are in sync."
    ForEach ($p in $profilesPath) {
        if (Test-Path $srv1) {
            #do stuff
            echo "Tested working"
            } else {echo "test"}
        
        Test-Path $srv2
    }
}