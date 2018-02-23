# Copyright © 2009, Microsoft Corporation. All rights reserved.


#*=================================================================================
# Parameters
#*=================================================================================


#*=================================================================================
# Load Utilities
#*=================================================================================
. ./utils_SetupEnv.ps1

#*=================================================================================
#Initialize 
#*=================================================================================

#*=================================================================================
#Run detection logic logic
#*=================================================================================
#set-stateOFRootCause "aud_reg_settings"
#pop-msg "registry rootcause"
$registryfound = $false
$path = "registry::HKEY_LOCAL_MACHINE\software\microsoft\windows\currentversion\audio"
if(Test-Path $path)
{
    $v = get-item -Path $path
    foreach($item in $v.GetValueNames())
	{
		if($item.ToLower() -eq "disableprotectedaudiodg")
		{
			update-diagrootcause -id "RC_ProtectedAudioDisabled" -detected $true
			$registryfound = $true
			return
		}
	}
}

update-diagrootcause -id "RC_ProtectedAudioDisabled" -detected $registryfound
