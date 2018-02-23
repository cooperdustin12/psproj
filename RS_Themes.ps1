# Copyright © 2008, Microsoft Corporation. All rights reserved.


. .\CL_Utility.ps1

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

Write-DiagProgress -activity $localizationString.themesResolve_progress

# check the Uxsms service startup tpe
$startupType = (Get-WmiObject -query "select * from win32_baseService where Name='Themes'").StartMode

#resolver
if($startupType -ne "auto" -and $startupType -ne $null)
{
    (Get-WmiObject -query "select * from win32_baseService where Name='Themes'").changeStartMode("automatic") > $null
}

Restart-Service Themes
WaitFor-ServiceStatus "Themes" ([ServiceProcess.ServiceControllerStatus]::Running)