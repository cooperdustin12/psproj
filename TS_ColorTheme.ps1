# Copyright © 2008, Microsoft Corporation. All rights reserved.


Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

Write-DiagProgress -activity $localizationString.colorTheme_progress

. .\cl_Utility.ps1

[bool]$result = $true

$sourceCode = Get-ThemeSourceCode
[string]$name = Invoke-Method $sourceCode "ThemeTool.exe" "getcurrentthemename"
[string]$themeStatus = Invoke-Method $sourceCode "ThemeTool.exe" "getthemestatus"
[string]$visualStyleName = Invoke-Method $sourceCode "ThemeTool.exe" "getcurrentvisualstylename"

New-Object -TypeName System.Management.Automation.PSObject | Select-Object @{Name=$localizationString.CurrentThemeStatus;Expression={$themeStatus}},@{Name=$localizationString.CurrentThemeName;Expression={$name}},@{Name=$localizationString.CurrentVisualStyle;Expression={$visualStyleName}} | Convertto-Xml | Update-DiagReport -id CurrentThemeInfo -name $localizationString.ThemeInfo -Verbosity informational -rid "RC_ColorTheme"

if(($themeStatus -ne "running") -or ($visualStyleName -ne "Aero.msstyles"))
{
    $result = $false
}

if(-not($result))
{
    Update-DiagRootCause -id "RC_ColorTheme" -detected $true -parameter @{"Name"="$name";"ThemeStatus"="$themeStatus";"VisualStyleName"="$visualStyleName"}
} else {
    Update-DiagRootCause -id "RC_ColorTheme" -detected $false -parameter @{"Name"="$name";"ThemeStatus"="$themeStatus";"VisualStyleName"="$visualStyleName"}

}

return $result
