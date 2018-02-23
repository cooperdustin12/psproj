# Copyright © 2008, Microsoft Corporation. All rights reserved.


. .\CL_Invocation.ps1
. .\CL_Utility.ps1

# Get videoMemoryBandwidth from registry
function GetVideoMemBandwidth()
{
    [string]$path = "HKLM:\SOFTWARE\Microsoft\Windows Nt\CurrentVersion\WinSat"
    [string]$name = "VideoMemoryBandwidth"
    [int]$VideoMemoryBandWidth = 0
    if(Test-Path $path)
    {
        $registryEntry = Get-ItemProperty -Path $path -Name $name
        if($registryEntry -ne $null)
        {
            $VideoMemoryBandWidth = $registryEntry.$name
        }
    }

    return ($videoMemoryBandWidth / 1KB)
}

# Check whether VideoMemoryBandwidth present in registry
function CheckWinSatHaveRun()
{
    [string]$path = "HKLM:\SOFTWARE\Microsoft\Windows Nt\CurrentVersion\WinSat"
    [string]$name = "VideoMemoryBandwidth"
    [bool]$result = $false

    if(Test-Path $path)
    {
        $registryEntry = Get-ItemProperty -Path $path -Name $name
        if($registryEntry -ne $null)
        {
            $result = $true
        }
    }

    return $result
}

# Get VideoMemorySize
function GetVideoMemory([XML]$winsatData = $(throw "No winsat data is specified"))
{
    return [int]$winsatData.WinSAT.SystemConfig.Graphics.DedicatedVideoMemory + [int]$winsatData.WinSAT.SystemConfig.Graphics.DedicatedSystemMemory + [int]$winsatData.WinSAT.SystemConfig.Graphics.SharedSystemMemory
}

# Check the graphics card supports Directx9.0 or higher
function SupportDx9([XML]$winsatData = $(throw "No winsat data is specified"))
{
    return [int]$winsatData.WinSAT.SystemConfig.Graphics.D3D9OrBetter -eq 1
}

# Check the graphics card supports pixel shader model 2.0 or higher
function SupportPSM2([XML]$winsatData = $(throw "No winsat data is specified"))
{
    return [int]$winsatData.WinSAT.SystemConfig.Graphics.PixelShader2OrBetter -eq 1
}

# Check the graphics card has WDDM driver
function HasWDDMDriver([XML]$winsatData = $(throw "No winsat data is specified"))
{
    return [int]$winsatData.WinSAT.SystemConfig.Graphics.LDDM -eq 1
}
