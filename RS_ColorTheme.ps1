# Copyright © 2008, Microsoft Corporation. All rights reserved.

PARAM($originalName, $originalThemeStatus, $originalVisualStyleName)

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

Write-DiagProgress -activity $localizationString.colorTheme_progress

. .\cl_Utility.ps1

if("Stopped" -eq (Get-Service "Themes").Status) {
    $startupType = (Get-WmiObject -query "select * from win32_baseService where Name='Themes'").StartMode

    if($startupType -ne "auto" -and $startupType -ne $null) {
        (Get-WmiObject -query "select * from win32_baseService where Name='Themes'").changeStartMode("automatic") > $null
    }

    Start-Service "Themes"
    WaitFor-ServiceStatus "Themes" ([ServiceProcess.ServiceControllerStatus]::Running)
}

[string]$sourceCode = Get-ThemeSourceCode
[string]$themeFilePath = Join-Path ${env:windir} "Resources\Themes\aero.theme"
Invoke-Method $sourceCode "ThemeTool.exe" "changetheme $themeFilePath"

[string]$name = Invoke-Method $sourceCode "ThemeTool.exe" "getcurrentthemename"
[string]$themeStatus = Invoke-Method $sourceCode "ThemeTool.exe" "getthemestatus"
[string]$visualStyleName = Invoke-Method $sourceCode "ThemeTool.exe" "getcurrentvisualstylename"

$propertyArray = @()
if($name -ne $originalName) {
    $propertyArray += @{Name=$localizationString.modifiedThemeStatus;Expression={$themeStatus}}
}

if($themeStatus -ne $originalThemeStatus) {
    $propertyArray += @{Name=$localizationString.modifiedThemeName;Expression={$name}}
}

if($visualStyleName -ne $originalVisualStyleName) {
    $propertyArray += @{Name=$localizationString.modifiedVisualStyle;Expression={$visualStyleName}}
}

if(0 -ne $propertyArray.Count) {
    New-Object -TypeName System.Management.Automation.PSObject | Select-Object $propertyArray | Convertto-Xml | Update-DiagReport -id ModifiedThemeInfo -name $localizationString.ThemeInfo -Verbosity informational
}
