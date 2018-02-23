# Copyright © 2017, Microsoft Corporation. All rights reserved.
# :: ======================================================= ::
#====================================================================================
# Initialize
#====================================================================================
Import-LocalizedData -BindingVariable Strings_RS_NetworkAdapterReset -FileName CL_LocalizationData
[bool]$detected = $false

#====================================================================================
# Main
#====================================================================================
Write-DiagProgress -Activity $Strings_RS_NetworkAdapterReset.ID_PROG_NetworkAdapterReset

$activeAdapters = Get-NetAdapter

foreach($activeAdapter in $activeAdapters)
{
	Restart-NetAdapter -Name $activeAdapter.Name
	#Sleeping as Resetting Network takes little time.
	Sleep 9
}