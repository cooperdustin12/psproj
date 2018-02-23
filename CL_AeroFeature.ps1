# Copyright © 2008, Microsoft Corporation. All rights reserved.


function CheckAeroTransprance()
{
    if(-not(Test-Path HKCU:\Software\microsoft\windows\dwm))
    {
        return $true
    }

    [int]$colorizationOpaqueBlend = (Get-ItemProperty -Path HKCU:\Software\microsoft\windows\dwm -Name ColorizationOpaqueBlend).ColorizationOpaqueBlend
    return -not($colorizationOpaqueBlend -eq 1)
}
