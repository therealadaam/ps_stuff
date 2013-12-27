#script to backup local user data and send to network destination
#created by Adam Rabenstein on 11/22/2013

function backup_local_data ($backupDest)
{
    $pc = $env:COMPUTERNAME
    if (!(Test-Path $backupDest)) {
        Write-Host "Bad Backup Dest!"
        Exit
        }
        
    New-Item $backupDest\$pc -ItemType "directory"
    $sDest = Get-Item $backupDest\$pc

    #check if XP or later
    $version = [Environment]::OSVersion.Version -ge (New-Object 'Version' 6,0)

    if ($version) {
        Set-Location -Path "C:\users"
        $userFolders = Get-ChildItem | Where-Object {$_.Name -ne "Administrator"} | Where-Object {$_.Name -ne "Public"} | Where-Object {$_.Name -ne "UpdatusUser"}
        Foreach ($u in $userFolders) {
            Copy-Item -Path $u -Destination $sDest -Force -Recurse -ErrorAction Continue
        }
    }
    else {
        Set-Location -Path "C:\Documents and settings"
        $userFolders = Get-ChildItem | Where-Object {$_.Name -ne "Administrator"}
         Foreach ($u in $userFolders) {
            Copy-Item -Path $u -Destination $sDest -Force -Recurse -ErrorAction Continue
        }
    }
}