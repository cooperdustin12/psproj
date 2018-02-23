# Copyright © 2008, Microsoft Corporation. All rights reserved.


#
# Remove current user's startup programs
#

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData
. .\CL_Utility.ps1

Write-DiagProgress -activity $localizationString.progress_rs_removeCurrentUserStartupPrograms

$choices = New-Object -TypeName System.Collections.ArrayList
#
# Check registry key
#
[string]$HKCURun = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
[string]$HKCUWowRun = "HKCU:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run"
$keyArray = ($HKCURun, $HKCUWowRun)
#
# check startup file
#
[string]$currentUserRoaming = "$env:userProfile\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
[string]$currentUserLocal = "$env:userProfile\AppData\Local\Microsoft\Windows\Start Menu\Programs\Startup"
$pathArray = ($currentUserRoaming, $currentUserLocal)

RemoveStartupPrograms $keyArray $pathArray "IT_CurrentUserStartupPrograms" $false
