while($true) {gwmi win32_computersystem -com "mctwrk1","mctwrk2","mctwrk4","mctwrk5","mctwrk6","mctwrk7","mctwrk8","mctwrk10","mctwrk11","mctwrk12","mctwrk13","mctwrk14","mctwrk15","mctwrk16","mctwrk17","mctwrk19","mctwrk23","mctwrk24","mctwrk25","mctwrk26","mctwrk27","mctwrk28","mctwrk29","mctwrk30","mctwrk31","mctwrk32","mctwrk33","mctwrk34","mctwrk35","mctwrk36","mctwrk37","mctwrk38","mctwrk39","mctwrk40","mctwrk41","mctwrk44","mctwrk45" | select name,username
Start-Sleep -Seconds 30
echo "_____________________________________"}
