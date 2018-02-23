# Copyright © 2016, Microsoft Corporation. All rights reserved.
# :: ======================================================= ::
Param($problemDeviceID, $action)
#====================================================================================
# Initialize
#====================================================================================
Import-LocalizedData -BindingVariable Strings_RC_Disabled -FileName CL_LocalizationData
[bool]$detected = $false
#====================================================================================
# Main
#====================================================================================

if(![string]::IsNullOrWhiteSpace($problemDeviceID))
{
	$problemDevice = (Get-WmiObject -Class CIM_LogicalDevice | ?{($_.DeviceID -eq $problemDeviceID)})
	$problemDeviceName = $problemDevice.Name
	$errorCode = $problemDevice.ConfigManagerErrorCode
	if($errorCode -eq 22)
	{
		$detected = $true
	}
}

if($detected)
{
	Update-DiagRootCause -ID 'RC_Disabled' -IID $problemDeviceID -Detected $detected -Parameter @{'ProblemDeviceID' = $problemDeviceID; 'ProblemDeviceName' = $problemDeviceName}
}
else
{
	if ($action -eq 'Verify')
	{
		Update-DiagRootCause -id RC_Disabled -IID $problemDeviceID -Detected $false -Parameter @{'ProblemDeviceID'= $problemDeviceID; 'ProblemDeviceName'= $problemDeviceName}
	}
}

return $detected