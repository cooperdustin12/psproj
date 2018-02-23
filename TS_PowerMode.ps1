# Copyright © 2008, Microsoft Corporation. All rights reserved.

#
# Check whether power mode is set to power Saver
#
Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData
. .\CL_Utility.ps1

Write-DiagProgress -activity $localizationString.progress_ts_powerMode

[bool]$isPowerSaver = Detectpowerplan 0

if($isPowerSaver)
{
    Update-DiagRootCause -id "RC_PowerMode" -Detected $true
}
else
{
    Update-DiagRootCause -id "RC_PowerMode" -Detected $false
}
