# Copyright © 2008, Microsoft Corporation. All rights reserved.


. .\CL_WinSat.ps1

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

Write-DiagProgress -activity $localizationString.Winsat_progress

[bool]$result = CheckWinSatHaveRun

if(-not($result))
{
    Update-DiagRootCause -id "RC_WinSatNotRun" -Detected $true
} else {
    Update-DiagRootCause -id "RC_WinSatNotRun" -Detected $false
}

return $result
