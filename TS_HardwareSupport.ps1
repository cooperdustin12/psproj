# Copyright © 2008, Microsoft Corporation. All rights reserved.


. .\CL_RegSnapin.ps1
. .\CL_WinSAT.ps1
. .\CL_VideoMemory.ps1
. .\CL_Utility.ps1

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

Write-DiagProgress -activity $localizationString.hardware_progress

[bool]$result = $true

[string]$fileName = GetLatestAssessmentFile
if($fileName -eq $null)
{
    throw "Can't find latest assessment file"
}

[XML]$winsatData = Get-Content $fileName

[bool]$supportDx9 = SupportDx9 $winsatData

[bool]$supportPSM2 = SupportPSM2 $winsatData

$result = (SupportDx9 $winsatData) -and (SupportPSM2 $winsatData)

Write-DiagProgress -activity $localizationString.incapableGraphicsCard_progress

$dll = "MonitorSnapin.dll"
$nameSpace = "Microsoft.Windows.Diagnosis.SystemInfo.MonitorInfo"
[int]$minHeight = 600
[int]$minWidth = 800

try {
    [XML]$winsatData = Get-Content $fileName

    RegSnapin $dll $nameSpace

    $Monitors = Get-Monitors
    [int]$priMonWidth = $minHeight
    [int]$priMonHeight = $minWidth
    [int]$secMonWidth = 0
    [int]$secMonHeight = 0

    [bool]$transprance = $true
    InitiateResolutionData $priMonWidth $priMonHeight $secMonWidth $secMonHeight
    [int]$needBandWidth = ComputeForLowestPassingPerformance $transprance
    [int]$needMemorySize = ComputeForLowestPassingMemSize $transprance

    [double]$videoBandwidth = GetVideoMemBandWidth
    [double]$videoMemorySize = (GetVideoMemory $winsatData)/1024/1024

    if(($videoBandwidth -gt 0) -and ($videoBandwidth -lt $needBandWidth)) {
        $result = $false
    }

    if(($videoMemorySize -lt $needMemorySize))  {
        $result = $false
    }

    if(-not($result))
    {
        Update-DiagRootCause -id "RC_HardwareSupport" -Detected $true

        $propertyArray = @()
        $propertyArray += @{Name=$localizationString.requiredBandwidth;Expression={[string]([Math]::Round($needBandwidth, 3)) + "MB/s"}}
        if(0 -ne $videoBandwidth) {
            $propertyArray += @{Name=$localizationString.currentBandwidth;Expression={[string]([Math]::Round($videoBandwidth, 3)) + "MB/s"}}
        }
        $propertyArray += @{Name=$localizationString.requiredSize;Expression={[string]([Math]::Round($needMemorySize, 3))  + "MB"}}
        $propertyArray += @{Name=$localizationString.currentSize;Expression={[string]([Math]::Round($videoMemorySize, 3)) + "MB"}}

        New-Object -TypeName System.Management.Automation.PSObject | Select-Object -Property $propertyArray | convertto-xml | Update-DiagReport -id VideoMemory -name $localizationString.videoMemory_name -description $localizationString.videoMemory_Description -Verbosity informational -rid "RC_HardwareSupport"
    } else {
        Update-DiagRootCause -id "RC_HardwareSupport" -Detected $false
    }

    Update-DiagReport -file $fileName -id AssessmentFile -name $localizationString.assessmentFile_name -description $localizationString.assessmentFile_description -Verbosity Informational -rid "RC_HardwareSupport"
} finally {
    UnregSnapin $dll $nameSpace
}

return $result
