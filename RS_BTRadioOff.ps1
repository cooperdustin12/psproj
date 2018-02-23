# Copyright © 2016, Microsoft Corporation. All rights reserved.
# :: ======================================================= ::
Param($bluetoothRadioState)
#====================================================================================
# Initialize
#====================================================================================
Import-LocalizedData -BindingVariable Strings_RS_BTRadioOff -FileName CL_LocalizationData
 
#====================================================================================
# Load Utilities
#====================================================================================
. .\CL_Utility.ps1

#====================================================================================
# Main
#====================================================================================
Write-DiagProgress -Activity $Strings_RS_BTRadioOff.ID_TurnOn_Bluetooth

if($bluetoothRadioState -ne $null)
{
	try
	{
		Reset-Bluetooth($bluetoothRadioState)
	}
	catch [System.Exception]
	{
		Write-ExceptionTelemetry "MAIN" $_
		$_ | ConvertTo-Xml | Update-DiagReport -ID 'RS_BTRadioOff' -Name 'RS_BTRadioOff' -Verbosity Debug
	}
}