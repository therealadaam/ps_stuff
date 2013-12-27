#Script that connects to tickets.com SFTP server and downloads customer info/data
#Created by Adam Rabenstein
#If $debug = $true then it logs just about everything

#debugging info
#$debug = $true
#$debugDate = Get-date -format MM-dd-yyy.hh:mm.ss

$Error.Clear();
$location = 'D:\DFS_Data\shares\Shared Data\Development\Provenue Ticket Buyers'
$ftpHost = '216.32.146.23'
$ftpUser = 'v_mccallum'
$ftpPassword = 'MC2013!!'

sl $location
if ($debug = $true ) {"$debugDate: This is the location: $location" >> C:\ProVenueDL.log}

$ftpGetCommandFile = "$(get-location)\ftpGetCommand.sftp"
$ftpLsCommand = "$(get-location)\ftpLsCommand.sftp"
$ftpDeleteCommand = "$(get-location)\ftpDeleteCommand.sftp"
if ($debug = $true ) {"$debugDate : This is the getCmdFile: $ftpGetCommandFile" >> C:\ProVenueDL.log}
if ($debug = $true ) {"$debugDate : This is the lsCmdFile: $ftpLsCommand" >> C:\ProVenueDL.log}
if ($debug = $true ) {"$debugDate : This is the delCmdFile: $ftpDeleteCommand" >> C:\ProVenueDL.log}

function ftp_work {
Param(
[Parameter(Mandatory=$true)]
$un,
$pass,
$ftpSrv,
$commandFile)
    & .\psftp.exe -l $un -pw $pass  $ftpSrv -b $commandFile -be -bc
    if($LastExitCode -ne 0 -and $commandFile -eq $ftpGetCommandFile){
        return "Error downloading files.  "}
    if($LastExitCode -ne 0 -and $commandFile -eq $ftpDeleteCommand) {
        return "Error deleting files. "}
}

function create_folders {
Param(
$files)

#if there are more than 1 days worth of files to DL, make the folders
if ($files.Length -gt 0) {
    foreach ($f in $files) {
        $folderName = $f.Split('_')[-1].split('.')[0].remove(10,9) #string magic to get the date from the filename
        mkdir $folderName
    } 
} else { #If only one make the folder
    $folderName = $files.Split('_')[-1].split('.')[0].remove(10,9)
    mkdir $folderName}

}

function sort_files {
Param(
$date)
    $toMoveTo = dir | ?{$_.Attributes -eq "Directory"} | ? {$_.Name -like "$date"}
    $files = dir | ? {$_.Attributes -ne "Directory"}
    $files | ? {$_.Name -like "*$date*.out"} | mv -Destination $toMoveTo
}


#remove old command files
if(Test-Path $ftpGetCommandFile){
    Remove-Item $ftpGetCommandFile
}
if(Test-Path $ftpDeleteCommand){
    Remove-Item $ftpDeleteCommand
}
if(Test-Path $ftpLsCommand){ #The continue command does not work like I expected it to in powershell.
} else { "ls" | Out-File $ftpLsCommand -Append -Encoding Ascii
}
if ($debug = $true ) {"$debugDate : This is the ftplsCmd: $ftpLsCommand" >> C:\ProVenueDL.log}

#list the files in the directory
$lsOfDir = & .\psftp.exe -l $ftpUser -pw $ftpPassword  $ftpHost -b $ftpLsCommand -be #the ftpLsCommand just contains an ls command
if($LastExitCode -ne 0){
    if ($debug = $true ) {"$debugDate : Error connecting to ftp" >> C:\ProVenueDL.log}
}

$remoteFiles = $lsOfDir | % {$_.Split()[-1]} #gets the filename of the files from the ftp list

$goFiles = $remoteFiles | ? {$_ -like "*.go"} #Get the .go files

create_folders $goFiles
if ($debug = $true ) {"$debugDate : Folders should be created">> C:\ProVenueDL.log}

#gets the filenames of the files we want to get and then delete later
$remoteFiles = $remoteFiles | where {$_ -like "*.out" }

$remoteFiles | % {
    "get $_" | Out-File $ftpGetCommandFile -Append -Encoding Ascii
    "delete $_" | Out-File $ftpDeleteCommand -Append -Encoding Ascii
}
$goFiles | % {
	"delete $_" | out-file $ftpDeleteCommand -Append -Encoding Ascii
}

if ($debug = $true ) {"$debugDate : ftp get and delete commands created" >> C:\ProVenueDL.log}

if ($debug = $true ) {"$debugDate : Downloading Files" >> C:\ProVenueDL.log}
ftp_work $ftpUser $ftpPassword $ftpHost $ftpGetCommandFile
if ($debug = $true ) {"$debugDate : Files downloaded" >> C:\ProVenueDL.log}

$tFiles = dir | ? {$_.Name -like "trait*"}
$dates = $tFiles | % {$_.name.Split('_')[-1].split('.')[0].remove(10,9)}

foreach ($d in $dates) {
    sort_files $d
}
if ($debug = $true ) {"$debugDate : Files sorted now, ready to delete." >> C:\ProVenueDL.log}

ftp_work $ftpUser $ftpPassword $ftpHost $ftpDeleteCommand
if ($debug = $true ) {"$debugDate : Completed!" >> C:\ProVenueDL.log}