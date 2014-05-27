#region Connect to Exchange server in LAN or through VPN.

#Used to connect to Exchange server so cmdlets can be run in any powershell session
#change $server to the FQDN for the server hosting exchange
$server = "server.domain.com"
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$server/PowerShell/ -Authentication Kerberos
Import-PSSession $Session
#endregion
