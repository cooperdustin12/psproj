# Copyright © 2008, Microsoft Corporation. All rights reserved.


# Trouble Shooting Common library
. .\CL_RegSnapin.ps1

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

Write-DiagProgress -activity $localizationString.colorDepthResolve_progress

$dll = "MonitorSnapin.dll"
$nameSpace = "Microsoft.Windows.Diagnosis.SystemInfo.MonitorInfo"

try {
    RegSnapin $dll $nameSpace

    $Monitors = Get-Monitors

    $Monitors | foreach {if($_.ColorDepth -ne 32){$_.ChangeColorDepth(32)}}
} finally {
    UnregSnapin $dll $nameSpace
}
