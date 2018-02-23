# Copyright © 2008, Microsoft Corporation. All rights reserved.

# Resolver Script - This script fixes the root cause. It only runs if the Troubleshooter detects the root cause.
# (Troubleshooter may detect the root cause more than once and can cause this script to run more than once)

# Parameters are defined in DiagPackage.diag and are set in rootcause detection script.
PARAM($DeviceVprString, $PortOnParentHub, $ParentHubPath, $DevinstId)

# Warn on improper use of variables, functions
Set-StrictMode -version 2

# All scripts first execute contents of CL_Utility.ps1
. .\CL_Utility.ps1


# Define functions


function GetTimeoutSecondsRemaining(
    [DateTime]$TimeoutTime
    )
#
# Function description:
#     Compute how many seconds are left between now and the specified time.
#
# Arguments:
#     $TimeoutTime - The time from which to subtract the current time
#
# Return value:
#     Integer number of seconds remaining until timeout.  If the timeout has expired,
#     the return value will be 0 or a negative number.
#
{
    # Subtract current time from the timeout time.
    # If the timeout time is in the future, the result will be positive.
    $remainingTimespan = $TimeoutTime - (Get-Date)

    # Convert the Timespan object to seconds units (in floating point).
    $remainingSecondsFloat = $remainingTimespan.TotalSeconds

    # Convert floating point to integer, rounding up.
    [Int]$remainingSecondsInt = [Math]::Ceiling($remainingSecondsFloat)

    $remainingSecondsInt # return value
}


function WaitForRemovalAndEnumeration(
    [String]$RootDevinstId,
    [Int]$DesiredDeviceCount,
    [String]$EventSourceId,
    [DateTime]$TimeoutTime
    )
#
# Function description:
#     Step 1. Wait for a removal event of type Win32_SystemConfigurationChangeEvent.
#     Step 2. Wait until a particular number of devices appear under the device node.
#
# Arguments:
#     $RootDevinstId - The device instance ID of the devnode whose descendants to watch
#     $DesiredDeviceCount - How many devices (including root) should be descendants of
#                           the root before returning
#     $EventSourceId - Event source for all waits.  To ensure events arrive, the caller
#                      should have started the event source before initiating the
#                      asynchronous action that causes removal and re-enumeration.
#                      How the events are used:
#                      Step 1 waits for a removal event, which must be a
#                      Win32_SystemConfigurationChangeEvent of type 3 ("Device Removal").
#                      Step 2 checks the device tree each time another event (of any type)
#                      arrives from this source.
#     $TimeoutTime - Timeout at which time the function must return, regardless of
#                    enumeration progress
#
# Return value:
#     None
#
{
    # Timeout boolean set by first loop
    $timeoutExpired = $false

    # Step 1.  Before we start looking for all the devnodes, wait for a removal event.
    # Thus we won't report all devnodes are present before the cycle port has even begun.
    # Limitation: Any device removal is picked up.
    #             The user could unplug another device, causing the wait to finish early.
    while ($true) {
        # Check the timeout and get the number of seconds to pass to Wait-Event.
        $remainingSeconds = GetTimeoutSecondsRemaining $TimeoutTime
        if ($remainingSeconds -le 0) {
            # Timeout expired.
            # Record that the timeout expired and break.
            $timeoutExpired = $true
            break
        }

        $event = Wait-Event -sourceIdentifier $EventSourceId -Timeout $remainingSeconds
        # $event is now $null if the timeout expired, or it stores the event that arrived.

        if ($event -ne $null) {
            # An event arrived.  Remove it from the queue.
            Remove-Event -EventIdentifier $event.EventIdentifier
            # Read the event.
            if ($event.SourceEventArgs.NewEvent.EventType -eq 3) {
                # Device removal event (EventType -eq 3) occurred, so finish the loop.
                break
            }
        }
    }

    # Step 2.  Now look for all the desired devnodes.
    # If not all are found, repeat whenever any event arrives.
    while ($timeoutExpired -eq $false) {
        # Count current devnodes under $RootDevinstId.
        $deviceSet = New-Object Microsoft.Windows.Diagnosis.DeviceSet($RootDevinstId)
        $deviceCount = $deviceSet.GetAllDescendantDevices().Count
        if ($deviceCount -ge $DesiredDeviceCount) {
            # The device tree under $RootDevinstId has fully re-enumerated,
            # so finish the loop.
            break
        }

        # Check the timeout and get the number of seconds to pass to Wait-Event.
        $remainingSeconds = GetTimeoutSecondsRemaining $TimeoutTime
        if ($remainingSeconds -le 0) {
            # Timeout expired.
            # Record that the timeout expired and break.
            $timeoutExpired = $true
            break
        }

        # See if any event is in the queue or wait for either a device event or timeout.
        # (Then run the loop again.  During the next iteration we'll check the timeout.)
        $null = # suppress output
            Wait-Event -sourceIdentifier $EventSourceId -Timeout $remainingSeconds

        # Remove all queued device arrival events, if any; several could have arrived
        # at once.
        Remove-Event -sourceIdentifier $EventSourceId -ErrorAction SilentlyContinue
    }
}


# Main resolver script:


$usbflagsDevicePath = $Constants.UsbflagsPath + "\$DeviceVprString"
if (-not(Test-Path $usbflagsDevicePath)) {
    # This path doesn't exist, create it.
    $null = # suppress output
        New-Item -path $usbflagsDevicePath -force # -force appears to create intermediate keys
}


# Record that the troubleshooter is the entity setting ResetOnResume
Set-ItemProperty -path $usbflagsDevicePath -name $Constants.TsWroteResetOnResumeName -type Dword -value 1


# Set ResetOnResume.
Set-ItemProperty -path $usbflagsDevicePath -name $Constants.ResetOnResumeName -type Binary -value 1


# Reset the device.
# This step must come after setting ResetOnResume because we also want
# usbhub to pick up the new registry value.


# We are ready to cycle the port.  However, the script should not exit until
# the device tree under the devnode has re-enumerated.
# Store a count of how many devnodes are under the one whose port we will cycle.
$deviceSet = New-Object Microsoft.Windows.Diagnosis.DeviceSet($DevinstId)
$originalDeviceCount = $deviceSet.GetAllDescendantDevices().Count

# WMI query: Start listening for device events before initiating cycle port.
#            This ordering guarantees we will see an event.
# The device removal or arrival event is important because without it, we could not
# distinguish the meaning of "all descendant devnodes are present" (this condition would
# hold during early stages of cycle port as well as after all devices have re-enumerated).
$wmiEventSourceId = "USBTS Enumeration WMI" # source ID for all events that will come
Register-WmiEvent -class Win32_SystemConfigurationChangeEvent `
                  -sourceIdentifier $wmiEventSourceId


# Cycle the device's port.
# This operation is asynchronous.
$cycle = New-Object Microsoft.Windows.Diagnosis.CyclePort($ParentHubPath, $PortOnParentHub)
$null = # suppress output
    $cycle.Send()


# Wait for the devnodes to come back before exiting the script.
# This wait reduces the impact of the resolver on other troubleshooter scripts.
# The USB devnode should have the same device instance ID when it comes back.  Since
# descendant devnodes may come back with changed device instance IDs, wait until the USB
# devnode has the same number of descendants as it started with.
# Limitation: It's possible that the final number of descendant devnodes after the port
#             cycle will be different from the current number.
#             If there are more after the port cycle, we may exit early.
#             If there are less after the port cycle, we will time out.
$timeout = (Get-Date) + (New-Timespan -seconds 8)
WaitForRemovalAndEnumeration -RootDevinstId $DevinstId `
                             -DesiredDeviceCount $originalDeviceCount `
                             -EventSourceId $wmiEventSourceId `
                             -TimeoutTime $timeout

# Event cleanup
Unregister-Event -sourceIdentifier $wmiEventSourceId
Remove-Event -sourceIdentifier $wmiEventSourceId -ErrorAction SilentlyContinue
