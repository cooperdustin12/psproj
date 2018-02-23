# Copyright © 2009, Microsoft Corporation. All rights reserved.

#*=================================================================================
# Parameters
#*=================================================================================

#*=================================================================================
# Load Utilities
#*=================================================================================
. ./utils_SetupEnv.ps1
#. ./CL_MutexVerifiers.ps1

#*=================================================================================
#Initialize 
#*=================================================================================

#*=================================================================================
#Run resolver logic
#*=================================================================================

$path = "registry::HKEY_LOCAL_MACHINE\software\microsoft\windows\currentversion\audio"
Remove-ItemProperty -Path $path -Name "DisableprotectedaudioDG" -Force -ErrorAction SilentlyContinue
net stop audiosrv /y
net start audiosrv
#runningResolver "aud_reg_settings" "registry"
