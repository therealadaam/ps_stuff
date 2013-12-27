Get-ADComputer -pr operatingsystem -Filter * | select @{label="Name"; Expression="name"},@{Label="OS"; Expression="operatingsystem"} | sort OS,Name | Export-Csv -Path C:\OS-by-PC.csv

