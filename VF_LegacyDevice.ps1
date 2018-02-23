
# Copyright © 2011, Microsoft Corporation. All rights reserved.

# Verifier Script
# Calls Update-DiagRootcause indicating whether the original root cause is detected or fixed.

# Parameters are defined in DiagPackage.diag and are set in rootcause detection script.
PARAM($DeviceDescription, $VprString, $DeviceInstanceId)

# Warn on improper use of variables, functions
Set-StrictMode -version 2

# All scripts first execute contents of CL_Utility.ps1
. .\CL_Utility.ps1

$instanceId = GetLegacyDeviceInstanceId -VprString $VprString           `
                                        -DevinstId $DeviceInstanceId

$deviceSet = New-Object Microsoft.Windows.Diagnosis.DeviceSet($DeviceInstanceId)
$portNumber = $deviceSet.GetAddress()
$parentHubPath = $deviceSet.GetParentId()

$rootcauseDetected = IsLegacyDeviceOnUSB3 -DeviceInstanceId $DeviceInstanceId   `
                                          -ParentHubPath $parentHubPath         `
                                          -PortNumber $portNumber

Update-DiagRootcause -id $Constants.LegacyDeviceRootcauseId             `
                     -detected $rootcauseDetected                       `
                     -instanceid $instanceid                            `
                     -param @{'DeviceDescription'=$DeviceDescription; 'VprString'=$VprString; 'DeviceInstanceId'=$DeviceInstanceId}
