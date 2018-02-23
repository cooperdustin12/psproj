# Copyright © 2008, Microsoft Corporation. All rights reserved.


#
# Check the visual effects setting.
#

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

Write-DiagProgress -activity $localizationString.progress_ts_visualEffects

[string]$Key = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\explorer\VisualEffects"
[string]$property = "VisualFXSetting"

$value = Get-ItemProperty $key $property
if($value -ne $null -and $value.$property -eq 1)
{
    Update-DiagRootCause -id "RC_VisualEffects" -Detected $true
} else {
    Update-DiagRootCause -id "RC_VisualEffects" -Detected $false
}
