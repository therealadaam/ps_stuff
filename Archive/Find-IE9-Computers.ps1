$computers = net view |% {if ($_ -match "^\\\\(\S+)"){$matches[1]}}
$versions = $computers | foreach {[system.diagnostics.fileversioninfo]::GetVersionInfo("\\$_\C`$\program files\internet explorer\iexplore.exe") }

$wrkWith9 = $versions | ? {$_.filename -like "*wrk*"} | ? {$_.productversion -like "9*"}
$wrkWith9 = $wrkWith9 | % {$_.filename.remove(0,2).split('\')[0] }
$ToNatural = { [regex]::Replace($_, '\d+', { $args[0].Value.PadLeft(20) }) }
$wrkWith9 | sort $ToNatural