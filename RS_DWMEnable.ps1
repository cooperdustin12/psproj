# Copyright © 2008, Microsoft Corporation. All rights reserved.


. .\CL_Utility.ps1

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

Write-DiagProgress -activity $localizationString.DWMResolve_progress

# Modify registry key
if(-not(Test-Path "HKCU:\software\Microsoft\Windows\DWM"))
{
    New-Item -Path "HKCU:\software\Microsoft\Windows\DWM"
}

if((Get-ItemProperty "HKCU:\software\Microsoft\Windows\DWM" "Composition") -eq $null)
{
    New-ItemProperty -Path "HKCU:\software\Microsoft\Windows\DWM" -Name "Composition" -PropertyType DWORD -Value 1
}

if((Get-ItemProperty "HKCU:\software\Microsoft\Windows\DWM" "CompositionPolicy") -eq $null)
{
    New-ItemProperty -Path "HKCU:\software\Microsoft\Windows\DWM" -Name "CompositionPolicy" -PropertyType DWORD -Value 2
}

Set-ItemProperty "HKCU:\software\Microsoft\Windows\DWM" "Composition" 1
Set-ItemProperty "HKCU:\software\Microsoft\Windows\DWM" "CompositionPolicy" 2

& $env:windir\system32\dwm.exe -stop
& $env:windir\system32\dwm.exe -start
