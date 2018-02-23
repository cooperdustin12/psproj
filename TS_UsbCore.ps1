# Copyright © 2008, Microsoft Corporation. All rights reserved.

# TroubleshooterScript - This script checks for the presence of a root cause

# Warn on improper use of variables, functions
Set-StrictMode -version 2

# All scripts first execute contents of CL_Utility.ps1
. .\CL_Utility.ps1


# Define functions and constants:


function GetVprString(
    [string]$HardwareId
    )
#
# Function Description:
#     Parse a USB hardware ID and retrieve its VID, PID, and REV.
#
# Arguments:
#     $HardwareId - String to parse.  Should look like "USB\VID_045E&PID_0039&REV_0300".
#
# Return value:
#     $null on parsing failure, else
#     12-hex-digit string of USB Vid, Pid, and Rev.  Example: "045E00390300".
#
{
    # Match the hardware ID against a regular expression pattern (case-sensitive).

    # Meaning of pattern string: Search for "VID_", followed by exactly 4 hex digits,
    #                            followed by anything, followed by "PID_", etc.
    # The parentheses define sub-patterns, causing the text that matches each sub-pattern
    # to be saved.

    $regexResult = [Regex]::Match($HardwareId,
                                  "VID_([0-9A-F]{4}).*PID_([0-9A-F]{4}).*REV_([0-9A-F]{4})"
                                  ).Groups
    # $regexResult[0] is the entire match, $regexResult[1] is the VID match, etc.

    # Check for failure.
    if ($regexResult[0].Success -eq $false -or $regexResult.Count -ne 4) {
        $null # failure return value
        return
    }
    # Ignore $regexResult[0] and extract the matching strings.
    $vprArray = $regexResult | select -last 3 | %{$_.Value}
    # Successful return value:
    $vprArray[0] + $vprArray[1] + $vprArray[2]
}


function FindRecentDriverProblems(
    [DateTime]$StartTime,
    [String[]]$DevinstId
    )
#
# Function description:
#     Search the event log for PNP troubleshooter rootcauses relating to driver problems.
#
# Arguments:
#     $StartTime - Earliest (minimum) event time
#     $DevinstId - 0 or more device instance IDs for which to search for driver problems
#                  (If count is 0, no problems will be found)
#
# Return value:
#     $true if a driver troubleshooting event was found, $false otherwise
#
{

    $driverProblemDevices = # Find devices that were troubleshooted recently for driver problems:
        Get-WinEvent -FilterHashtable @{LogName = "Microsoft-Windows-Diagnosis-Scripted/Operational";
                                        StartTime = $StartTime;
                                        } |
        Where   { $_.Id -eq 401 -or $_.Id -eq 402 } | # detected/fixed
        Where   { $_.Properties[0].Value -eq "DeviceDiagnostic" } | # by pnp troubleshooter
        Foreach { $_.Properties[1].Value } | # get just the rootcause instance id
        Where   { $_ -match "^RC_[^/]*Driver[^/]*/" } | # driver problems
        Foreach { $_ -replace "RC_[^/]*/","" } | # remove rootcause, leaving device id
        Select-Object -unique # leave 1 instance of each troubleshooted device id

    if ($driverProblemDevices -eq $null) {
        # PNP troubleshooter events not found.
        $driverProblemDevices = @()
    }

    # Compare parameter devinsts to driver problem devinsts.  If there's any
    # overlap, return $true.
    if ((Compare-Object -IncludeEqual -ExcludeDifferent $driverProblemDevices $DevinstId) -ne $null) {
        # Overlap found
        $true # return value
    } else {
        $false # return value
    }

}


function FindRecentInstalls(
    [DateTime]$StartTime,
    [String[]]$DevinstId
    )
#
# Function description:
#     Check if any devices have a recent Install Date.
#     (Install Date is the latest time when the device was installed or its driver was updated.)
#
# Arguments:
#     $StartTime - Earliest (minimum) Install Date to consider recent
#     $DevinstId - 0 or more device instance IDs whose install dates to check
#                  (If count is 0, no devnodes are considered to have had recent installs)
#
# Return value:
#     $true if any devnode's Install Date is "recent", $false otherwise
#
{
    $returnValue = $false
    $DevinstId | Foreach {
        # Get the Install Date property via DeviceSet class
        $deviceSet = New-Object Microsoft.Windows.Diagnosis.DeviceSet($_)
        if ($deviceSet.GetInstallDate() -gt $StartTime) {
            $returnValue = $true
        }
    }
    $returnValue
}


function GetLastWake(
    [DateTime]$StartTime
    )
#
# Function Description:
#     Search the event log for the most recent wake from S3 or S4.
#
# Arguments:
#     $StartTime - Earliest (minimum) event time
#
# Return value:
#     The time of the most recent wake, type [DateTime], or
#     $null if no wake event is found.
#
{
    Get-WinEvent -FilterHashtable @{LogName = "System";
                                    ProviderName = "Microsoft-Windows-Power-Troubleshooter";
                                    Id = 1; # system wake (from S3 or S4)
                                    StartTime = $searchStart;
                                    } |
    Select-Object -first 1 | # newest event
    Select-Object -ExpandProperty "TimeCreated" # get just the time of the event
}


function GetNamesAtRegKey(
    [string]$RegistryPath
    )
#
# Function Description:
#     Get the names of the registry values at this key.
#
# Arguments:
#     $RegistryPath - A registry path as a string, for example "hklm:\system\currentcontrolset"
#                     Caller guarantees that this path exists.
#
# Return value:
#     $null if no values exist at this key, else
#     An array of strings: the names of registry values at this key
#     Warning: Some Powershell property names are also returned.
#     May include "(default)" if that value is set.
#
{
    $regkeyObj = Get-ItemProperty $RegistryPath
    if ($regkeyObj -eq $null) {
        # No values here
        $null # return value
    } else {
        $ret = $regkeyObj |
            Get-Member -MemberType NoteProperty | # Get array of info on object members
            Foreach-Object {$_.Name} # Get names only
                
        @($ret) # return value, ensured to be an array by @()
    }
}


function ConvertTo-Hashtable(
    [Object]$Obj
    )
#
# Function Description:
#     Converts an object's NoteProperty properties to hashtable values.
#     Note there are reasons to use both objects and hashtables:
#         Objects - property names are checked strongly when accessed
#         Hashtables - required for calling Update-DiagRootcause
#
# Arguments:
#     $Obj - An object created by using "New-Object" and "Add-Member NoteProperty"
#
# Return value:
#     A hashtable with a key=>value for each NoteProperty in $Obj.
#
{
    $retHash = New-Object Hashtable
    # Copy each "NoteProperty" property from the object into the hashtable.
    $Obj | Get-Member | Where {$_.MemberType -eq "NoteProperty"} |
        Foreach {
            $propertyName = $_.Name
            $retHash.$propertyName = $Obj.$propertyName
        }
    $retHash # return
}


# Parameters to resolver script must follow this structure (property names must match XML).
$RsParameterTemplate = New-Object System.Management.Automation.PSObject
$RsParameterTemplate | Add-Member NoteProperty -Name DeviceVprString -Value ""
$RsParameterTemplate | Add-Member NoteProperty -Name PortOnParentHub -Value 0
$RsParameterTemplate | Add-Member NoteProperty -Name ParentHubPath -Value ""
$RsParameterTemplate | Add-Member NoteProperty -Name DevinstId -Value ""

# We must always pass "parameters" to Update-DiagRootcause, even if they won't be passed to
# a resolver due to "detected" being false.  In that case use this variable.
# The values stored in the object will be ignored.
$RootcauseNotDetectedParams = ConvertTo-Hashtable $RsParameterTemplate


# Main detection script:

$RootCauseId = $Constants.ResetOnResumeRootcauseId

#
#Try to retrieve Device List from context parameters passed to script.
#
[String]$DevinstIdsSerial = ""

try
{
    # This call returns an array of 1 string but we want a string.
    # Since the variable is explicitly typed as String above, it will
    # store the array's 1 element.
    $DevinstIdsSerial = Get-DiagInput -id "IT_DeviceList"
}
catch
{

}

# Make sure we have a parameter.
if ([String]::IsNullOrEmpty($DevinstIdsSerial))
{
    update-diagrootcause -id $RootCauseId -detected $false -param $RootcauseNotDetectedParams
    return # end script
}

# Make sure UXD isn't enabled.
# (The resolver will change UXD settings and we're being conservative.)
$uxdPolicyPath = $Constants.UxdPath + "\policy" # for global enable
if (Test-Path $uxdPolicyPath) {
    $valueNames = GetNamesAtRegKey $uxdPolicyPath
    if (($valueNames -ne $null) -and ($valueNames -contains $Constants.UxdGlobalEnableName)) {
        # UXD global enable value exists

        $value = (Get-ItemProperty $uxdPolicyPath).($Constants.UxdGlobalEnableName)
        if (0 -ne $value) {
            # UXD global enable is set, don't touch the system.
            update-diagrootcause -id $RootCauseId -detected $false -param $RootcauseNotDetectedParams
            return # end script
        }

    }
}


# Record a USB ETW log while this script runs.
$null = # Suppress console output
    Logman start $Constants.EtwSessionName -p Microsoft-Windows-USB-USBPORT -o $Constants.EtlFileName -ets -nb 128 640 -bs 128
$null = # Suppress console output
    Logman update $Constants.EtwSessionName -p Microsoft-Windows-USB-USBHUB -ets -nb 128 640 -bs 128


# This is a slow query, run it once outside the loop.
$cachedDevices = Get-WmiObject Win32_PnpEntity
$cachedControllers = Get-WmiObject Win32_UsbControllerDevice

# Recover the array of parameters by parsing the serialized parameters.
$devinstIdArray = $DevinstIdsSerial.Split("#")

# Loop over unique device instance IDs.
$devinstIdArray | Select-Object -unique | Foreach-Object {

    $devinstId = $_

    # Skip over devices not enumerated by USB.
    # (notmatch is case-insensitive)
    if ($devinstId -notmatch "^usb") {
        # No loop output for this iteration, go to the next iteration.
        # NOTE "return" here has the effect that "continue" has in a true loop.
        #      "return" here does not end the script (but "continue" would).
        #      This is a quirk of Foreach-Object, which is not a true loop.
        return 
    }

    # Create an object to store data about this devnode, with the following data fields.
    $devnodeData = New-Object System.Management.Automation.PSObject
    $devnodeData | Add-Member NoteProperty -Name DevinstId -Value ""
    $devnodeData | Add-Member NoteProperty -Name Service -Value ""
    $devnodeData | Add-Member NoteProperty -Name VprString -Value ""
    $devnodeData | Add-Member NoteProperty -Name ParentHubId -Value ""
    $devnodeData | Add-Member NoteProperty -Name ParentHubPath -Value ""
    $devnodeData | Add-Member NoteProperty -Name Port -Value 0
    $devnodeData | Add-Member NoteProperty -Name WmiPath -Value ""
    $devnodeData | Add-Member NoteProperty -Name ApplicabilityRule -Value ""
    $devnodeData | Add-Member NoteProperty -Name TsWroteResetOnResume -Value 0
    $devnodeData | Add-Member NoteProperty -Name Description -Value ""

    # For the rest of this block, we fill in the devnode data, making checks along
    # the way to skip the devnode if it's not appropriate for setting ResetOnResume.


    $devnodeData.DevinstId = $devinstId

    # VprString and Service will come from WMI.

    $wmiPnpEntity = $cachedDevices | # get all pnp devices
        Where-Object {$_.DeviceID -eq $devnodeData.DevinstId} | # get the one with this devinst ID
        Select -first 1 # ensure we only get 1 result

    # Device not found in WMI?  Skip it.
    if ($wmiPnpEntity -eq $null) {
        return
    }

    # Record device's WMI path
    $devnodeData.WmiPath = $wmiPnpEntity.__PATH

    # Skip over hubs.
    if ($Constants.HubService -contains $wmiPnpEntity.Service) {
        return
    }
    $devnodeData.Service = $wmiPnpEntity.Service

    # Skip over devices that have no hardware ID.
    if ($wmiPnpEntity.HardwareID -eq $null) {
        return
    }
    # The most verbose hardware ID (contains REV) is in index 0.  Parse it.
    $devnodeData.VprString = GetVprString @($wmiPnpEntity.HardwareID)[0]
    # Skip over devices where we couldn't parse vid,pid,rev
    if ($devnodeData.VprString -eq $null) {
        return
    }

    # Get the device's parent hub id and the device's port on the parent hub.
    $deviceSet = New-Object Microsoft.Windows.Diagnosis.DeviceSet($devnodeData.DevinstId)
    $devnodeData.Port = $deviceSet.GetAddress()
    $devnodeData.ParentHubId = $deviceSet.GetParentId()
    $devnodeData.Description = $deviceSet.GetDescription()

    # Skip the device if anything went wrong in the last step.
    # Note, empirically the step could fail due to a PNP problem on the devnode.
    if (-not($deviceSet.Initialized) -or
        $devnodeData.Port -eq 0 -or
        $devnodeData.ParentHubId -eq ""
        ) {
        return
    }

    # Verify the device's parent is a hub; if not, skip the device.
    $wmiPnpEntity = $cachedDevices |                                          # get all pnp devices
                    Where-Object {$_.DeviceID -eq $devnodeData.ParentHubId} | # get the one with parent's devinst ID
                    Select -first 1                                           # ensure we only get 1 result

    if (($wmiPnpEntity -eq $null) -or ($Constants.HubService -notcontains $wmiPnpEntity.Service)) {
        return
    }

    # Get the hub's path.
    $hubDeviceSet = New-Object Microsoft.Windows.Diagnosis.DeviceSet($devnodeData.ParentHubId)
    $devnodeData.ParentHubPath = $hubDeviceSet.GetHubDevicePath()

    # Skip the device on failure.
    if (-not($hubDeviceSet.Initialized) -or $devnodeData.ParentHubPath -eq "") {
        return
    }


    # At this point we've
    # (a) determined that this devnode is a USB peripheral device, and
    # (b) gathered the data necessary for the resolver.
    # Before emitting $devnodeData and finishing the loop, we check some applicability rules
    # that will prevent the resolution from being executed.  The first applicability rule
    # that is met will be saved to $devnodeData.ApplicabilityRule.
    # Additional variables needed from above: $deviceSet

    # Skip over the device if it already has ResetOnResume set.
    $usbflagsDevicePath = $Constants.UsbflagsPath + "\" + $devnodeData.VprString
    if (Test-Path $usbflagsDevicePath) {
        # ResetOnResume name/data may already exist.  So far we know usbflags subkey exists.
        $valueNames = GetNamesAtRegkey $usbflagsDevicePath
        if (($valueNames -ne $null) -and ($valueNames -contains $Constants.ResetOnResumeName)) {
            # ResetOnResume value exists
            $value = (Get-ItemProperty $usbflagsDevicePath).($Constants.ResetOnResumeName)
            if ($value -is [Byte[]]) {
                # It's a REG_BINARY (required)
                if ($value.count -gt 0 -and $value[0] -ne 0) {

                    # Byte 0 is non-zero (required for ResetOnResume to be effective)
                    # Then ResetOnResume is already set for the device.  Skip it.
                    $devnodeData.ApplicabilityRule = $Constants.ApplicabilityResetOnResumeAlreadySet

                    # We also want to know whether the existing ResetOnResume was set by
                    # this troubleshooter (during an earlier run).
                    if ($valueNames -contains $Constants.TsWroteResetOnResumeName) {
                        $devnodeData.TsWroteResetOnResume = [int] (
                            Get-ItemProperty $usbflagsDevicePath | Select -ExpandProperty $Constants.TsWroteResetOnResumeName
                        )
                        if ($devnodeData.TsWroteResetOnResume -eq 1) {
                            Set-ItemProperty -path $usbflagsDevicePath -name $Constants.TsWroteResetOnResumeName -type Dword -value 0
                        }
                    }
                }
            }
        }
    }

    # Skip over the device if it has UXD settings (even inactive ones), since
    # the resolver will change them.
    if ($devnodeData.ApplicabilityRule -eq "") {
        $uxdDevicesPath = $Constants.UxdPath + "\devices" # for per-device(VPR) UXD settings
        if (Test-Path $uxdDevicesPath) {
            $valueNames = GetNamesAtRegKey $uxdDevicesPath
            if (($valueNames -ne $null) -and ($valueNames -contains $devnodeData.VprString)) {
                $devnodeData.ApplicabilityRule = $Constancs.ApplicabilityUxdSettingsExist
            }
        }
    }

    # Skip the device if, after the last system wake, it (or a descendant) has:
    # (a) been troubleshooted for a driver problem,
    # (b) been installed for the first time, or
    # (c) had a driver update.
    if ($devnodeData.ApplicabilityRule -eq "") {

        # Determine last system system wake time
        $searchStart = (Get-Date) - (New-Timespan -days 14) # limit events to past 14 days
        $wakeTime = GetLastWake -StartTime $searchStart
        if ($wakeTime -eq $null) {
            # Wake event not found.  Assume the system last woke at time $searchStart
            $wakeTime = $searchStart
        }

        $descendantDevices = $deviceSet.GetAllDescendantDevices()
        if (FindRecentDriverProblems -StartTime $wakeTime -DevinstId $descendantDevices) {
            # Condition (a): Recent driver problem found.  Skip the device.
            $devnodeData.ApplicabilityRule = $Constants.ApplicabilityTroubleshootedDriver
        } elseif (FindRecentInstalls -StartTime $wakeTime -DevinstId $descendantDevices) {
            # Condition (b) or (c): Recent device install or driver update found.
            # Skip the device.
            $devnodeData.ApplicabilityRule = $Constants.ApplicabilityDeviceOrDriverInstalled
        }
    }

    # Skip the device if the global ForceHCResetOnResume flag is set.
    # There is one such flag per controller type - usbxhci, usbehci etc.
    if ($devnodeData.ApplicabilityRule -eq "") {

        $wmiControllerAndDevice = $cachedControllers |
                                  Where-Object { $_.Dependent -eq $devnodeData.WmiPath } |
                                  Select -first 1

        if ($wmiControllerAndDevice -ne $null) {

            # Dereference the controller
            $hcDeviceSet = $null # Remains $null if an exception is thrown
            try {
                $wmiHostController = New-Object System.Management.ManagementObject($wmiControllerAndDevice.Antecedent)
                $hcDeviceSet = New-Object Microsoft.Windows.Diagnosis.DeviceSet($wmiHostController.PNPDeviceID)
            } catch {
                $hcDeviceSet = $null
            }

            if (($hcDeviceSet -ne $null) -and $hcDeviceSet.Initialized) {
                if ($hcDeviceSet.GetSoftwareRegValue($Constants.ForceHCResetOnResumeName) -ne 0) {
                    $devnodeData.ApplicabilityRule = $Constants.ApplicabilityGlobalResetOnResumeSet
                }
            }
        }
    }

    # For devices that weren't skipped for any reason, pass their data on as loop output.
    $devnodeData

} | Set-Variable devnodes # loop output goes into $devnodes

# Ensure $devnodes is an array of objects or null.
if ($devnodes -ne $null) {
    $devnodes = @($devnodes)
}

# Record the applicability rules that apply to each USB peripheral device devnode,
# plus TsWroteResetOnResume registry value (pertinent if rule is ResetOnResumeAlreadySet).
$devnodes |
    Select -Property DevinstId,VprString,ApplicabilityRule,TsWroteResetOnResume |
    ConvertTo-Xml |
    Update-DiagReport -Id "ResetOnResumeApplicabilityRules" `
                      -Name $localizationString.ResetOnResumeApplicabilityRules_Name `
                      -Description $localizationString.ResetOnResumeApplicabilityRules_Description `
                      -Verbosity Debug

# Split $devnodes by applicability rule.
if (($devnodes -eq $null) -or ($devnodes.count -eq 0)) {
    $devnodesToApplyResolver = $null
    $devnodesResolved = $null
} else {
    # Those devnodes with no applicability rule set go to the resolver.
    $devnodesToApplyResolver = $devnodes | Where {$_.ApplicabilityRule -eq ""}
    # Those with ResetOnResumeAlreadySet detected have special handling, because that rule
    # is the only rule that is affected by the resolver's action.
    $devnodesResolved = $devnodes | Where {$_.ApplicabilityRule -eq $Constants.ApplicabilityResetOnResumeAlreadySet}
    # The rest of the devnodes have another applicability rule applied and are not further needed.
}

# Before the final determination of root cause detected or not, finish the ETW log.
$null = # Suppress console output
    Logman stop $Constants.EtwSessionName -ets

# Attach the ETW log, but only if we haven't detected any root causes.
if ($devnodesToApplyResolver -eq $null) {
    if (Test-Path $Constants.EtlFileName) {
        Update-DiagReport -File $Constants.EtlFileName `
                          -Id "UsbEtwLog" `
                          -Name $localizationString.UsbEtwLog_Name `
                          -Description $localizationString.UsbEtwLog_Description `
                          -Verbosity Debug
    }
}

# For a Devnode that was potentially just resolved, avoid raising a new rootcause
# instance as "Issue not detected"; instead, update the same instance ID as would
# be used in the "detected" case.
if ($devnodesResolved -ne $null) {

    foreach($devnodeData in $devnodesResolved) {

        $instanceId = GetResetOnResumeInstanceId -VprString $devnodeData.VprString `
                                                 -Port $devnodeData.Port `
                                                 -ParentHubPath $devnodeData.ParentHubPath `
                                                 -DevinstId $devnodeData.DevinstId

        Update-DiagRootcause -id $RootCauseId -detected $false -instanceid $instanceId -param $RootcauseNotDetectedParams
    }
}

# For Devnodes for which a root cause is detected, pass the devnode on to the resolver script.
if ($devnodesToApplyResolver -ne $null) {

    foreach($devnodeData in $devnodesToApplyResolver) {

        # Arrange the parameters for the resolver script.
        $rsParamsObj = $RsParameterTemplate.PSObject.Copy()
        $rsParamsObj.DeviceVprString = $devnodeData.VprString
        $rsParamsObj.PortOnParentHub = $devnodeData.Port
        $rsParamsObj.ParentHubPath = $devnodeData.ParentHubPath
        $rsParamsObj.DevinstId = $devnodeData.DevinstId

        # Parameters must be in a hashtable
        $rsParams = ConvertTo-Hashtable $rsParamsObj

        # The resolver will get called once for each time we call Update-DiagRootcause
        # with a unique rootcause instance ID.
        $instanceId = GetResetOnResumeInstanceId -VprString $rsParamsObj.DeviceVprString `
                                                 -Port $rsParamsObj.PortOnParentHub `
                                                 -ParentHubPath $rsParamsObj.ParentHubPath `
                                                 -DevinstId $rsParamsObj.DevinstId

        Update-DiagRootcause -id $RootCauseId -detected $true -instanceid $instanceId -parameter $rsParams
    }
}

# ResetOnResume resolution did not apply to any of the Devnodes.
# Try the legacy device resolution.
if (($devnodesToApplyResolver -eq $null) -and ($devnodes -ne $null)) {

    foreach($devnodeData in $devnodes) {

        if ($devnodeData.TsWroteResetOnResume -eq 1) {
            continue
        }

        $rootcauseDetected = IsLegacyDeviceOnUSB3 -DeviceInstanceId $DevnodeData.DevinstId  `
                                                  -ParentHubPath $DevnodeData.ParentHubPath `
                                                  -PortNumber $DevnodeData.Port

        $instanceId = GetLegacyDeviceInstanceId -VprString $devnodeData.VprString `
                                                -DevinstId $devnodeData.DevinstId

        Update-DiagRootcause -id $Constants.LegacyDeviceRootcauseId                 `
                             -detected $rootcauseDetected                                  `
                             -instanceid $instanceid                                `
                             -param @{'DeviceDescription'=$devnodeData.Description; 'VprString'=$devnodeData.VprString; 'DeviceInstanceId'=$devnodeData.DevinstId}
    }
}

# No devnodes to send to resolver and none were potentially just resolved.
# Update default root cause instance as not detected.
if ($devnodes -eq $null) {

    Update-DiagRootcause -id $RootCauseId -detected $false -param $RootcauseNotDetectedParams
}
