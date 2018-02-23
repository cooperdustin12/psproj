# Copyright © 2016, Microsoft Corporation. All rights reserved.
# :: ======================================================= ::

PARAM($errorCode,$blueScreenDateTime)

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

$info = $LocalizedStrings.RS_MemoryFailureBlueScreen_Info
$URL = $LocalizedStrings.RS_MemoryFailureBlueScreen_URL

#Provide Info
Get-DiagInput -ID 'INT_BlueScreen_Info' -Parameter @{'errorCode'= $errorcode; 'blueScreenDateTime'=$blueScreenDateTime; 'info'=$info; 'URL'=$URL}