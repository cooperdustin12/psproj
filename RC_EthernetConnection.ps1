# Copyright © 2017, Microsoft Corporation. All rights reserved.
# :: ======================================================= ::
#====================================================================================
# Initialize
#====================================================================================
Import-LocalizedData -BindingVariable Strings_EthernetConnection -FileName CL_LocalizationData
[bool]$detected = $false

#====================================================================================
# Load Utilities
#====================================================================================
. .\CL_Utility.ps1

#====================================================================================
# Main
#====================================================================================
Write-DiagProgress -Activity $Strings_EthernetConnection.ID_PROG_InternetConnectionCheck

if((Test-InternetConnection) -eq $false)
{
	$detected = $true
}

Update-DiagRootCause -ID 'RC_EthernetConnection' -Detected $detected