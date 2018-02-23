# Copyright © 2008, Microsoft Corporation. All rights reserved.


#
# Check whether the aero effect impacts the performance
#

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

Write-DiagProgress -activity $localizationString.progress_ts_SuperFetch

if((get-service SysMain).status -ne "Running")
{
    Update-DiagRootCause -id "RC_SuperFetch" -Detected $true
} else {
    Update-DiagRootCause -id "RC_SuperFetch" -Detected $false
}
