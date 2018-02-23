# Copyright © 2008, Microsoft Corporation. All rights reserved.

. .\CL_Utility.ps1

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

Write-DiagProgress -activity $localizationString.transparencyResolve_progress

[string]$sourceCode = Get-ThemeSourceCode
Invoke-Method $sourceCode "ThemeTool.exe" "activatetransparency"
