<#
.Version
    0.1
    Created script, imported/copied helpful function in.
    0.2
    Adding WMI elements for DNS settings.
    0.3
    Added more stuff, there are multiple functions now, one to get and one to set.

.Synopsis
    Created by Adam Rabenstein on 12-6-2013.
    This is a set of functions related to DNS. Setting, getting, reporting, etc.
    http://blogs.technet.com/b/heyscriptingguy/archive/2012/02/28/use-powershell-to-configure-static-ip-and-dns-settings.aspx
   
.EXAMPLE
    change_dns_for_computers

.Todo
   
}
#>

function set_dns_for_computers {
Param(
        [Parameter(Mandatory=$true, 
                    ValueFromPipeline=$false,                    
                    Position=0,
                    ParameterSetName='Computers')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("p1")] 
	    $computers,
        [Parameter(Mandatory=$true,
                    ValueFromPipeline=$false,
                    Position=1,
                    ParameterSetName='New DNS Server')]        
        [Alias("p2")]
        $newDNSServer,
        [Parameter(Mandatory=$false, 
                    ValueFromPipeline=$false,                    
                    Position=2,
                    ParameterSetName='Old DNS Server')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("p3")]
        $oldDNSServer
    )

    #for each get wmi and set DNS
    Foreach($computer in $computers) {    
        $NICs = gwmi win32_networkadapterconfiguration -ComputerName $computer -Filter "IPEnabled = 'True'"
        Foreach($NIC in $NICs) {       
        
            #If DHCP is disabled, change DNS server to the new one
            if (!$NIC.DHCPEnabled) {
                $NIC.SetDNSServerSearchOrder($newDNSServer)
                #$NIC.SetDynamicDNSRegistration(“TRUE”)

            #If DHCP is enabled, check the current servers, set to DHCP DNS
            } elseif ($NIC.DNSServerSearchOrder -ne $null){                
                $NIC.EnableDHCP()                
            }
        }
    }
}

function get_dns_for_computers {
Param(
        [Parameter(Mandatory=$true, 
                    ValueFromPipeline=$false,                    
                    Position=0,
                    ParameterSetName='Computers')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("p1")] 
	    $computers        
    )

    #for each get wmi and set DNS
    Foreach($computer in $computers) {    
        $NICs = gwmi win32_networkadapterconfiguration -ComputerName $computer -Filter "IPEnabled = 'True'"
        Foreach($NIC in $NICs) {
            $date = Get-Date -Format "MM-dd-yy_hh:mm"       
        
            #If DHCP is disabled, change DNS server to the new one
            if (!$NIC.DHCPEnabled) {
                "$date : $computer is set to DNS server(s): $($NIC.DNSServerSearchOrder)" | Out-File -Append -FilePath "C:\temp\DNS.log"

            #If DHCP is enabled, check the current servers, replace the old one if dns is statically set
            } elseif ($NIC.DNSServerSearchOrder -ne $null){
                #Log the current DNS server(s) for DHCP client
                "$date : $computer is set to DNS server(s): $($NIC.DNSServerSearchOrder)" | Out-File -Append -FilePath "C:\temp\DNS.log"                
            }
        }
    }
}