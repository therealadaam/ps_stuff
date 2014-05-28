<#
.Version
    0.1
    Created script, formated it out.

.Synopsis
   Created by Adam Rabenstein on 5-27-2014.
   https://support.microsoft.com/kb/221833/en-us
  
.EXAMPLE
   enable_winlogon_debugging

.Todo
    Remote - does it for remote wrk
    Local - for local host
#>

#region local

$logonProps = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'

if ($logonProps.UserEnvDebugLevel -ne '0x00030002') {
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name UserEnvDebugLevel -Value 0x00030002
}

#endregion