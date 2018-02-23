# Copyright © 2017, Microsoft Corporation. All rights reserved.
# :: ======================================================= ::

#====================================================================================
# Initialize
#====================================================================================
Param ($problemDeviceID, $problemDeviceName)
Import-LocalizedData -BindingVariable Strings_RS_NetworkAdapterDisabled -FileName CL_LocalizationData 

#====================================================================================
# Load Utilities
#====================================================================================
. .\CL_Utility.ps1

#====================================================================================
# Main
#====================================================================================
Write-DiagProgress -Activity $Strings_RS_NetworkAdapterDisabled.ID_EnableNetworkAdapterDisabled
try
{
	Get-WmiObject -Class Win32_PnPEntity | ? {($_.DeviceID  -eq $problemDeviceID)} | Enable-PnpDevice -Confirm:$false
}
catch [System.Exception]
{
	Write-ExceptionTelemetry "RC_NetworkAdapterDisabled" $_
    $_ | ConvertTo-Xml | Update-DiagReport -ID 'RS_NetworkAdapterDisabled' -Name 'RS_NetworkAdapterDisabled' -Verbosity Debug
}