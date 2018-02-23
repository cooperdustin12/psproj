# Copyright © 2009, Microsoft Corporation. All rights reserved.

#*=================================================================================
# Parameters
#*=================================================================================
#PARAM ($drivers)

#*=================================================================================
# Load Utilities
#*=================================================================================
. ./utils_SetupEnv.ps1


#*=================================================================================
#Initialize 
#*=================================================================================

#*=================================================================================
#Run detection logic
#*=================================================================================
#set-stateOFRootCause "viddrv_2kbs_req1"
$drivers = gwmi win32_VideoController |select DeviceID,Name,DriverVersion #|ft -a
$global:defaultflag = $false
foreach($driver in $drivers)
{
	<#pop-msg $driver.name
	if((($driver.name) -ilike "Mobile Intel(R) 4 Series Express Chipset Family (Microsoft Corporation - WDDM 1.1)") -and (($driver.DriverVersion) -eq "8.15.10.2702"))
	{
		continue
	}
	elseif((($driver.Name) -ilike "*Microsoft Basic Display*") -or (($driver.name) -ilike "*WDDM*"))
	{
		#pop-msg "default driver"
		update-diagrootcause -id "RC_MSFTBasicVideoDriver" -detected $true -Parameter @{"DName"= $driver.Name; "DVersion"=$driver.DriverVersion}
		$global:defaultflag = $true
		break
	}#>
	if((($driver.Name) -ilike "*Microsoft Basic Display*"))# -or (($driver.name) -ilike "*WDDM*"))
	{
		#pop-msg "default driver"
		update-diagrootcause -id "RC_MSFTBasicVideoDriver" -detected $true -Parameter @{"DName"= $driver.Name; "DVersion"=$driver.DriverVersion}
		$global:defaultflag = $true
		break
	}
}
if($global:defaultflag -eq $false)
{
	#pop-msg "good driver"
	update-diagrootcause -id "RC_MSFTBasicVideoDriver" -detected $false
}



