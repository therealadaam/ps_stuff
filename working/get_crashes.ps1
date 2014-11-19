$computers = "ljcwrk20","ljcwrk21","ljcwrk23","ljcwrk25","ljcwrk27","ljcwrk34"
$date = read-host -prompt "Enter the date see crashes after"

foreach ($c in $computers) {
	$user = gwmi win32_computersystem -comp $c| select username
	$user = $user.username

	#bad form, dgaf, need to get done/working
	if ($c -eq "ljcwrk23") {$user = "rpain"
	} else { $user = $user.Split('\')[1] }

	try {	$dumps = ls "\\$($c)\c$\users\$($user)\appdata\local\crashdumps" -ea stop
		$dumps = $dumps | where {$_.LastWriteTime -gt $date} -ea stop
	} catch {
		$dumps = "Nothing here!"
	}
	write-host $c $user
	write-host $dumps
}