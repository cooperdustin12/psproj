# Copyright © 2008, Microsoft Corporation. All rights reserved.

# TroubleshooterScript - This script checks for the presence of a root cause
# Key Cmdlets:
# -- update-diagrootcause flags the status of a root cause and can be used to pass parameters
# -- get-diaginput invokes an interactions and returns the response
# -- write-diagprogress displays a progress string to the user

$RootCauseID = "RC_Deprecated"
$Detected = $false 

get-diaginput -id "IT_Deprecated"

update-diagrootcause -id $RootCauseId -detected $Detected