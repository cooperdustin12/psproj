# Copyright © 2008, Microsoft Corporation. All rights reserved.


#
# Launch the window of Performance Options and let user deside whether or not set Visual Effects to 'let Windows choose what's best for my computer'.
#

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData
. .\CL_Utility.ps1

Write-DiagProgress -activity $localizationString.progress_rs_visualEffects

[string]$SHOW_VISUAL_EFFECTS = "SHOWVISUALEFFECTS"
[string]$CLOSE_SYSTEM_PROPERTIES = "CLOSESYSTEMPROPERTIES"
[string]$performanceWindowName = $localizationString.performance_windowName
[string]$systemWindowName = $localizationString.system_windowName
[string]$className = $localizationString.performance_className
[string]$exePath = GetSystemPath "SystemPropertiesPerformance.exe"
[int]$WM_CLOSE = 0x0010;

#
# We will set the Performance Option window to top if it has been opened
#
$windowType = GetWindowType
[IntPtr]$performanceHandle = $windowType::FindWindowEx([IntPtr]::Zero, [IntPtr]::Zero, "$className", "$performanceWindowName")
[IntPtr]$systemHandle = $windowType::FindWindowEx([IntPtr]::Zero, [IntPtr]::Zero, "$className", "$systemWindowName")
if($performanceHandle -ne [IntPtr]::Zero)
{
    Get-DiagInput  -id "IT_ChangeVisualEffects"
}
else
{
    if($systemHandle -ne [IntPtr]::Zero)
    {
        $windowType::SendMessage($systemHandle, $WM_CLOSE, 0, 0)
        Sleep(1)
        $systemHandle = $windowType::FindWindowEx([IntPtr]::Zero, [IntPtr]::Zero, "$className", "$systemWindowName")
        if($systemHandle -ne [IntPtr]::Zero)
        {
            $select = Get-DiagInput  -id "IT_CloseSystemProperties"
            if($select -eq $CLOSE_SYSTEM_PROPERTIES)
            {
                Get-DiagInput  -id "IT_ChangeVisualEffects"
            }
        }
        else
        {
            Get-DiagInput  -id "IT_ChangeVisualEffects"
        }
    }
    else
    {
        Get-DiagInput  -id "IT_ChangeVisualEffects"
    }
}

