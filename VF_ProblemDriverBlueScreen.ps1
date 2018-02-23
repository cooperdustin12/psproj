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
else{
	[string] $BSLogFileName = (Get-Location -PSProvider FileSystem).ProviderPath
	$BSLogFileName = join-path  $BSLogFileName "\BS-ProblemDriver.log"
	#Check if driver was successfully Rolled Back.
	$detected = $false
	if (Test-Path $BSLogFileName)
	{
		$BSLogFileContent = Get-Content $BSLogFileName
		foreach($line in $BSLogFileContent){
			if($line -like "*Error*"){
				#Driver not successfully Rolled Back
				$detected = $true
			}
		}
	}
	else{
		return
	}
	Update-DiagRootcause -ID RC_ProblemDriverBlueScreen -Detected $detected -iid "$errorcode/$deviceId" -parameter @{'errorCode'= $errorcode; 'blueScreenDateTime'=$blueScreenDateTime; 'deviceID'= $deviceId; 'deviceName'=$deviceName}
}
