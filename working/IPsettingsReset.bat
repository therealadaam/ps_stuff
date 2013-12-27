@echo off
REM used to reset IP settings then renew IP address with dhcp

netsh int ip reset resetlog.txt
ipconfig /release && ipconfig /renew
exit
