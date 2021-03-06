# Copyright © 2015, Microsoft Corporation. All rights reserved.
# :: ======================================================= ::
<#
	DESCRIPTION:	
	  TS_NotDefault checks whether given audio device is default on not.

	ARGUMENTS:
	  $deviceType: Type of the audio device which needs to be verified.
	  $deviceID: ID of the audio device which needs to be verified.

	RETURNS:
	  <&true> if not a default audio device otherwise <$false>
#>

#====================================================================================
# Initialize
#====================================================================================
PARAM($deviceType, $deviceID)
Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

#====================================================================================
# Load Utilities
#====================================================================================
. .\CL_Utility.ps1

#====================================================================================
# Main
#====================================================================================
[bool]$result = $true
[bool]$detected = $false

Write-DiagProgress -Activity $localizationString.notDefault_progress

Get-AudioManager
$result = [Microsoft.Windows.Diagnosis.AudioConfigManager]::IsEndPointDefault($deviceID, $deviceType)
if(-not($result))
{
	$detected = $true
} 
Update-DiagRootCause -ID 'RC_NotDefault' -Detected $detected -Parameter @{'DeviceType' = $deviceType; 'DeviceID' = $deviceID}
return $detected