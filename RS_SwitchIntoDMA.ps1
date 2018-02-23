# Copyright © 2008, Microsoft Corporation. All rights reserved.

trap { break }

#
# Switch devices into DMA mode
#

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData
. .\CL_Utility.ps1

Write-DiagProgress -activity $localizationString.progress_rs_switchIntoDMA

[string]$IDEChannel = "HKLM:\SYSTEM\CurrentControlSet\Enum\PCIIDE\IDEChannel\"
$IDEs = get-childItem -path $ideChannel

[bool]$result = $false
$IDEArray = New-Object System.Collections.ArrayList
foreach ($IDE in $IDEs)
{
    [string]$itemPath = $IDE.psPath + "\Device Parameters"
    $target = (get-childItem -path "$itemPath") | where { $_.PSChildName -eq "Target0" }
    if($target -ne $null -and (Get-ItemProperty $target.PSPath).UserTimingModeAllowed -eq 0x1f)
    {
        [string]$targetPath = $target.PSPath
        Set-ItemProperty "$targetPath" "UserTimingModeAllowed" 0xffffffff
        $IDEArray += (Get-ItemProperty $IDE.PSPath).FriendlyName
    }
}

$scanDefinition = @"
    [DllImport("setupapi.dll", CallingConvention = CallingConvention.StdCall, SetLastError = true)]
    public static extern int CM_Locate_DevNodeA(ref int pdnDevInst, IntPtr pDeviceID, int ulFlags);

    [DllImport("cfgmgr32.dll", CallingConvention = CallingConvention.StdCall, SetLastError = true)]
    public static extern int CM_Reenumerate_DevNode(int dnDevInst, int ulFlags);
"@

$scanType = Add-Type -MemberDefinition $scanDefinition -Name "scanType" -UsingNamespace "System.Reflection","System.Diagnostics" -PassThru

[string]$fileName = "RS_SwitchInfoDMA"

[int]$pdnDevInst = 0
[int]$status = $scanType::CM_Locate_DevNodeA([REF]$pdnDevInst, [IntPtr]::Zero, 0)
if($status -ne 0)
{
    WriteFileAPIExceptionReport $fileName "CM_Locate_DevNodeA" $status
    return
}
$status = $scanType::CM_Reenumerate_DevNode($pdnDevInst, 0)
if($status -ne 0)
{
    WriteFileAPIExceptionReport $fileName "CM_Reenumerate_DevNode" $status
    return
}

if($IDEArray.Length -gt 0)
{
    $IDEArray | select-object -Property @{Name=$localizationString.pioModeIDE_friendlyName; Expression={$_}} | convertto-xml | Update-DiagReport -id DMAModeIDE -name $localizationString.dmaModeIDE_name -description $localizationString.dmaModeIDE_description -verbosity Informational
}
