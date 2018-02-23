# Copyright © 2008, Microsoft Corporation. All rights reserved.

function Enable-HomeGroupLogging([bool]$isRerun)
{
    if ($isRerun)
    {
        Write-DiagProgress -activity $LocalizedStrings.TS_VerifyingConfiguration
    }
    else
    {
        Write-DiagProgress -activity $LocalizedStrings.TS_Starting
    }

    try
    {
        [string]$path = "HKLM:\Software\Microsoft\Windows\CurrentVersion\HomeGroup\TestHooks"
        [string]$item = "Logging"

        New-Item -type Directory $path
        Set-ItemProperty -path $path -name $item -type DWORD -value 0xFFFFFFFF
    }
    catch
    {
    }

    if ((ServiceRunning "HomeGroupProvider") -and (-not($isRerun)))
    {
        Restart-Service "HomeGroupProvider"
    }
}

function Disable-HomeGroupLogging()
{
    Write-DiagProgress -activity $LocalizedStrings.TS_VerifyingConfiguration

    try
    {
        [string]$path = "HKLM:\Software\Microsoft\Windows\CurrentVersion\HomeGroup\TestHooks"
        [string]$item = "Logging"

        Remove-ItemProperty -path $path -name $item
    }
    catch
    {
    }

    # Attach the logfile to the report
    [string]$logfile = "$ENV:SystemRoot\Logs\HomeGroup\homegrouplog.etl"
    if (Test-Path -path $logfile)
    {
        Update-DiagReport -file $logfile -ID HomeGroupLog -Name $LocalizedStrings.RPT_HomeGroupLog
    }
}

function Kick-WSD()
{
    $paths  = @("HKLM:\SOFTWARE\Microsoft\Function Discovery\RegistryStore\Publication\Explorer",
                "HKLM:\SOFTWARE\Microsoft\Function Discovery\RegistryStore\Publication\HomeGroup")
    $names  = @($null, $null)
    $values = @($null, $null)

    try
    {
        # Save and clear the publication keys
        for ($i = 0; $i -lt $paths.Count; $i++)
        {
            $item = Get-Item -path $paths[$i]
            if ($item.ValueCount -gt 0)
            {
               $names[$i] = ($item.GetValueNames())[0]
               $values[$i] = $item.GetValue($names[$i])
               Clear-ItemProperty -path $paths[$i] -name $names[$i]
            }
        }

        # Wait for WSD to register the change
        Start-Sleep -Milliseconds 5000
    }
    finally
    {
        # Restore the publication keys
        for ($i = 0; $i -lt $paths.Count; $i++)
        {
            if ($values[$i] -ne $null)
            {
                Set-ItemProperty -path $paths[$i] -name $names[$i] -value $values[$i]
            }
        }
    }
}

$script:ExpectingException = $false
$script:isRerun = $false
$script:isEnding = $false

&{
    $script:ExpectingException = $true
    $SBSData = Get-DiagInput -ID "SecurityBoundarySafe"
    $script:ExpectingException = $false

    if ($SBSData[0].Length -gt 0)
    {
        if ($SBSData[0] -eq "End")
        {
            $script:isEnding = $true
        }

        $script:isRerun = $true
    }
}
trap [Exception]
{
    if ($script:ExpectingException)
    {
        $script:ExpectingException = $false
        continue
    }
    else
    {
        throw $_.Exception
    }
}

if ($script:isEnding)
{
    return
}

$interopDllPath = "$ENV:SystemRoot\diagnostics\system\HomeGroup\Microsoft-Windows-HomeGroupDiagnostic.Interop.dll"
[Reflection.Assembly]::LoadFile($interopDllPath);

. .\CL_Detection.ps1

Import-LocalizedData -BindingVariable LocalizedStrings -FileName CL_LocalizationData

Enable-HomeGroupLogging($script:isRerun)

if (-not($script:isRerun))
{
    $response = Get-DiagInput -id IT_NetworkDiagnostics
    if ($response[0] -eq "Yes")
    {
        Write-DiagProgress -activity $LocalizedStrings.TS_NetworkDiagnostics

        if (Test-HomeGroupName)
        {
            $HomeGroupName = Get-HomeGroupName
            Start-Process -Wait -FilePath "$ENV:SystemRoot\System32\msdt.exe" -ArgumentList @("-skip", "-force", "-path", "$ENV:windir\diagnostics\system\Networking", "-param", "`"IT_EntryPoint=Grouping IT_GroupName=$HomeGroupName`"")
        }
        else
        {
            Start-Process -Wait -FilePath "$ENV:SystemRoot\System32\msdt.exe" -ArgumentList @("-skip", "-force", "-path", "$ENV:windir\diagnostics\system\Networking", "-param", "`"IT_EntryPoint=NetworkAdapter IT_NetworkAdapter={00000000-0000-0000-0000-000000000000}`"")
        }
    }

    Kick-WSD
}

$RootCauseList = @("PeerNetworkingGrouping",
                   "HomeGroupProvider",
                   "MultipleNetworks",
                   "NetworkIsPublic",
                   "IPv6",
                   "InformationCorruption",
                   "Permissions",
                   "GroupMembership",
                   "FirewallConfiguration",
                   "HomeGroupNotConnected")

[bool]$IssuesDetected = $false
foreach ($RootCause in $RootCauseList)
{
    if (Check-RootCause $RootCause)
    {
        $IssuesDetected = $true
        if ($RootCause -eq "HomeGroupNotConnected")
        {
            Check-RootCause "Firewall"
        }
    }
}

if (-not($IssuesDetected))
{
    $result = Get-DiagInput -id IT_IsProblemFixed
    if ($result[0] -eq "Yes")
    {
        Update-DiagRootCause -id RC_IssuesFixed -Detected $true -Parameter @{"SBSData" = "End"}
    }
    else
    {
        Check-RootCause -ShowDialog "Firewall"
        Update-DiagRootCause -id RC_UserIdentifiedIssues -Detected $true -Parameter @{"SBSData" = "End"}
    }
}

Disable-HomeGroupLogging