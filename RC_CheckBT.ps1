# Copyright © 2016, Microsoft Corporation. All rights reserved.
# :: ======================================================= ::

#====================================================================================
# Initialize
#====================================================================================
Import-LocalizedData -BindingVariable Strings_RC_CheckBT -FileName CL_LocalizationData 
$detected = $false

#====================================================================================
# Main
#====================================================================================
Write-DiagProgress -Activity $Strings_RC_CheckBT.ID_Check_Bluetooth

$findBluetooth=( Get-WmiObject -Class CIM_LogicalDevice | ? {($_.ClassGuid -eq '{e0cbf06c-cd8b-4647-bb8a-263b43f0f974}')})
$detected = !$findBluetooth

Update-DiagRootCause -ID 'RC_CheckBT' -Detected $detected
return $detected