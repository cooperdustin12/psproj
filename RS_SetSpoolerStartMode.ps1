# Copyright ?2008, Microsoft Corporation. All rights reserved.


#
# Set the start mode for the spooler service 
#

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData
. .\CL_Utility.ps1
Write-DiagProgress -activity $localizationString.progress_rs_setSpoolerStartMode

$spoolersvc = Get-WMIObject Win32_Service | Where-Object {$_.Name -eq "spooler"}

if($spoolersvc.StartMode -ne "Auto")
{
    $spoolersvc.ChangeStartMode("Automatic")   
}