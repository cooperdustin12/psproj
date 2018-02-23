# Copyright © 2008, Microsoft Corporation. All rights reserved.


. .\CL_Utility.ps1
. .\CL_Invocation.ps1

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

Write-DiagProgress -activity $localizationString.winSatResolve_progress

[string]$fileName = "DisplayAssessment.xml"

[string]$winSatCmd = GetSystemPath "WinSat.exe"
SyncInvoke $winSatCmd "dwm -xml $fileName" $true

if((-not([String]::IsNullOrEmpty($fileName))) -and (Test-Path $fileName))
{
    Update-DiagReport -file $fileName -id UpdatedAssessmentFile -name $localizationString.updatedAssessmentFile_name -description $localizationString.assessmentFile_description -Verbosity Informational
}
