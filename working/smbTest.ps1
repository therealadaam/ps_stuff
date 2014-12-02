while ($i -lt 10) {
$i++
echo "Test" > file1
write-host "Moving to srv"
if (-not (test-path \\ljcsrv2\shared\file1)) {
	cp file1 \\ljcsrv2\shared\
	cp \\ljcsrv2\shared\file1 \\ljcsrv2\shared\file2
}
echo "Testing more of this now." >> \\ljcsrv2\shared\file1
echo "Yet more testing..." >> \\ljcsrv2\shared\file2
#write-host "Removing files from srv:"
#rm \\ljcsrv2\shared\file1
#rm \\ljcsrv2\shared\file2
}