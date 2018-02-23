# Copyright © 2008, Microsoft Corporation. All rights reserved.

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

Write-DiagProgress -activity $localizationString.mirrorDriver_progress

# function to check whether mirror driver is running or not
function CheckMirrorDriver {
    [string]$sourceCode = @"
using System;
using System.Runtime.InteropServices;
using System.Security.Permissions;

namespace Microsoft.Windows.Diagnosis {
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
    struct DISPLAY_DEVICE {
        public uint cb;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string deviceName;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)]
        public string deviceString;
        public uint stateFlags;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)]
        public string deviceID;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)]
        public string deviceKey;
    }

    static class NativeMethods {
        [DllImport("User32.dll", CharSet = CharSet.Unicode)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool EnumDisplayDevices(string lpDevice, uint iDevNum, ref DISPLAY_DEVICE lpDisplayDevice, uint dwFlags);
    }

    public static class DisplayManager {
        const uint DISPLAY_DEVICE_ACTIVE = 0x00000001;
        const uint DISPLAY_DEVICE_MIRRORING_DRIVER = 0x00000008;


        [EnvironmentPermission(SecurityAction.LinkDemand, Unrestricted = true)]
        public static bool HasMirrorDriver() {
            bool result = false;
            DISPLAY_DEVICE displayDevice = new DISPLAY_DEVICE();
            displayDevice.cb = (uint)Marshal.SizeOf(displayDevice);

            for (uint id = 0; NativeMethods.EnumDisplayDevices(null, id, ref displayDevice, 0); id++) {
                if ((0 != (displayDevice.stateFlags & DISPLAY_DEVICE_ACTIVE)) && (0 != (displayDevice.stateFlags & DISPLAY_DEVICE_MIRRORING_DRIVER))) {
                    result = true;
                }
            }

            return result;
        }
    }
}
"@
    $type = Add-Type -TypeDefinition $sourceCode -PassThru

    return $type[2]::HasMirrorDriver()
}

[bool]$hasMirrorDriver = CheckMirrorDriver
Update-DiagRootcause -ID "RC_MirrorDriver" -Detected $hasMirrorDriver

return -not($hasMirrorDriver)