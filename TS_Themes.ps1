# Copyright © 2008, Microsoft Corporation. All rights reserved.


Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

Write-DiagProgress -activity $localizationString.themes_progress

# check Whether the service of Themes is existent

[bool]$themesState = $false

$wmiService = (Get-WmiObject -query "select * from win32_baseService where Name='Themes'")

if($wmiService -eq $null)
{
    $themesState = $false
}
else
{
    $themesState = $wmiService.state -eq "Running"
}

if(-not($themesState))
{
    Update-DiagRootCause -id "RC_Themes" -Detected $true
} else {
    Update-DiagRootCause -id "RC_Themes" -Detected $false
}

return $themesState
