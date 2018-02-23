# Copyright © 2008, Microsoft Corporation. All rights reserved.


. .\CL_Utility.ps1

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

Write-DiagProgress -activity $localizationString.transparency_progress

[bool]$result = $true

try {
    $result = Check-Transparency
} catch {
    return
}

if(-not($result))
{
    Update-DiagRootCause -id "RC_Transparency" -Detected $true
} else {
    Update-DiagRootCause -id "RC_Transparency" -Detected $false
}

return $result
