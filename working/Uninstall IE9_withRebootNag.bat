@echo off

FORFILES /P %WINDIR%\servicing\Packages /M Microsoft-Windows-InternetExplorer-*9.*.mum /c "cmd /c start /w pkgmgr /up:@fname /norestart"
FORFILES /P %WINDIR%\servicing\Packages /M Microsoft-Windows-InternetExplorer-*9.*.mum /c "cmd /c start /w pkgmgr /up:@fname /norestart"

pushd %~dp0
start "" cmd /c cscript rebootnag.vbs