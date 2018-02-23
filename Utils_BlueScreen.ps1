# Copyright © 2016, Microsoft Corporation. All rights reserved.
# :: ======================================================= ::

<#
	DESCRIPTION:
	  Utils_BlueScreen.ps1 is used as common scripts by Blue Screen Troubleshooter 
	  which contains functionalities related to Blue Screen
#>

#====================================================================================
# Initialize
#====================================================================================
Import-LocalizedData -BindingVariable LocalizedStrings -FileName CL_LocalizationData

#====================================================================================
# Main
#====================================================================================

# List of Known BugChecks by type
$knownBugChecks = @{}
$knownBugChecks.Add("0x00000124","ProblemDriver") #https://msdn.microsoft.com/en-us/library/windows/hardware/ff557321(v=vs.85).aspx
$knownBugChecks.Add("0x00000113","ProblemDriver") #https://msdn.microsoft.com/en-us/library/windows/hardware/ff557253(v=vs.85).aspx
$knownBugChecks.Add("0x0000007E","ProblemDriver") #https://msdn.microsoft.com/en-us/library/windows/hardware/ff559239(v=vs.85).aspx
$knownBugChecks.Add("0x0000003B","ProblemDriver") #https://msdn.microsoft.com/en-us/library/windows/hardware/ff558949(v=vs.85).aspx
$knownBugChecks.Add("0x0000004E","ProblemDriver") #https://msdn.microsoft.com/en-us/library/windows/hardware/ff559014(v=vs.85).aspx
$knownBugChecks.Add("0x0000001E","ProblemDriver") #https://msdn.microsoft.com/en-us/library/windows/hardware/ff557408(v=vs.85).aspx
$knownBugChecks.Add("0x000000E1","ProblemDriver") #https://msdn.microsoft.com/en-us/library/windows/hardware/ff560322(v=vs.85).aspx
$knownBugChecks.Add("0x00000139","ProblemDriver") #https://msdn.microsoft.com/en-us/library/windows/hardware/jj569891(v=vs.85).aspx
$knownBugChecks.Add("0x000000D1","ProblemDriver") #https://msdn.microsoft.com/en-us/library/windows/hardware/ff560244(v=vs.85).aspx
$knownBugChecks.Add("0x00000133","ProblemDriver") #https://msdn.microsoft.com/en-us/library/windows/hardware/jj154556(v=vs.85).aspx
$knownBugChecks.Add("0x00000109","ProblemDriver") #https://msdn.microsoft.com/en-us/library/windows/hardware/ff557228(v=vs.85).aspx
$knownBugChecks.Add("0x00000019","ProblemDriver") #https://msdn.microsoft.com/en-us/library/windows/hardware/ff557389(v=vs.85).aspx
$knownBugChecks.Add("0x000000C2","ProblemDriver") #https://msdn.microsoft.com/en-us/library/windows/hardware/ff560185(v=vs.85).aspx

$knownBugChecks.Add("0x00000050","Malware") #https://msdn.microsoft.com/en-us/library/windows/hardware/ff559023(v=vs.85).aspx
$knownBugChecks.Add("0x0000007A","Malware") #https://msdn.microsoft.com/en-us/library/windows/hardware/ff559211(v=vs.85).aspx
$knownBugChecks.Add("0x000000F7","Malware") #https://msdn.microsoft.com/en-us/library/windows/hardware/ff560389(v=vs.85).aspx
$knownBugChecks.Add("0xC000021A","Malware") #https://msdn.microsoft.com/en-us/library/windows/hardware/ff560177(v=vs.85).aspx

$knownBugChecks.Add("0x00000024","DiskFailure") #https://msdn.microsoft.com/en-us/library/windows/hardware/ff557433(v=vs.85).aspx
#$knownBugChecks.Add("0x0000007A","DiskFailure") #https://msdn.microsoft.com/en-us/library/windows/hardware/ff559211(v=vs.85).aspx

$knownBugChecks.Add("0x0000007F","MemoryFailure") #https://msdn.microsoft.com/en-us/library/windows/hardware/ff559211(v=vs.85).aspx
#$knownBugChecks.Add("0x0000007A","MemoryFailure") #https://msdn.microsoft.com/en-us/library/windows/hardware/ff559211(v=vs.85).aspx
#$knownBugChecks.Add("0x00000109","MemoryFailure") #https://msdn.microsoft.com/en-us/library/windows/hardware/ff557389(v=vs.85).aspx

$knownBugChecks.Add("0x00000101","BadHardware") #https://msdn.microsoft.com/en-us/library/windows/hardware/ff557211(v=vs.85).aspx
#$knownBugChecks.Add("0x00000124","BadHardware") #https://msdn.microsoft.com/en-us/library/windows/hardware/ff557321(v=vs.85).aspx
#$knownBugChecks.Add("0x0000007F","BadHardware") #https://msdn.microsoft.com/en-us/library/windows/hardware/ff559211(v=vs.85).aspx
#$knownBugChecks.Add("0x00000050","BadHardware") #https://msdn.microsoft.com/en-us/library/windows/hardware/ff559023(v=vs.85).aspx
#$knownBugChecks.Add("0x0000001E","BadHardware") #https://msdn.microsoft.com/en-us/library/windows/hardware/ff557408(v=vs.85).aspx

#$knownBugChecks.Add("0x00000050","ProblemService") #https://msdn.microsoft.com/en-us/library/windows/hardware/ff559023(v=vs.85).aspx
#$knownBugChecks.Add("0x0000001E","ProblemService") #https://msdn.microsoft.com/en-us/library/windows/hardware/ff557408(v=vs.85).aspx

#*=================================================================================
#Functions to interact with Drivers
#*=================================================================================
Function Get-DriverSource
{
    <#
        .DESCRIPTION
           Function get driver resources of the specific device on 64 bit OS
        .PARAMETER 
			None
        .OUTPUTS
            Returns data type of get driver resources
    #>
     $ChangeDriverSource = @"
using System;
using System.Runtime.InteropServices;
namespace Microsoft.Windows.Diagnosis
{
    public static class ChangeDriver
    {
        public enum DIOD
        {
            None = (0),
            CANCEL_REMOVE = (0x00000004),
            // If this flag is specified and the device had been marked for pending removal, the OS cancels the pending removal. 
            INHERIT_CLASSDRVS = (0x00000002)
            //the resulting device information element inherits the class driver list, if any
        }

        public enum DICD
        {
            None = (0),
            GENERATE_ID = (0x00000001), // create unique device instance key
            INHERIT_CLASSDRVS = (0x00000002)  // inherit class driver list
        }

        public enum SPDIT
        {
            None = (0),
            SPDIT_COMPATDRIVER = (0x00000002), // Build a list of compatible drivers
            SPDIT_CLASSDRIVER = (0x00000001)  // Build a list of class drivers
        }

        public enum DI_FLAGS
        {
             DI_FLAGSEX_INSTALLEDDRIVER = (0x04000000),
             DI_FLAGSEX_ALLOWEXCLUDEDDRVS = (0x00000800)
        }

        [StructLayout(LayoutKind.Sequential)]
        public class SP_DEVINFO_DATA
        {
            /// <summary>
            /// Size of the structure, in bytes. 
            /// </summary>
            public Int32 cbSize = Marshal.SizeOf(typeof(SP_DEVINFO_DATA));

            /// <summary>
            /// GUID of the device interface class. 
            /// </summary>
            public Guid ClassGuid;

            /// <summary>
            /// Handle to this device instance. 
            /// </summary>
            public Int32 DevInst;

            /// <summary>
            /// Reserved; do not use. 
            /// </summary>
            public IntPtr Reserved;
        }
        // 64 bit: Pack=4
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode, Pack=4)]
        public class SP_DRVINFO_DATA
        {
            public Int32 cbSize;
            public Int32 DriverType;
            public IntPtr Reserved;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)]
            public String Description;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)]
            public String MfgName;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)]
            public String ProviderName;
            public System.Runtime.InteropServices.ComTypes.FILETIME DriverDate;
            public Int64 DriverVersion;
        }
        // 64 bit: Pack=8
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode, Pack = 8)]
        public class SP_DRVINFO_DETAIL_DATA
        {
            public Int32 cbSize;
            public System.Runtime.InteropServices.ComTypes.FILETIME InfDate;
            public Int32 CompatIDsOffset;
            public Int32 CompatIDsLength;
            public IntPtr Reserved;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)]
            public string SectionName;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)]
            public string InfFileName;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)]
            public string DrvDescription;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 1)]
            public string HardwareID;
        }
        // 64 bit: Pack=8
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode, Pack = 8)]
        public class SP_DEVINSTALL_PARAMS
        {
            public Int32 cbSize;
            public Int32 Flags;
            public DI_FLAGS FlagsEx;
            public IntPtr hwndParent;
            public IntPtr InstallMsgHandler;
            public IntPtr InstallMsgHandlerContext;
            public IntPtr FileQueue;
            public UIntPtr ClassInstallReserved;
            public Int32 Reserved;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)]
            public string DriverPath;
        }

        [DllImport("Setupapi.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern bool SetupDiOpenDeviceInfo(
            IntPtr DeviceInfoSet,
            string device,
            IntPtr handleToWindow,
            DIOD flag,
            SP_DEVINFO_DATA deviceInfoData
            );
        [DllImport("Setupapi.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public extern static IntPtr SetupDiCreateDeviceInfoList
            (
            IntPtr ClassGuid,
            IntPtr hwndParent
            );
        [DllImport("Setupapi.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern bool SetupDiBuildDriverInfoList(
            IntPtr DeviceInfoSet,
            SP_DEVINFO_DATA DeviceInfoData,
            SPDIT DriverType
            );
        [DllImport("Setupapi.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern bool SetupDiEnumDriverInfo(
            IntPtr DeviceInfoSet,
            SP_DEVINFO_DATA DeviceInfoData,
            SPDIT DriverType,
            int MemberIndex,
            [In, Out] SP_DRVINFO_DATA DriverInfoData
            );
        [DllImport("Setupapi.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern bool SetupDiGetDriverInfoDetail(
            IntPtr DeviceInfoSet,
            SP_DEVINFO_DATA DeviceInfoData,
            SP_DRVINFO_DATA DriverInfoData,
            [In, Out] SP_DRVINFO_DETAIL_DATA DriverInfoDetailData,
            int DriverInfoDetailDataSize,
            out int RequiredSize
            );
        [DllImport("Setupapi.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern bool SetupDiSetDeviceInstallParams(
            IntPtr DeviceInfoSet,
            SP_DEVINFO_DATA DeviceInfoData,
            SP_DEVINSTALL_PARAMS DeviceInstallParams
            );
        [DllImport("Newdev.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern bool DiInstallDevice(
            IntPtr hwndParent,
            IntPtr DeviceInfoSet,
            SP_DEVINFO_DATA DeviceInfoData,
            SP_DRVINFO_DATA DriverInfoData,
            int Flags,
            out bool rebootRequired            
            );
         [DllImport("Newdev.dll", SetLastError = true, CharSet = CharSet.Unicode)]
         public static extern bool DiRollbackDriver(
            IntPtr DeviceInfoSet,
            SP_DEVINFO_DATA DeviceInfoData,
            IntPtr hwndParent,
            int Flags,
            out bool rebootRequired            
            );

        public static int RollBackDriver(string deviceId)
        {
            int error = 0;
            IntPtr hDevSet = SetupDiCreateDeviceInfoList(IntPtr.Zero, IntPtr.Zero);
            SP_DEVINFO_DATA deviceInfoData = new SP_DEVINFO_DATA();
            bool bRet = SetupDiOpenDeviceInfo(hDevSet, deviceId, IntPtr.Zero, 0, deviceInfoData);
            if (bRet == false)
            {
                return Marshal.GetLastWin32Error();
            }

            bRet = SetupDiBuildDriverInfoList(hDevSet, deviceInfoData, SPDIT.SPDIT_COMPATDRIVER);
            if (bRet == false)
            {
                return Marshal.GetLastWin32Error();
            }
            bool bReboot = false;
            bRet = DiRollbackDriver(hDevSet, deviceInfoData, IntPtr.Zero, 0, out bReboot);
            if (bRet == false)
            {
                error = Marshal.GetLastWin32Error();
                return error;
            }
            else
            {
                return 0;
            }
        }

        public static int ForceInstallDriver(string deviceId, string infPath)
        {
            int error = 0;
            IntPtr hDevSet = SetupDiCreateDeviceInfoList(IntPtr.Zero, IntPtr.Zero);
            SP_DEVINFO_DATA deviceInfoData = new SP_DEVINFO_DATA();
            bool bRet = SetupDiOpenDeviceInfo(hDevSet, deviceId, IntPtr.Zero, 0, deviceInfoData);
            if (bRet == false)
            {
                return Marshal.GetLastWin32Error();
            }

            bRet = SetupDiBuildDriverInfoList(hDevSet, deviceInfoData, SPDIT.SPDIT_COMPATDRIVER);
            if (bRet == false)
            {
                return Marshal.GetLastWin32Error();
            }
            int driverItr = 0;
            bool bResult = true;
            while (bResult)
            {
                SP_DRVINFO_DATA driverInfoData = new SP_DRVINFO_DATA();
                driverInfoData.cbSize = Marshal.SizeOf(typeof(SP_DRVINFO_DATA));
                bRet = SetupDiEnumDriverInfo(hDevSet, deviceInfoData, SPDIT.SPDIT_COMPATDRIVER, driverItr, driverInfoData);
                if (bRet == false)
                {
                    return Marshal.GetLastWin32Error();
                }

                int requiredSize = 0;
                SP_DRVINFO_DETAIL_DATA driverInfoDetailData = new SP_DRVINFO_DETAIL_DATA();
                driverInfoDetailData.cbSize = Marshal.SizeOf(typeof(SP_DRVINFO_DETAIL_DATA));
                int dataSize = Marshal.SizeOf(driverInfoDetailData);

                bRet = SetupDiGetDriverInfoDetail(hDevSet, deviceInfoData, driverInfoData, driverInfoDetailData, dataSize, out requiredSize);
                if (bRet == false)
                {
                    error = Marshal.GetLastWin32Error();
                    //122 - ERROR_INSUFFICIENT_BUFFER, expected error
                    if (error != 122)
                    {
                        Marshal.GetLastWin32Error();
                    }
                }

                if (driverInfoDetailData.InfFileName != null && driverInfoDetailData.InfFileName.Contains(infPath))
                {
                    bool bReboot = false;
                    bRet = DiInstallDevice(IntPtr.Zero, hDevSet, deviceInfoData, driverInfoData, 0, out bReboot);
                    if (bRet == false)
                    {
                        error = Marshal.GetLastWin32Error();
                        driverItr++;
                        continue;
                    }
                    else
                    {
                        return 0;
                    }
                }
                driverItr++;
            }
            return -1;
        }

        public static string GetCurrentDriverINF(string deviceId)
        {
            string infPath = "ErrorFindingINF";
            int error = 0;
            IntPtr hDevSet = SetupDiCreateDeviceInfoList(IntPtr.Zero, IntPtr.Zero);
            SP_DEVINFO_DATA deviceInfoData = new SP_DEVINFO_DATA();

            bool bRet = SetupDiOpenDeviceInfo(hDevSet, deviceId, IntPtr.Zero, 0, deviceInfoData);
            if (bRet == false)
            {
                error = Marshal.GetLastWin32Error();
                return infPath;
            }

            // Get Currently Installed Driver
            SP_DEVINSTALL_PARAMS deviceInstallParams = new SP_DEVINSTALL_PARAMS();
            deviceInstallParams.cbSize = Marshal.SizeOf(typeof(SP_DEVINSTALL_PARAMS));
            deviceInstallParams.FlagsEx = DI_FLAGS.DI_FLAGSEX_ALLOWEXCLUDEDDRVS | DI_FLAGS.DI_FLAGSEX_INSTALLEDDRIVER;
            bRet = SetupDiSetDeviceInstallParams(hDevSet, deviceInfoData, deviceInstallParams);
            if (bRet == false)
            {
                error = Marshal.GetLastWin32Error();
                return infPath;
            }

            bRet = SetupDiBuildDriverInfoList(hDevSet, deviceInfoData, SPDIT.SPDIT_COMPATDRIVER);
            if (bRet == false)
            {
                error = Marshal.GetLastWin32Error();
                return infPath;
            }
            int driverItr = 0;
           
            SP_DRVINFO_DATA driverInfoData = new SP_DRVINFO_DATA();
            driverInfoData.cbSize = Marshal.SizeOf(typeof(SP_DRVINFO_DATA));
            bRet = SetupDiEnumDriverInfo(hDevSet, deviceInfoData, SPDIT.SPDIT_COMPATDRIVER, driverItr, driverInfoData);
            if (bRet == false)
            {
                error = Marshal.GetLastWin32Error();
                return infPath;
            }
            int requiredSize = 0;
            SP_DRVINFO_DETAIL_DATA driverInfoDetailData = new SP_DRVINFO_DETAIL_DATA();
            driverInfoDetailData.cbSize = Marshal.SizeOf(typeof(SP_DRVINFO_DETAIL_DATA));
            int dataSize = Marshal.SizeOf(driverInfoDetailData);
            // First get the required size
            bRet = SetupDiGetDriverInfoDetail(hDevSet, deviceInfoData, driverInfoData, driverInfoDetailData, dataSize, out requiredSize);
            if (bRet == false)
            {
                error = Marshal.GetLastWin32Error();
                //122 - ERROR_INSUFFICIENT_BUFFER, expected error
                if (error != 122)
                {
                    return infPath;
                }
            }

            if (driverInfoDetailData.InfFileName != null)
            {
                infPath = driverInfoDetailData.InfFileName;
            }
            return infPath;
        }
    }
}
"@
    Add-Type -TypeDefinition $ChangeDriverSource
    $driverSource = [Microsoft.Windows.Diagnosis.ChangeDriver]
    return $driverSource
}

Function Get-DriverSource32
{
    <#
        .DESCRIPTION
           Function get driver resources of the specific device on 32 bit OS
        .PARAMETER 
			None
        .OUTPUTS
            Returns data type of get driver resources
    #>
     $ChangeDriverSource32 = @"
using System;
using System.Runtime.InteropServices;
namespace Microsoft.Windows.Diagnosis
{
    public static class ChangeDriver32
    {
        public enum DIOD
        {
            None = (0),
            CANCEL_REMOVE = (0x00000004),
            // If this flag is specified and the device had been marked for pending removal, the OS cancels the pending removal. 
            INHERIT_CLASSDRVS = (0x00000002)
            //the resulting device information element inherits the class driver list, if any
        }

        public enum DICD
        {
            None = (0),
            GENERATE_ID = (0x00000001), // create unique device instance key
            INHERIT_CLASSDRVS = (0x00000002)  // inherit class driver list
        }

        public enum SPDIT
        {
            None = (0),
            SPDIT_COMPATDRIVER = (0x00000002), // Build a list of compatible drivers
            SPDIT_CLASSDRIVER = (0x00000001)  // Build a list of class drivers
        }

        public enum DI_FLAGS
        {
             DI_FLAGSEX_INSTALLEDDRIVER = (0x04000000),
             DI_FLAGSEX_ALLOWEXCLUDEDDRVS = (0x00000800)
        }

        [StructLayout(LayoutKind.Sequential)]
        public class SP_DEVINFO_DATA
        {
            /// <summary>
            /// Size of the structure, in bytes. 
            /// </summary>
            public Int32 cbSize = Marshal.SizeOf(typeof(SP_DEVINFO_DATA));

            /// <summary>
            /// GUID of the device interface class. 
            /// </summary>
            public Guid ClassGuid;

            /// <summary>
            /// Handle to this device instance. 
            /// </summary>
            public Int32 DevInst;

            /// <summary>
            /// Reserved; do not use. 
            /// </summary>
            public IntPtr Reserved;
        }
        // 64 bit: Pack=4
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode, Pack=1)]
        public class SP_DRVINFO_DATA
        {
            public Int32 cbSize;
            public Int32 DriverType;
            public IntPtr Reserved;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)]
            public String Description;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)]
            public String MfgName;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)]
            public String ProviderName;
            public System.Runtime.InteropServices.ComTypes.FILETIME DriverDate;
            public Int64 DriverVersion;
        }
        // 64 bit: Pack=8
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode, Pack = 1)]
        public class SP_DRVINFO_DETAIL_DATA
        {
            public Int32 cbSize;
            public System.Runtime.InteropServices.ComTypes.FILETIME InfDate;
            public Int32 CompatIDsOffset;
            public Int32 CompatIDsLength;
            public IntPtr Reserved;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)]
            public string SectionName;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)]
            public string InfFileName;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)]
            public string DrvDescription;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 1)]
            public string HardwareID;
        }
        // 64 bit: Pack=8
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode, Pack = 4)]
        public class SP_DEVINSTALL_PARAMS
        {
            public Int32 cbSize;
            public Int32 Flags;
            public DI_FLAGS FlagsEx;
            public IntPtr hwndParent;
            public IntPtr InstallMsgHandler;
            public IntPtr InstallMsgHandlerContext;
            public IntPtr FileQueue;
            public UIntPtr ClassInstallReserved;
            public Int32 Reserved;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)]
            public string DriverPath;
        }

        [DllImport("Setupapi.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern bool SetupDiOpenDeviceInfo(
            IntPtr DeviceInfoSet,
            string device,
            IntPtr handleToWindow,
            DIOD flag,
            SP_DEVINFO_DATA deviceInfoData
            );
        [DllImport("Setupapi.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public extern static IntPtr SetupDiCreateDeviceInfoList
            (
            IntPtr ClassGuid,
            IntPtr hwndParent
            );
        [DllImport("Setupapi.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern bool SetupDiBuildDriverInfoList(
            IntPtr DeviceInfoSet,
            SP_DEVINFO_DATA DeviceInfoData,
            SPDIT DriverType
            );
        [DllImport("Setupapi.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern bool SetupDiEnumDriverInfo(
            IntPtr DeviceInfoSet,
            SP_DEVINFO_DATA DeviceInfoData,
            SPDIT DriverType,
            int MemberIndex,
            [In, Out] SP_DRVINFO_DATA DriverInfoData
            );
        [DllImport("Setupapi.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern bool SetupDiGetDriverInfoDetail(
            IntPtr DeviceInfoSet,
            SP_DEVINFO_DATA DeviceInfoData,
            SP_DRVINFO_DATA DriverInfoData,
            [In, Out] SP_DRVINFO_DETAIL_DATA DriverInfoDetailData,
            int DriverInfoDetailDataSize,
            out int RequiredSize
            );
        [DllImport("Setupapi.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern bool SetupDiSetDeviceInstallParams(
            IntPtr DeviceInfoSet,
            SP_DEVINFO_DATA DeviceInfoData,
            SP_DEVINSTALL_PARAMS DeviceInstallParams
            );
        [DllImport("Newdev.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern bool DiInstallDevice(
            IntPtr hwndParent,
            IntPtr DeviceInfoSet,
            SP_DEVINFO_DATA DeviceInfoData,
            SP_DRVINFO_DATA DriverInfoData,
            int Flags,
            out bool rebootRequired            
            );
         [DllImport("Newdev.dll", SetLastError = true, CharSet = CharSet.Unicode)]
         public static extern bool DiRollbackDriver(
            IntPtr DeviceInfoSet,
            SP_DEVINFO_DATA DeviceInfoData,
            IntPtr hwndParent,
            int Flags,
            out bool rebootRequired            
            );

        public static int RollBackDriver(string deviceId)
        {
            int error = 0;
            IntPtr hDevSet = SetupDiCreateDeviceInfoList(IntPtr.Zero, IntPtr.Zero);
            SP_DEVINFO_DATA deviceInfoData = new SP_DEVINFO_DATA();
            bool bRet = SetupDiOpenDeviceInfo(hDevSet, deviceId, IntPtr.Zero, 0, deviceInfoData);
            if (bRet == false)
            {
                return Marshal.GetLastWin32Error();
            }

            bRet = SetupDiBuildDriverInfoList(hDevSet, deviceInfoData, SPDIT.SPDIT_COMPATDRIVER);
            if (bRet == false)
            {
                return Marshal.GetLastWin32Error();
            }
            bool bReboot = false;
            bRet = DiRollbackDriver(hDevSet, deviceInfoData, IntPtr.Zero, 0, out bReboot);
            if (bRet == false)
            {
                error = Marshal.GetLastWin32Error();
                return error;
            }
            else
            {
                return 0;
            }
        }

        public static int ForceInstallDriver(string deviceId, string infPath)
        {
            int error = 0;
            IntPtr hDevSet = SetupDiCreateDeviceInfoList(IntPtr.Zero, IntPtr.Zero);
            SP_DEVINFO_DATA deviceInfoData = new SP_DEVINFO_DATA();
            bool bRet = SetupDiOpenDeviceInfo(hDevSet, deviceId, IntPtr.Zero, 0, deviceInfoData);
            if (bRet == false)
            {
                return Marshal.GetLastWin32Error();
            }

            bRet = SetupDiBuildDriverInfoList(hDevSet, deviceInfoData, SPDIT.SPDIT_COMPATDRIVER);
            if (bRet == false)
            {
                return Marshal.GetLastWin32Error();
            }
            int driverItr = 0;
            bool bResult = true;
            while (bResult)
            {
                SP_DRVINFO_DATA driverInfoData = new SP_DRVINFO_DATA();
                driverInfoData.cbSize = Marshal.SizeOf(typeof(SP_DRVINFO_DATA));
                bRet = SetupDiEnumDriverInfo(hDevSet, deviceInfoData, SPDIT.SPDIT_COMPATDRIVER, driverItr, driverInfoData);
                if (bRet == false)
                {
                    return Marshal.GetLastWin32Error();
                }

                int requiredSize = 0;
                SP_DRVINFO_DETAIL_DATA driverInfoDetailData = new SP_DRVINFO_DETAIL_DATA();
                driverInfoDetailData.cbSize = Marshal.SizeOf(typeof(SP_DRVINFO_DETAIL_DATA));
                int dataSize = Marshal.SizeOf(driverInfoDetailData);

                bRet = SetupDiGetDriverInfoDetail(hDevSet, deviceInfoData, driverInfoData, driverInfoDetailData, dataSize, out requiredSize);
                if (bRet == false)
                {
                    error = Marshal.GetLastWin32Error();
                    //122 - ERROR_INSUFFICIENT_BUFFER, expected error
                    if (error != 122)
                    {
                        Marshal.GetLastWin32Error();
                    }
                }

                if (driverInfoDetailData.InfFileName != null && driverInfoDetailData.InfFileName.Contains(infPath))
                {
                    bool bReboot = false;
                    bRet = DiInstallDevice(IntPtr.Zero, hDevSet, deviceInfoData, driverInfoData, 0, out bReboot);
                    if (bRet == false)
                    {
                        error = Marshal.GetLastWin32Error();
                        driverItr++;
                        continue;
                    }
                    else
                    {
                        return 0;
                    }
                }
                driverItr++;
            }
            return -1;
        }

        public static string GetCurrentDriverINF(string deviceId)
        {
            string infPath = "ErrorFindingINF";
            int error = 0;
            IntPtr hDevSet = SetupDiCreateDeviceInfoList(IntPtr.Zero, IntPtr.Zero);
            SP_DEVINFO_DATA deviceInfoData = new SP_DEVINFO_DATA();

            bool bRet = SetupDiOpenDeviceInfo(hDevSet, deviceId, IntPtr.Zero, 0, deviceInfoData);
            if (bRet == false)
            {
                error = Marshal.GetLastWin32Error();
                return infPath;
            }

            // Get Currently Installed Driver
            SP_DEVINSTALL_PARAMS deviceInstallParams = new SP_DEVINSTALL_PARAMS();
            deviceInstallParams.cbSize = Marshal.SizeOf(typeof(SP_DEVINSTALL_PARAMS));
            deviceInstallParams.FlagsEx = DI_FLAGS.DI_FLAGSEX_ALLOWEXCLUDEDDRVS | DI_FLAGS.DI_FLAGSEX_INSTALLEDDRIVER;
            bRet = SetupDiSetDeviceInstallParams(hDevSet, deviceInfoData, deviceInstallParams);
            if (bRet == false)
            {
                error = Marshal.GetLastWin32Error();
                return infPath;
            }

            bRet = SetupDiBuildDriverInfoList(hDevSet, deviceInfoData, SPDIT.SPDIT_COMPATDRIVER);
            if (bRet == false)
            {
                error = Marshal.GetLastWin32Error();
                return infPath;
            }
            int driverItr = 0;
           
            SP_DRVINFO_DATA driverInfoData = new SP_DRVINFO_DATA();
            driverInfoData.cbSize = Marshal.SizeOf(typeof(SP_DRVINFO_DATA));
            bRet = SetupDiEnumDriverInfo(hDevSet, deviceInfoData, SPDIT.SPDIT_COMPATDRIVER, driverItr, driverInfoData);
            if (bRet == false)
            {
                error = Marshal.GetLastWin32Error();
                return infPath;
            }
            int requiredSize = 0;
            SP_DRVINFO_DETAIL_DATA driverInfoDetailData = new SP_DRVINFO_DETAIL_DATA();
            driverInfoDetailData.cbSize = Marshal.SizeOf(typeof(SP_DRVINFO_DETAIL_DATA));
            int dataSize = Marshal.SizeOf(driverInfoDetailData);
            // First get the required size
            bRet = SetupDiGetDriverInfoDetail(hDevSet, deviceInfoData, driverInfoData, driverInfoDetailData, dataSize, out requiredSize);
            if (bRet == false)
            {
                error = Marshal.GetLastWin32Error();
                //122 - ERROR_INSUFFICIENT_BUFFER, expected error
                if (error != 122)
                {
                    return infPath;
                }
            }

            if (driverInfoDetailData.InfFileName != null)
            {
                infPath = driverInfoDetailData.InfFileName;
            }
            return infPath;
        }
    }
}
"@
    Add-Type -TypeDefinition $ChangeDriverSource32
    $driverSource = [Microsoft.Windows.Diagnosis.ChangeDriver32]
    return $driverSource
}


#*=================================================================================
#Get BugCheck Type
#*=================================================================================
function Get-BugCheckType()
{
	<#
		.DESCRIPTION:
		  Checks STOP/BugCheck Codes in knownIssues List and returns Type

		.INPUTS:
		  String errorcode
		
		.OUTPUTS:
		  String type
	#>
	param([String]$errorcode)
	$type = "Unknown"

	if($knownBugChecks.ContainsKey($errorcode)){
		$type = $knownBugChecks[$errorcode]
	}

	$type
}

#*=================================================================================
#Arm Compression code
#*=================================================================================
Function GetARMCompression()
{
$str = @'
using System;
using System.Collections.Generic;

using System.Text;
using System.IO;
using System.Diagnostics;
using System.IO.Compression;

	 namespace Compressions
	 {
		 public class OutputDataPackage
		 {
			 string fileName;
			 ZipArchive z;
			 FileStream fileStream;
			 ZipArchiveEntry zae;
			 public string FileName
			 {
				 get
				 {
					 return fileName;
				 }
			 }


			 public OutputDataPackage()
			 {
				 string dt = String.Format("{0:yyyy-MM-dd_hh-mm-ss}", DateTime.Now);
				 string filePath = Environment.GetFolderPath(Environment.SpecialFolder.Desktop);
				 fileName = filePath +@"\RoamingLog"+dt+".zip";

				 fileStream = new FileStream(fileName, FileMode.Create);

				 z = new ZipArchive(fileStream, ZipArchiveMode.Create);

			 }

			 public OutputDataPackage(string outputPackagePath)
			 {
				 DateTime dt = DateTime.Now;
				 this.fileName = outputPackagePath;
				 fileStream = new FileStream(this.fileName, FileMode.Create);
				 z = new ZipArchive(fileStream, ZipArchiveMode.Create);
			 }

			 public OutputDataPackage(string outputPackagePath,bool overwrite)
			 {
				if(overwrite)
				{
					 DateTime dt = DateTime.Now;
					 this.fileName = outputPackagePath;
					 fileStream = new FileStream(this.fileName, FileMode.Create);
					 z = new ZipArchive(fileStream, ZipArchiveMode.Create);
				 }
           			 else
            			{
                			DateTime dt = DateTime.Now;
                			this.fileName = outputPackagePath;
                			fileStream = new FileStream(this.fileName, FileMode.OpenOrCreate);
                			z = new ZipArchive(fileStream, ZipArchiveMode.Update);
            			}
			 }
			 // Add a file to the package using the specified path on disk and path in package
			 //   Example call: "outputPackage.AddFile("temp.txt", new Uri("/temp.txt", UriKind.RelativeOrAbsolute));"
			 //
			 public void AddFile(String pathOnDisk, String pathInZip)
			 {

				 zae = z.CreateEntry(pathInZip, CompressionLevel.Fastest);
				 FileStream fs = new FileStream(pathOnDisk, FileMode.Open, FileAccess.Read);
				 using (Stream s = zae.Open())
				 {
					 fs.CopyTo(s);
				 }

				 fs.Close();

			 }

			 // Saves the package out
			 public void Close()
			 {
				 z.Dispose();

			 }


		 }
	 }
'@

	add-type $str -ReferencedAssemblies "System.IO.Compression"

}
#*=================================================================================
#ARM-Zip
#Params $srcdir,$destDir - Works on all Win 8 including ARM
#*=================================================================================
Function ARM-Zip()
{
	param([string]$srcdir,$destDir)
	GetARMCompression
	$obj = new-object Compressions.OutputDataPackage($destDir)
	get-childitem $srcdir -force -recurse -ea SilentlyContinue|?{!([system.io.directory]::Exists($_.FullName))}|%{
	$relativepath = [system.io.path]::GetFullPath($_.FullName).SubString([system.io.path]::GetFullPath($srcdir).Length + 1);
	$obj.AddFile($_.FullName.ToString(),$relativepath.ToString() -as [system.uri]) 2>$null
	}
	$obj.Close()
}
#*=================================================================================
#Get-SizeFormat
#*=================================================================================
function Get-SizeFormat ()
{ 
     param($length)    
     if($length -gt 1gb)
     {
         $use=1gb;$ext="GB"
     }
     elseif($length -gt 1mb)
     {
        $use=1mb;$ext="MB"
     }
     else
     {
        $use=1kb;$ext="KB"
     }
    $size = [math]::Round($length/$use,2) 
    $size=$size.ToString()+"$ext"
    return $size     
}
#*=================================================================================
#CreateObjHelper
#*=================================================================================
function CreateObjHelper()
{
    param($file)
    
    $fileobj = new-Object psobject
    $f = new-object System.IO.fileinfo($file)
	$filename = $f.Name
	$sizeinbytes  = $f.Length
	$size = Get-SizeFormat $sizeinbytes		    
	Add-Member -InputObject $fileobj -MemberType noteproperty -Name Path -Value $file
	Add-Member -InputObject $fileobj -MemberType noteproperty -Name Name -Value $filename
	Add-Member -InputObject $fileobj -MemberType noteproperty -Name Size -Value $size 
	return $fileobj
}
#*=================================================================================
# CreateObj
#*=================================================================================
function CreateObj()
{
    param($files)
    
	$fileobjs = @()
	#write-diagprogress -activity $Strings_CL_fileCollection.ID_CollectFileProgressActivity
	foreach ($file in $files)
	{
	    if($file)
		{		     
            ### $paths = gci $file -recurse -force  -ea SilentlyContinue ### | % { $_.fullname }

			if ( -not ( test-path $file ) ) {  continue }

			& {
				$paths = gci $file -recurse -force  -ea SilentlyContinue
			}
			### CATCH NullReference and IndexOutOfRange, etc
			trap [Exception] {
	
				continue 
			}

            if([System.IO.file]::exists($file) -and $paths -eq $null)
			{
			    $fileobjs += (CreateObjHelper $file)				
			}
		    foreach($path in $paths)
		    { 
				$path.fullname

		        if($path)
		        {
					write-diagprogress -activity $Strings_CL_fileCollection.ID_CollectFileProgressActivity -status $path
					$fileobjs += (CreateObjHelper $path)
		        }
		    }
		}
	}
	return $fileobjs  
}
#*=================================================================================
# CopyTOMSDT
# Work around for clicking the Zip file error on the result page
#parameters $filepath,$title
#*=================================================================================
Function CopyToCABAndReport()
{
    param([string]$filepath,[string]$title = "Collected File",[string]$context = "TS_Main")
	$fileobjs = (CreateObj (Get-ChildItem $filepath -ea silentlycontinue|%{$_.fullname}	))

	Update-DiagReport -file ($fileobjs.path) -id $context -name $title -description ($fileobjs.size) -Verbosity Informational 
}

#*=================================================================================
# ispostbackOnWin
#*=================================================================================
function ispostbackOnWin($packName)
{
<#
	DESCRIPTION
	  ispostbackOnWin check whether package is postback.

	ARGUMENTS:
	  packName : String value containing ID of pack 

	RETURNS:
	  $result : Boolean value $true if package running in postback or $false 
#>
	[string] $path1 = (Get-Location -PSProvider FileSystem).ProviderPath
	[string] $path1 = join-path  $path1  "\$packName"
	if(test-path $path1){
		return $true
	}
	"once" > $path1 
	return $false
}


Function Get-DateDifference($bugcheckTime)
{
<#
	DESCRIPTION
	  Gets the date difference

	ARGUMENTS:
	  bugcheckTime : Time when blue screen occurred  

	RETURNS:
	  $occuredinlastSevenDays : Boolean value $true depending upon the time difference or $false 
#>	
     [bool]$occuredinlastSevenDays = $false
     $currentDate = (Get-Date)
     $timeSpan = New-TimeSpan -Start $bugcheckTime -End $currentDate
     if($timeSpan.Days -ge 7)
     {
       $occuredinlastSevenDays = $true
     }
     return $occuredinlastSevenDays
}

Function Write-ExceptionTelemetry($FunctionName, [System.Management.Automation.ErrorRecord] $ex)
{
    <#
    DESCRIPTION:
      Writes script error information into telemetry stream
     
    EXAMPLE:
      try
      {
         0 / 0
      }
      catch [System.Exception]
      {
         Write-ExceptionTelemetry "DivideByZeroTest" $_
      }
    #>
	if([System.Environment]::OSVersion.Version.Build -gt 15000)
	{
	    $ExceptionMessage = $ex.Exception.Message
		$ScriptFullPath = $ex.InvocationInfo.ScriptName
		$ExceptionScript = [System.IO.Path]::GetFileName($ScriptFullPath)
		$ExceptionScriptLine = $ex.InvocationInfo.ScriptLineNumber
		$ExceptionScriptColumn = $ex.InvocationInfo.OffsetInLine
        Write-DiagTelemetry "ScriptError" "$ExceptionScript\$FunctionName\$ExceptionScriptLine\$ExceptionScriptColumn\$ExceptionMessage"
	}	
}