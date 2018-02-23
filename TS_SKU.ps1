# Copyright © 2008, Microsoft Corporation. All rights reserved.


# Functoin to check whether the current SKU supports Aero
function Check-SupportAeroFeatrue
{
    [string]$source = @"
using System;
using System.Runtime.InteropServices;

static class CheckAeroFeature
{
    const int S_OK = 0;

    static class NativeMethods
    {
        [DllImport("Slc.dll")]
        internal static extern int SLGetWindowsInformationDWORD([MarshalAs(UnmanagedType.LPWStr)]string valueName, out int value);
    }

    public static bool SupportAeroFeature()
    {
        bool result = true;
        int transparencyEnabled = 0;

        if (NativeMethods.SLGetWindowsInformationDWORD("Microsoft-Windows-DesktopWindowManager-Core-TransparencyAllowed", out transparencyEnabled) != S_OK
            || (0 == transparencyEnabled)) {
                result = false;
        }

        return result;
    }
}
"@

    $type = Add-Type -TypeDefinition $source -PassThru

    return $type[0]::SupportAeroFeature()
}

[bool]$result = $false

$result = Check-SupportAeroFeatrue
if(-not($result))
{
    Update-DiagRootcause -id RC_SKUNotSupported -Detected $true
} else {
    Update-DiagRootcause -id RC_SKUNotSupported -Detected $false
}

return $result
