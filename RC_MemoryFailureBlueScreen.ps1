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
write-diagprogress -activity $LocalizedStrings.RC_MemoryFailureBlueScreen_Running

$errorcode = $bugCheckEvents[0].ErrorCode
$blueScreenDateTime = $bugCheckEvents[0].TimeCreated

Update-DiagRootcause -ID RC_MemoryFailureBlueScreen -Detected $true -iid $errorcode -Parameter @{'errorCode'= $errorcode; 'blueScreenDateTime'= $blueScreenDateTime}
