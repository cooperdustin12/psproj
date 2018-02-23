# Copyright © 2017, Microsoft Corporation. All rights reserved.
# :: ======================================================= ::
Param($problemDeviceID, $action)
#====================================================================================
# Initialize
#====================================================================================
Import-LocalizedData -BindingVariable Strings_RC_NetworkAdapterErrors -FileName CL_LocalizationData
[bool]$detected = $false
#====================================================================================
# Load Utilities
#====================================================================================
. ./CL_Utility.ps1

#====================================================================================
# Main
#====================================================================================
Write-DiagProgress -Activity $Strings_RC_NetworkAdapterErrors.ID_PROG_NetworkAdapterErrors

if(![string]::IsNullOrWhiteSpace($problemDeviceID))
{
	$problemDevice = (Get-WmiObject -Class Win32_PnPEntity | ? {($_.DeviceID -eq $problemDeviceID)})
	$problemDeviceName = $problemDevice.Name
	$errorCode = $problemDevice.ConfigManagerErrorCode
	if($knownErrorCodes.Keys -contains $errorCode)
	{
		$detected = $true
	}
}
if($detected)
{
	Update-DiagRootCause -ID 'RC_NetworkAdapterErrors' -IID $problemDeviceID -Detected $detected -Parameter @{'ProblemDeviceID'= $problemDeviceID; 'ProblemDeviceName'= $problemDeviceName}
}
else
{
	if ($action -eq 'Verify')
	{
		Update-DiagRootCause -ID 'RC_NetworkAdapterErrors' -IID $problemDeviceID -Detected $false -Parameter @{'ProblemDeviceID'= $problemDeviceID; 'ProblemDeviceName'= $problemDeviceName}
	}
}
return $detected