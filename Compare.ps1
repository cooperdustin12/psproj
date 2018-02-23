#Use this script to compare a basic VM state against a VM with installed Apps to help build Solarwinds Monitors


#basefile IP should point to a fresh VM state
$basefile = "10.100.20.137"
#Targetfile IP should point to the VM with newly installed, unmonitored apps,services
$targetfile = "10.100.21.45"


#Get Services
"Comparing Services.."
$Services_1 = Get-Service -ComputerName "$basefile" | Select-Object name
$Services_2 = Get-Service -ComputerName "$targetfile" | Select-Object name
$compareserv = Compare-Object $Services_1 $Services_2 –property name 





#Get Processes
"Comparing Processes.." 
$Processes_1 = Get-Process -ComputerName "$basefile"| Select-Object name -Unique
$Processes_2 = Get-Process -ComputerName "$targetfile"| Select-Object name -Unique
$compareproc = Compare-Object $Processes_1 $Processes_2 –property name 





#Get Perfmon Counters
"Performance Counters.."
$Perfmon_1 = Get-Counter -Computer "$basefile" -ListSet * | Select-Object CounterSetName
$Perfmon_2 = Get-Counter -Computer "$targetfile" -ListSet * | Select-Object CounterSetName
$compareperfmon = Compare-Object $Perfmon_1 $Perfmon_2 -Property CounterSetName 

Sleep -s 2

"Outputting Differences.."

Sleep -s 2

"Services.."
Out-String -InputObject $compareserv | Out-File
Sleep -s 2

"Processes.."
Out-String -InputObject $compareproc
Sleep -s 2

"Permon Objects.."
Out-String -InputObject $compareperfmon
Sleep -s 2



"Now Lets do Event Log Sources Last.."

Sleep -s 2

#Get Event Log Sources
"Comparing Event Log Sources.."

$EventLog_1 = Get-Eventlog -ComputerName "$basefile" -Logname * | ForEach-Object {$LogName = $_.Log;Get-EventLog -LogName $LogName -ErrorAction SilentlyContinue | Select-Object @{Name="Log Name";Expression = {$LogName}}, Source -Unique} 

$EventLog_2 = Get-Eventlog -ComputerName "$targetfile" -Logname * | ForEach-Object {$LogName = $_.Log;Get-EventLog -LogName $LogName -ErrorAction SilentlyContinue | Select-Object @{Name="Log Name";Expression = {$LogName}}, Source -Unique} 
$comparelog = Compare-Object -ReferenceObject $EventLog_1 -DifferenceObject $EventLog_2
$a = Out-String -InputObject  $comparelog

Out-string -InputObject $a


Sleep -s 1

"DONE"