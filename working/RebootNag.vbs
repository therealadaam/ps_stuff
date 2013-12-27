option explicit
on error resume next

Dim strComputer, intRebootChoice
Dim objWMIService, objOperatingSystem
Dim colOperatingSystems 

strComputer = "."

do while 1>0
 intRebootChoice = msgbox("Hello, you, need to reboot.  Choose No to be asked again 1 hour",308,"Reboot incoming")
 select case intRebootChoice
  case 6
   Set objWMIService = GetObject("winmgmts:" & "{impersonationLevel=impersonate,(Shutdown)}!\\" & strComputer & "\root\cimv2")
   Set colOperatingSystems = objWMIService.ExecQuery ("Select * from Win32_OperatingSystem")
   For Each objOperatingSystem in colOperatingSystems
    ObjOperatingSystem.Reboot(1)
   Next
  case 7
   wscript.sleep(3600000)
  case else
   'shenanigans'
 end select
loop