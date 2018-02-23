# Copyright © 2008, Microsoft Corporation. All rights reserved.


. .\CL_RegSnapin.ps1

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

Write-DiagProgress -activity $localizationString.colorDepth_progress

[bool]$result = $false
try {
    RegSnapin MonitorSnapin.dll Microsoft.Windows.Diagnosis.SystemInfo.MonitorInfo

    $result = (Get-Monitors | where {$_.ColorDepth -ne 32}) -eq $null

    if(-not($result))
    {
        Update-DiagRootCause -id "RC_LowColorDepth" -Detected $true

        $propertyArray = @()
        $propertyArray += @{Name=$localizationString.colorDepth;Expression={[string]($_.ColorDepth) + " bits"}}
        $propertyArray += @{Name=$localizationString.requiredDepth;Expression={"32 bits"}}
        if(1 -eq @(Get-Monitors).Count) {
            $propertyArray += @{Name=$localizationString.Primary;Expression={$_.Primary}}
        }

        Get-Monitors | Select-Object $propertyArray | convertto-xml | Update-DiagReport -id ColorDepth -name $localizationString.colorDepth_name -description $localizationString.colorDepth_description -Verbosity informational -rid "RC_LowColorDepth"
    } else {
        Update-DiagRootCause -id "RC_LowColorDepth" -Detected $false
    }
} finally {
    UnregSnapin MonitorSnapin.dll Microsoft.Windows.Diagnosis.SystemInfo.MonitorInfo
}

return $result
