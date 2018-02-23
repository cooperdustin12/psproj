
$computers = import-csv C:\tmp\Services_Serverlistbak.csv
ForEach ($computer in $computers){
$computername = $computer.Caption
$servicename = $computer.Name
if ($computername -like "*CBN.Local") {

$computer | foreach-Object{ (Get-Service -Name "*$servicename*" -computername $computername) | Where-Object {$_.Name -like "*$servicename*"} | Sort-Object Name, DisplayName, Status  | Format-Table -Property $computer.Caption.Trim(), Name  -wrap | Format-Wide -Column 2
}
if ($computername -notlike "*CBN.Local") {
Write-Host $computername

}
}
}










$server | foreach { (Get-Service -Name '*' -computername $computername) | Where-Object {$_.Status -eq "Running"} | Select-Object Status, Name, DisplayName 
 

Write-host foreach $server in $server
}


$server = Import-Csv C:\tmp\Services_Serverlist.csv | Where-Object {$_.Caption -like *}

$server | foreach { (Get-Service -Name ccm* -computername $_) |
 Select-Object Status, Name, DisplayName | 
ConvertTo-HTML | Out-File "C:\tmp\test.htm"}