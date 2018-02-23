# Copyright © 2016, Microsoft Corporation. All rights reserved.
# :: ======================================================= ::

PARAM([System.Array]$bugCheckEvents)

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
write-diagprogress -activity $LocalizedStrings.RC_ProblemDriverBlueScreen_Running
try
{
	#Get all Plug and Play (PnP) devices with RollBack Driver Available
	$allPnpDevicesWithRollBack = Get-PnpDevice | Get-PnpDeviceProperty -KeyName '{83DA6326-97A6-4088-9453-A1923F573B29} 4' | Where {$_.Data -ne $null}

	foreach ($bugCheck in $bugCheckEvents){

		$blueScreenDateTime = $bugCheck.TimeCreated
		$errorcode = $bugCheck.ErrorCode

		if(!$allPnpDevicesWithRollBack){
			Update-DiagRootcause -ID RC_ProblemDriverBlueScreen -Detected $false -iid "$errorcode/NoRollBackDrivers" -parameter @{'errorCode'= $errorcode; 'blueScreenDateTime'=$blueScreenDateTime; 'deviceID'= "NoRollBackDrivers";'deviceName'="NoRollBackDrivers"}
		}
		else{
			#If InstallDate -le 72h of $blueScreenDateTime add it to $suspectedDeviceList
			$suspectedDeviceList = @()
			foreach ($device in $allPnpDevicesWithRollBack){
				#Get InstallDate
				$installDate = Get-PnpDeviceProperty -InstanceId $device.InstanceId -KeyName 'DEVPKEY_Device_InstallDate'
				if($installDate.Data -le $blueScreenDateTime -and $installDate.Data -ge ($blueScreenDateTime - (New-TimeSpan -Hours 72))){
					$suspectedDeviceList+=$device
				}
			}

			if(!$suspectedDeviceList){
				Update-DiagRootcause -ID RC_ProblemDriverBlueScreen -Detected $false -iid "$errorcode/NoDeviceFound" -parameter @{'errorCode'= $errorcode; 'blueScreenDateTime'=$blueScreenDateTime; 'deviceID'= "NoDeviceFound";'deviceName'="NoDeviceFound"}
			}
			else{
				#Select driver to rollback from Suspected Device List
				$choices = @()
				foreach($suspectedDevice in $suspectedDeviceList){
					$choices += @{"Name" = ((Get-PnpDevice -InstanceId ($suspectedDevice.InstanceID)).FriendlyName); "Value" = ((Get-PnpDevice -InstanceId ($suspectedDevice.InstanceID)).FriendlyName + ";" + $suspectedDevice.InstanceID); "Description" = ""; "ExtensionPoint" = ""}
				}
				$choices += @{"Name" = $LocalizedStrings.RC_ProblemDriverBlueScreen_ChoiceNoDevice; "Value" = "NoDeviceSelected;NoDeviceSelected"; "Description" = ""; "ExtensionPoint" = ""}
			
				$checkedDevice = Get-DiagInput -Id "INT_DriversToRollBackChoices" -Choice $choices -Parameter @{"errorCode" = $errorcode; "blueScreenDateTime" = $blueScreenDateTime}

				$checkedDevice = $checkedDevice.Split(";")
				$checkedDeviceName = $checkedDevice[0]
				$checkedDeviceId = $checkedDevice[1]

				Update-DiagRootcause -ID RC_ProblemDriverBlueScreen -Detected $true -iid "$errorcode/$checkedDeviceId" -parameter @{'errorCode'= $errorcode; 'blueScreenDateTime'=$blueScreenDateTime; 'deviceID'= $checkedDeviceId; 'deviceName'=$checkedDeviceName}
				#We are only targetting the most recent BlueScreen with a suspected Device List
				return
			}
		}
	}
}
catch [System.Exception]
{
	Write-ExceptionTelemetry "RC_ProblemDriverBlueScreen" $_
	$errorMsg = $_.Exception.Message
	$errorMsg | ConvertTo-Xml | Update-DiagReport -id "RC_ProblemDriverBlueScreen" -name "RC_ProblemDriverBlueScreen" -Verbosity Debug
}

