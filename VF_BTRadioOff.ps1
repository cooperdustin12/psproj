# Copyright © 2016, Microsoft Corporation. All rights reserved.
# :: ======================================================= ::
#====================================================================================
# Initialize
#====================================================================================
Import-LocalizedData -BindingVariable Strings_VF_BTRadioOff -FileName CL_LocalizationData
$detected = $false
#====================================================================================
# Load Utilities
#====================================================================================
. .\CL_Utility.ps1

#====================================================================================
# Main
#====================================================================================
$detected = $bluetoothRadioState -eq 'RadioState_Off'

Update-DiagRootCause -ID 'RC_BTRadioOff' -Detected $detected -Parameter @{'BluetoothRadioState'= $bluetoothRadioState}
return $detected