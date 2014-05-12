<#
.Version
    0.1
    Created script, formated it out.

.Synopsis
   Created by Adam Rabenstein on 05-12-2014.
   Gets a list of all the shares for localhost, options for remote computer, or input from list.
   Exports to a .csv file
  
.EXAMPLE
   get_shares

.Todo
    Get permissions on the shares

#>

#Get for localhost only
Get-WmiObject -Class win32_share | select name,path,description | Export-CSV -NoTypeInformation 'shares.csv'
