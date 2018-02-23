# Copyright © 2008, Microsoft Corporation. All rights reserved.

#
# Remove all users's startup programs
#

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData
. .\CL_Utility.ps1

Write-DiagProgress -activity $localizationString.progress_rs_removeAllUsersStartupPrograms

$choices = New-Object -TypeName System.Collections.ArrayList

#
# Perhaps the string array could be added later.
#
[string]$HKLMRun = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
[string]$HKLMWowRun = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run"
$keyArray = ($HKLMRun, $HKLMWowRun)
#
# check startup file
#
[string]$programData = "$env:SystemDrive\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
$pathArray = ($programData)

RemoveStartupPrograms $keyArray $pathArray "IT_AllUsersStartupPrograms" $true

