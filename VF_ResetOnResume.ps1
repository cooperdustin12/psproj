# Copyright © 2008, Microsoft Corporation. All rights reserved.

# Verifier Script
# Calls Update-DiagRootcause indicating whether the original root cause is detected or fixed.

# Parameters are defined in DiagPackage.diag and are set in rootcause detection script.
PARAM($DeviceVprString, $PortOnParentHub, $ParentHubPath, $DevinstId)

# Warn on improper use of variables, functions
Set-StrictMode -version 2

# All scripts first execute contents of CL_Utility.ps1
. .\CL_Utility.ps1

# Correct variables must be set in the root cause instance's parameter.
# (Their values should not need to be correct since detected=false)
$parameter = @{DeviceVprString = $DeviceVprString;
               PortOnParentHub = $PortOnParentHub;
               ParentHubPath = $ParentHubPath;
               DevinstId = $DevinstId;
               }

$instanceId = GetResetOnResumeInstanceId -VprString $DeviceVprString `
                                         -Port $PortOnParentHub `
                                         -ParentHubPath $ParentHubPath `
                                         -DevinstId $DevinstId

Update-DiagRootcause -id $Constants.ResetOnResumeRootcauseId `
                     -detected $false `
                     -instanceid $instanceId `
                     -parameter $parameter

