# Copyright © 2017, Microsoft Corporation. All rights reserved.
# :: ======================================================= ::
Param ($problemDeviceID,$problemDeviceName)
#====================================================================================
# Initialize
#====================================================================================
Import-LocalizedData -BindingVariable Strings_RS_NetworkAdapterErrors -FileName CL_LocalizationData

#====================================================================================
# Load Utilities
#====================================================================================
. .\CL_Utility.ps1

#====================================================================================
# Main
#====================================================================================
Write-DiagProgress -Activity $Strings_RS_NetworkAdapterErrors.ID_RS_PROG_NetworkAdapterErrors

try
{
	Remove-Device($problemDeviceID)
	Reinstall-Device($problemDeviceID)
	Rescan-Devices
	Get-DiagInput -ID 'INT_UpdateDriver' -Parameter @{'ProblemDeviceName'=$problemDeviceName}
}
catch [System.Exception]
{
	Write-ExceptionTelemetry "RS_NetworkAdapterErrors" $_
	$_ | ConvertTo-Xml | Update-DiagReport -ID 'RS_NetworkAdapterErrors' -Name 'RS_NetworkAdapterErrors' -Verbosity Debug
}