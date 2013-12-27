echo This will uninstall IE9, and put back the prior version. Press any key to continue...

pause

FORFILES /P %WINDIR%\servicing\Packages /M Microsoft-Windows-InternetExplorer-*9.*.mum /c "cmd /c start /w pkgmgr /up:@fname /norestart"
FORFILES /P %WINDIR%\servicing\Packages /M Microsoft-Windows-InternetExplorer-*9.*.mum /c "cmd /c start /w pkgmgr /up:@fname /norestart"

echo The computer will now reboot. Press any key to continue...

pause

shutdown -r -f -t 0