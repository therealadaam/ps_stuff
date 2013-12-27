<#
.Version
    0.1 - Adam Rabenstein
.Synopsis
   Used to get all GPOs in the domain
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>

function Get-All-GPO
{
    Param
    (
        # Param1 help description
        #[Parameter(Mandatory=$true,
                  # ValueFromPipelineByPropertyName=$true,
                   #Position=0)]
        [switch]$verbose,

        # Param2 help description
        [switch]$test
    )
#Sets the domain to the current domain, might expand to select a list of domains in the forest.
$domain = $env:USERDOMAIN

$gpm = New-Object -ComObject gpmgmt.gpm
$constants = $gpm.GetConstants()
$gpmDomain = $gpm.GetDomain($domain,$null,$constants.useanydc)
$gpmSearchCriteria = $gpm.CreateSearchCriteria()
$gpo=$gpmdomain.SearchGPOs($gpmSearchCriteria)

 if($verbose)
  { 
   $gpo 
  }
 ELSE
  {
   foreach($ogpo in $gpo)
    {
     $hash += @{ $ogpo.ID = $ogpo.DisplayName }
    }
     format-table -inputobject $hash -autosize
  } #end else



[System.Runtime.Interopservices.Marshal]::ReleaseComObject($gpm)
} #end Get-All-GPO


