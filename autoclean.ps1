Function Cleanup { 
<# 
.CREATED BY: 
    Matthew A. Kerfoot 
.CREATED ON: 
    10\17\2013 
.Synopsis 
   Aautomate cleaning up a C: drive with low disk space 
.DESCRIPTION 
   Cleans the C: drive's Window Temperary files, Windows SoftwareDistribution folder, ` 
   the local users Temperary folder, IIS logs(if applicable) and empties the recycling bin. ` 
   All deleted files will go into a log transcript in C:\Windows\Temp\. By default this ` 
   script leaves files that are newer than 7 days old however this variable can be edited. 
.EXAMPLE 
   PS C:\Users\mkerfoot\Desktop\Powershell> .\cleanup_log.ps1 
   Save the file to your desktop with a .PS1 extention and run the file from an elavated PowerShell prompt. 
.NOTES 
   This script will typically clean up anywhere from 1GB up to 15GB of space from a C: drive. 
.FUNCTIONALITY 
   PowerShell v3 
#> 
function global:Write-Verbose ( [string]$Message ) 
 
# check $VerbosePreference variable, and turns -Verbose on 
{ if ( $VerbosePreference -ne 'SilentlyContinue' ) 
{ Write-Host " $Message" -ForegroundColor 'Yellow' } } 
 
$VerbosePreference = "Continue" 
$DaysToDelete = 30
$LogDate = get-date -format "MM-d-yy-HH" 
$objShell = New-Object -ComObject Shell.Application  
$objFolder = $objShell.Namespace(0xA) 
$ErrorActionPreference = "silentlycontinue" 
                     
Start-Transcript -Path C:\Windows\Temp\$LogDate.log 
 
## Cleans all code off of the screen. 
Clear-Host 
 
$size = Get-ChildItem C:\Users\* -Include *.iso, *.vhd -Recurse -ErrorAction SilentlyContinue |  
Sort Length -Descending |  
Select-Object Name, 
@{Name="Size (GB)";Expression={ "{0:N2}" -f ($_.Length / 1GB) }}, Directory | 
Format-Table -AutoSize | Out-String 
 
$Before = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq "3" } | Select-Object SystemName, 
@{ Name = "Drive" ; Expression = { ( $_.DeviceID ) } }, 
@{ Name = "Size (GB)" ; Expression = {"{0:N1}" -f( $_.Size / 1gb)}}, 
@{ Name = "FreeSpace (GB)" ; Expression = {"{0:N1}" -f( $_.Freespace / 1gb ) } }, 
@{ Name = "PercentFree" ; Expression = {"{0:P1}" -f( $_.FreeSpace / $_.Size ) } } | 
Format-Table -AutoSize | Out-String                       
                     
## Stops the windows update service.  
Get-Service -Name wuauserv | Stop-Service -Force -Verbose -ErrorAction SilentlyContinue 
## Windows Update Service has been stopped successfully! 
 
## Deletes the contents of windows software distribution. 
Get-ChildItem "C:\Windows\SoftwareDistribution\*" -Recurse -Force -Verbose -ErrorAction SilentlyContinue | remove-item -force -Verbose -recurse -ErrorAction SilentlyContinue 
## The Contents of Windows SoftwareDistribution have been removed successfully! 
 
## Deletes the contents of the Windows Temp folder. 
Get-ChildItem "C:\Windows\Temp\*" -Recurse -Force -Verbose -ErrorAction SilentlyContinue | 
Where-Object { ($_.CreationTime -lt $(Get-Date).AddDays(-$DaysToDelete)) } | 
remove-item -force -Verbose -recurse -ErrorAction SilentlyContinue 
## The Contents of Windows Temp have been removed successfully! 
              
## Delets all files and folders in user's Temp folder.  
Get-ChildItem "C:\users\*\AppData\Local\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue | 
Where-Object { ($_.CreationTime -lt $(Get-Date).AddDays(-$DaysToDelete))} | 
remove-item -force -Verbose -recurse -ErrorAction SilentlyContinue 
## The contents of C:\users\$env:USERNAME\AppData\Local\Temp\ have been removed successfully! 
                     
## Remove all files and folders in user's Temporary Internet Files.  
Get-ChildItem "C:\users\*\AppData\Local\Microsoft\Windows\Temporary Internet Files\*" ` 
-Recurse -Force -Verbose -ErrorAction SilentlyContinue | 
Where-Object {($_.CreationTime -le $(Get-Date).AddDays(-$DaysToDelete))} | 
remove-item -force -recurse -ErrorAction SilentlyContinue 
## All Temporary Internet Files have been removed successfully! 
                     
## Cleans IIS Logs if applicable. 
Get-ChildItem "C:\inetpub\logs\LogFiles\*" -Recurse -Force -ErrorAction SilentlyContinue | 
Where-Object { ($_.CreationTime -le $(Get-Date).AddDays(-60)) } | 
Remove-Item -Force -Verbose -Recurse -ErrorAction SilentlyContinue 
## All IIS Logfiles over x days old have been removed Successfully! 
                   
## deletes the contents of the recycling Bin. 
## The Recycling Bin is now being emptied! 
$objFolder.items() | ForEach-Object { Remove-Item $_.path -ErrorAction Ignore -Force -Verbose -Recurse } 
## The Recycling Bin has been emptied! 
 
## Starts the Windows Update Service 
Get-Service -Name wuauserv | Start-Service -Verbose 
 
$After =  Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq "3" } | Select-Object SystemName, 
@{ Name = "Drive" ; Expression = { ( $_.DeviceID ) } }, 
@{ Name = "Size (GB)" ; Expression = {"{0:N1}" -f( $_.Size / 1gb)}}, 
@{ Name = "FreeSpace (GB)" ; Expression = {"{0:N1}" -f( $_.Freespace / 1gb ) } }, 
@{ Name = "PercentFree" ; Expression = {"{0:P1}" -f( $_.FreeSpace / $_.Size ) } } | 
Format-Table -AutoSize | Out-String 
 
 ##Now Run automated Disk Cleanup
    cleanmgr /sagerun:1 | out-Null  
     
    $([char]7) 
    Sleep 1  
    $([char]7) 
    Sleep 1  


## Sends some before and after info for ticketing purposes 
 
Hostname ; Get-Date | Select-Object DateTime 
Write-Verbose "Before: $Before" 
Write-Verbose "After: $After" 
Write-Verbose $size 
## Completed Successfully! 
Stop-Transcript } Cleanup

