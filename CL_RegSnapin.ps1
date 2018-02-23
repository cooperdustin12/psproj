# Copyright © 2008, Microsoft Corporation. All rights reserved.


# Common library
. .\CL_Utility.ps1

function RegSnapin([string]$dllName = $(throw "No dll is specified"), [string]$namespace = $(throw "No namespace is specified"))
{
    if((Get-PSSnapin | Where-Object {$_.Name -eq $namespace}) -eq $null)
    {
        [string]$installTool = GetRuntimePath "InstallUtil.exe"

        &$installTool $dllName > $null
        Add-PSSnapin $nameSpace
    }
}

function UnregSnapin([string]$dllName = $(throw "No dll is specified"), [string]$namespace = $(throw "No namespace is specified"))
{
    if((Get-PSSnapin | Where-Object {$_.Name -eq $namespace}) -ne $null)
    {
        #Remove-PSSnapin $nameSpace

        [string]$installTool = GetRuntimePath "InstallUtil.exe"
        &$installTool /u $dllName > $null
    }
}
