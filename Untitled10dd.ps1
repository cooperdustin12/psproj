Clear-Host
$numRep=3
$Sleep=5
$Idle1=$DiskTime1=$T1=$Idle2=$DiskTime2=$T2=$numRep=3

for ($i=1; $i -le $numRep; $i++)
{
$Disk = Get-WmiObject -class Win32_PerfRawData_PerfDisk_LogicalDisk `

[Double]$Idle1 = $Disk.PercentIdleTime
[Double]$DiskTime1 = $Disk.PercentDiskTime
[Double]$T1 = $Disk.TimeStamp_Sys100NS

start-Sleep $Sleep

$Disk = Get-WmiObject -class Win32_PerfRawData_PerfDisk_LogicalDisk `

[Double]$Idle2 = $Disk.PercentIdleTime
[Double]$DiskTime2 = $Disk.PercentDiskTime
[Double]$T2 = $Disk.TimeStamp_Sys100NS

"Repetition $i ... counting to $numRep..."

$PercentIdleTime =(1 - (($Idle2 - $Idle1) / ($T2 - $T1))) * 100
"`t Percent Disk Idle Time is " + "{0:n2}" -f $PercentIdleTime
$PercentDiskTime =(1 - (($DiskTime2 - $DiskTime1) / ($T2 - $T1))) * 100
"`t Percent Disk Time is " + "{0:n2}" -f $PercentDiskTime

}