# Copyright © 2008, Microsoft Corporation. All rights reserved.

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData
. .\CL_Utility.ps1

Write-DiagProgress -activity $localizationString.progress_ts_tooManyStartupPrograms
[string]$inboxExeProductName = GetInboxExeProductName
#
# the related registry key
#
[string]$HKLMRun = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
[string]$HKCURun = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
[string]$HKCUWowRun = "HKCU:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run"
[string]$HKLMWowRun = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run"

$registryValueArray = New-Object -TypeName System.Collections.ArrayList

#
# Perhaps the string array could be added later.
#
$saveValues = ,"WindowsWelcomeCenter"

$keyArray = ($HKLMRun, $HKCURun, $HKCUWowRun, $HKLMWowRun)
foreach($key in $keyArray)
{
    #
    # Check whether the key is existed in registry
    #
    if(-not (Test-Path($key)))
    {
        Continue
    }
    $keyObj = Get-Item -Path $key
    $names = $keyObj.Property
    if($names.Count -gt 0)
    {
        foreach($name in $names)
        {
            [bool]$canBeRemoved = $true
            foreach($saveValue in $saveValues)
            {
                if($name -eq $saveValue)
                {
                    $canBeRemoved = $false
                    break
                }
            }
            if($canBeRemoved)
            {
                [bool]$needbeAdded = $true
                [string]$data = (Get-ItemProperty -Path $key -Name $name).$name
                [System.Text.RegularExpressions.MatchCollection]$matches = [System.Text.RegularExpressions.Regex]::matches($data, "\""?(?<exePath>.+.exe)\""?", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
                if($matches.Count -gt 0)
                {
                    try
                    {
                        [string]$exePath = $matches[0].Groups["exePath"].Value
                        $needbeAdded = NeedAddToList $exePath $inboxExeProductName
                    }
                    catch
                    {
                        WriteFileExceptionReport "TS_TooManyStartupPrograms" $_
                    }
                }
                if($needbeAdded)
                {
                    $registryValueArray += (Get-ItemProperty -Path $key -Name $name).$name
                }
            }
        }
    }
}

#
# the related startup file
#
[string]$currentUserRoaming = "$env:userProfile\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
[string]$currentUserLocal = "$env:userProfile\AppData\Local\Microsoft\Windows\Start Menu\Programs\Startup"
[string]$programData = "$env:SystemDrive\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
$pathArray = ($currentUserRoaming, $currentUserLocal, $programData)

$startupFileArray = New-Object -TypeName System.Collections.ArrayList

foreach($path in $pathArray)
{
    if(Test-Path($path))
    {
        $fileArray = Get-ChildItem -Path $path
        if($fileArray -ne $null)
        {
            foreach($statupFile in $fileArray)
            {
                [bool]$needbeAdded = $true
                try
                {
                    $shell =  New-Object -ComObject WScript.Shell
                    $shortcut = $shell.CreateShortcut($statupFile.FullName)

                    if($shortcut -ne $null)
                    {
                        $targetPath = [System.Environment]::ExpandEnvironmentVariables($shortcut.TargetPath)
                        $needbeAdded = NeedAddToList $shortcut.TargetPath $inboxExeProductName
                    }
                }
                catch
                {
                    WriteFileExceptionReport "TS_TooManyStartupPrograms" $_
                }
                if($needbeAdded)
                {
                    $startupFileArray += $statupFile
                }
            }
        }
    }
}


if(($registryValueArray.Count + $startupFileArray.Count) -gt 10)
{
    Update-DiagRootCause -id "RC_TooManyStartupPrograms" -Detected $true
} else {
    Update-DiagRootCause -id "RC_TooManyStartupPrograms" -Detected $false
}

if($registryValueArray.Count -gt 0)
{
    $registryValueArray | select-object -Property @{Name=$localizationString.registryPrograms_programName; Expression={$_}} | convertto-xml | Update-DiagReport -id RegistryPrograms -name $localizationString.registryPrograms_name -verbosity Informational -rid "RC_TooManyStartupPrograms"
}

if($startupFileArray.Count -gt 0){

    $startupFileArray | select-object -Property @{Name=$localizationString.registryPrograms_programName; Expression={$_.FullName}} | convertto-xml | Update-DiagReport -id RegistryPrograms -name $localizationString.registryPrograms_name -verbosity Informational -rid "RC_TooManyStartupPrograms"
}

