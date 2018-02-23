# Copyright © 2008, Microsoft Corporation. All rights reserved.


. .\CL_WinSAT.ps1
. .\CL_Utility.ps1

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

Write-DiagProgress -activity $localizationString.WDDM_progress

[bool]$result = $false

[string]$fileName = GetLatestAssessmentFile

if($fileName -eq $null)
{
    throw "Can't find latest assessment file"
}

[XML]$winsatData = Get-Content $fileName

$result = (HasWDDMDriver $winsatData)

if(-not($result))
{
    Update-DiagRootCause -id "RC_WDDMDriver" -Detected $true
} else {
    Update-DiagRootCause -id "RC_WDDMDriver" -Detected $false
}

return $result
