#Written on 10-16-2013 by Adam Rabenstein
net stop spooler

del $env:windir\system32\spool\printers\*.*

$null = New-PSDrive -Name HKU   -PSProvider Registry -Root Registry::HKEY_USERS 

cd HKU:
$userReg = dir
foreach ($i in $userReg) {
    $userPrinters = dir $i\Printers\Connections
    foreach ($p in $userPrinters) {
	if ($p.GetValue("Server").StartsWith('\\') ) { del $p -ErrorAction SilentlyContinue } 
	}else { continue }
    }

net start spooler
