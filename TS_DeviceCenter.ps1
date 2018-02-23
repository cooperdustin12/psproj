# Copyright © 2008, Microsoft Corporation. All rights reserved.


. .\CL_Utility.ps1
Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

Write-DiagProgress -activity $localizationString.Progress_Troubleshoot

try
{
    [string]$DeviceErrorInfo = Get-DiagInput -ID "IT_DeviceInfo"
}
catch
{
    return
}

if([String]::IsNullOrEmpty($DeviceErrorInfo) -eq $True)
{
    return
}

$DeviceDataArray = GetProblematicFunctionForObject $DeviceErrorInfo

if($DeviceDataArray -eq $Null)
{
    return
}

$PnPDeviceID = ""
$PrinterName = ""
$UsbDeviceID = ""

foreach($DeviceData in $DeviceDataArray)
{
    $DeviceType = $DeviceData.Type

    if([String]::IsNullOrEmpty($DeviceType) -eq $True)
    {
        return
    }

    if($DeviceType -eq "PNPDevice")
    {
        $PnPDeviceID += $DeviceData.DeviceID
        $PnPDeviceID += "#"
    }

    if($DeviceType -eq "Printer")
    {
        $PrinterName = $DeviceData.DeviceName
    }

    if($DeviceType -eq "USB")
    {
        if (-not([String]::IsNullOrEmpty($UsbDeviceID)))
        {
            $UsbDeviceID += "#"
        }
        $UsbDeviceID += $DeviceData.DeviceID
    }
}


if([String]::IsNullOrEmpty($UsbDeviceID) -eq $False)
{
    # Don't run USB TS if PNP TS runs
    #   Reason: USB+PNP TSes can interfere with each other
    #   Reason 2: Create strict ordering: USB TS runs after PNP TS
    if([String]::IsNullOrEmpty($PnPDeviceID))
    {

        # Encode the special characters in the context parameter since the context parameter is
        # passed through an XML blob.
        $UsbDeviceID = $UsbDeviceID.Replace("&", "&amp;")
        Update-DiagRootCause -id "RC_ProblematicUSBDevice" -Detected $true -p @{'USBDEVICEID' = $UsbDeviceID}

    }
}


if([String]::IsNullOrEmpty($PnPDeviceID) -eq $False)
{
    $PnPDeviceID = $PnPDeviceID.Replace("&", "&amp;")
    Update-DiagRootCause -id "RC_ProblematicPNPDevice" -Detected $true -p @{'DEVICEID' = $PnPDeviceID}
}


if([String]::IsNullOrEmpty($PrinterName) -eq $False)
{
    Update-DiagRootCause -id "RC_ProblematicPrinter" -Detected $true -p @{'PRINTERNAME' = $PrinterName}
}
