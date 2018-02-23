# Copyright © 2016, Microsoft Corporation. All rights reserved.
# :: ======================================================= ::

Param($problemDeviceID)
#====================================================================================
# Initialize
#====================================================================================
Import-LocalizedData -BindingVariable Strings_RC_OtherIssue -FileName CL_LocalizationData
[bool]$detected = $false

#====================================================================================
# Load Utilities
#====================================================================================
. ./CL_Utility.ps1

#====================================================================================
# Main
#====================================================================================

if(![string]::IsNullOrWhiteSpace($problemDeviceID))
{
	$problemDevice = (Get-WmiObject -Class CIM_LogicalDevice | ? {($_.DeviceID  -eq $problemDeviceID)})
	$problemDeviceName = $problemDevice.Name
	$errorCode = $problemDevice.ConfigManagerErrorCode
	if(($knownErrorCodes.Keys -notcontains $errorCode) -and ($errorCode -ne 22))
	{
		$detected = $true
	}
}

Update-DiagRootCause -ID 'RC_OtherIssue' -IID $problemDeviceID -Detected $detected -Parameter @{'ProblemDeviceID'= $problemDeviceID;'ProblemDeviceName'=$problemDeviceName;'ErrorCode'=$errorCode}
return $detected