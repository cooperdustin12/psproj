# Copyright © 2008, Microsoft Corporation. All rights reserved.

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

Write-DiagProgress -activity $localizationString.progress_ts_multipleAntivirusProducts

$antivirusProducts = Get-WmiObject -Query "Select * From AntiVirusProduct Where OnAccessScanningEnabled='true'" -Namespace "root/SecurityCenter"

if($antivirusProducts.Count -gt 1)
{
    Update-DiagRootCause -id "RC_MultipleAntivirusProducts" -Detected $true
} else {
    Update-DiagRootCause -id "RC_MultipleAntivirusProducts" -Detected $false
}

if($antivirusProducts -ne $null)
{
    $propertyArray = New-Object System.Collections.ArrayList
    $propertyArray += @{Name=$localizationString.antivirusProducts_companyName; Expression={$_.companyName}}
    $propertyArray += @{Name=$localizationString.antivirusProducts_displayName; Expression={$_.displayName}}
    $propertyArray += @{Name=$localizationString.antivirusProducts_onAccessScanningEnabled; Expression={$_.onAccessScanningEnabled}}
    $propertyArray += @{Name=$localizationString.antivirusProducts_pathToSignedProductExe; Expression={$_.pathToSignedProductExe}}
    $propertyArray += @{Name=$localizationString.antivirusProducts_versionNumber; Expression={$_.versionNumber}}
    $antivirusProducts | select-object -Property $propertyArray | convertto-xml | Update-DiagReport -id AntivirusProducts -name $localizationString.antivirusProducts_name -verbosity Informational -rid "RC_MultipleAntivirusProducts"
}