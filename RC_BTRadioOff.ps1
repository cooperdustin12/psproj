# Copyright © 2016, Microsoft Corporation. All rights reserved.
# :: ======================================================= ::

#====================================================================================
# Initialize
#====================================================================================
Import-LocalizedData -BindingVariable Strings_RC_BTRadioOff -FileName CL_LocalizationData 

#====================================================================================
# Load Utilities
#====================================================================================
. .\CL_Utility.ps1

#====================================================================================
# Main
#====================================================================================
Write-DiagProgress -Activity $Strings_RC_BTRadioOff.ID_Check_Radio_Bluetooth

Update-DiagRootCause -ID 'RC_BTRadioOff' -Detected $true -Parameter @{'BluetoothRadioState'= $bluetoothRadioState}
return $true