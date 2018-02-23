# Copyright © 2008, Microsoft Corporation. All rights reserved.

. .\CL_Utility.ps1

#
# Start the SysMain and set the mode as automatic
#
Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

Write-DiagProgress -activity $localizationString.progress_rs_startSysMainService

[string]$startupType = (Get-WmiObject -query "select * from win32_baseService where Name='SysMain'").StartMode

if($startupType -ne "auto" -and $startupType -ne $null)
{
    (Get-WmiObject -query "select * from win32_baseService where Name='SysMain'").changeStartMode("automatic")
}

Start-Service SysMain
WaitFor-ServiceStatus "SysMain" ([ServiceProcess.ServiceControllerStatus]::Running)