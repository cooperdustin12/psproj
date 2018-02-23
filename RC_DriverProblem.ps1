# Copyright © 2016, Microsoft Corporation. All rights reserved.
# :: ======================================================= ::
Param($problemDeviceID, $action)
#====================================================================================
# Initialize
#====================================================================================
Import-LocalizedData -BindingVariable Strings_RC_DriverProblem -FileName CL_LocalizationData
[bool]$detected = $false
#====================================================================================
# Load Utilities
#====================================================================================
. ./CL_Utility.ps1

#====================================================================================
# Main
#====================================================================================
Write-DiagProgress -Activity $Strings_RC_DriverProblem.ID_PROG_DriverProblems

if(![string]::IsNullOrWhiteSpace($problemDeviceID))
{
	$problemDevice = (Get-WmiObject -Class CIM_LogicalDevice | ? {($_.DeviceID  -eq $problemDeviceID)})
	$problemDeviceName = $problemDevice.Name
	$errorCode =  $problemDevice.ConfigManagerErrorCode
	if($knownErrorCodes.Keys -contains $errorCode)
	{
		$detected = $true
	}
}

if($detected)
{
	Update-DiagRootCause -ID 'RC_DriverProblem' -IID $problemDeviceID -Detected $detected -Parameter @{'ProblemDeviceID'= $problemDeviceID; 'ProblemDeviceName'= $problemDeviceName}
}
else
{
	if ($action -eq 'Verify')
	{
		Update-DiagRootCause -ID 'RC_DriverProblem' -IID $problemDeviceID -Detected $detected -Parameter @{'ProblemDeviceID'= $problemDeviceID; 'ProblemDeviceName'= $problemDeviceName}
	}
}

return $detected