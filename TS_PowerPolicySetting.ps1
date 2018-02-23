# Copyright © 2008, Microsoft Corporation. All rights reserved.


. .\CL_LoadAssembly.ps1
. .\CL_Utility.ps1

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

Write-DiagProgress -activity $localizationString.powerPolicySetting_progress

[bool]$result = $false

LoadAssemblyFromNS "System.Windows.Forms"

# check power policy
[string]$powercfgCmd = GetSystemPath "Powercfg.exe"
$cmdOutput = & $powercfgCmd "/GETACTIVESCHEME"
if($cmdOutput -match "[a-f\d]{8}-[a-f\d]{4}-[a-f\d]{4}-[a-f\d]{4}-[a-f\d]{12}")
{
    $powerPolicyGuid = $matches[0]
}

# check power status
$lineOn = [System.Windows.Forms.SystemInformation]::PowerStatus.PowerLineStatus

New-Object -TypeName System.Management.Automation.PSObject | Select-Object @{Name=$localizationString.powerSource;Expression={ConvertTo-PowerSourceName $lineOn}},@{Name=$localizationString.originalSetting;Expression={Get-PowerPolicyInfo $cmdOutput}} | Convertto-Xml | Update-DiagReport -id CurrentPowerPolicySetting -name $localizationString.powerPolicy_name -description $localizationString.powerPolicy_Description -Verbosity informational -rid "RC_PowerPolicySetting"

$result = -not (($powerPolicyGuid -eq "A1841308-3541-4FAB-BC81-F71556F20B4A") -and ($lineOn -eq "Offline"))

if(-not($result))
{
    Update-DiagRootCause -id "RC_PowerPolicySetting" -Detected $true
} else {
    Update-DiagRootCause -id "RC_PowerPolicySetting" -Detected $false
}

return $result
