#Written on 10-16-2013 by Adam Rabenstein

net stop spooler
del $env:windir\system32\spool\printers\*.*

net start spooler
$printers = gwmi -class win32_printer | ? {$_.Name -like "\\sstisrv1*"}
foreach ($p in $printers) {$p.delete}


#$null = New-PSDrive -Name HKU   -PSProvider Registry -Root Registry::HKEY_USERS 

#cd HKU:
#$userReg = dir
#foreach ($i in $userReg) {
	#$userPrinters = dir $i\Printers\Connections
	#foreach ($p in $userPrinters) {
		#if ($p.GetValue("Server").StartsWith('\\sstisrv1',"CurrentCultureIgnoreCase") ) { del $p -ErrorAction SilentlyContinue } 	
	#}
	#$devPrinters = dir $i\Software\Microsoft\Windows NT\CurrentVersion\Devices
	#foreach ($d in $devPrinters) {
		#$d.StartsWith('\\sstisrv1',"CurrentCultureIgnoreCase") { del $d -ErrorAction SilentlyContinue} 
	#}
#}
