# Copyright © 2016, Microsoft Corporation. All rights reserved.
# :: ======================================================= ::


PARAM($errorCode,$blueScreenDateTime,$deviceId,$deviceName)

#====================================================================================
# Initialize
#====================================================================================
Import-LocalizedData -BindingVariable LocalizedStrings -FileName CL_LocalizationData

#====================================================================================
# Load Utilities
#====================================================================================
. .\Utils_BlueScreen.ps1

#====================================================================================
# Main
#====================================================================================

if($deviceId -eq "NoDeviceSelected"){
	return
}
else
{

	if ([system.environment]::Is64BitOperatingSystem)
	{
		$ChangeDriver = Get-DriverSource
	}
	else
	{
		$ChangeDriver = Get-DriverSource32
	}

	#RollBack checked driver by the user
	$rolledBack= $null

	$rollbackResult = $ChangeDriver::RollbackDriver($deviceId);

	if($rollbackResult -eq 0){
		$rolledBack += ("$deviceName - $deviceId | Rolled Back Successfully")
	}
	elseif($rollbackResult -eq 259){
		$rolledBack += ("$deviceName - $deviceId | Error [$rollbackResult]. No Roll Back Driver is Available")
	}
	else {
		$rolledBack += ("$deviceName - $deviceId | Error [$rollbackResult]. Please try to Roll Back this driver manually on Device Manager.")
	}

	#RollBack Result
	[string] $BSLogFileName = (Get-Location -PSProvider FileSystem).ProviderPath
	$BSLogFileName = join-path  $BSLogFileName "\BS-ProblemDriver.log"
	"###############################">> $BSLogFileName
	"Blue screen [$errorCode] might be caused by a driver update." >> $BSLogFileName
	"The following Devices were selected to Roll Back to the previous driver" >> $BSLogFileName
	"###############################">> $BSLogFileName
	"" >> $BSLogFileName
	"$rolledBack" >> $BSLogFileName

	Update-DiagReport -file $BSLogFileName -id "RS_ProblemDriverBlueScreen" -name "BS-ProblemDriver Log" -description "Drivers Rolled Back Results..." -Verbosity Informational
}


