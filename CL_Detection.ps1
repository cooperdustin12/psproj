# Copyright © 2008, Microsoft Corporation. All rights reserved.

. .\CL_Service.ps1
. .\CL_INetwork.ps1
. .\CL_NativeMethods.ps1
. .\CL_WscApi.ps1

Import-LocalizedData -BindingVariable LocalizedStrings -FileName CL_LocalizationData

[string]$Global:ExplorerPublishingPath = "HKLM:\SOFTWARE\Microsoft\Function Discovery\RegistryStore\Publication\Explorer"
[string]$Global:HomegroupPublishingPath = "HKLM:\SOFTWARE\Microsoft\Function Discovery\RegistryStore\Publication\HomeGroup"

[string]$Global:MachineKeysPath = "$ENV:SystemDrive\ProgramData\Microsoft\Crypto\RSA\MachineKeys"

# NET_FW_PROFILE_TYPE2 Enumeration
$Global:NET_FW_PROFILE2_DOMAIN  = 0x0001
$Global:NET_FW_PROFILE2_PRIVATE = 0x0002
$Global:NET_FW_PROFILE2_PUBLIC  = 0x0004
$Global:NET_FW_PROFILE2_ALL     = 0x7FFFFFFF

$Global:FirewallRulesHomeNetwork = @{"Core Networking"                              = "@FirewallAPI.dll,-25000";    # IDS_FW_CORENET_GROUP
                                     "Network Discovery"                            = "@FirewallAPI.dll,-32752"}    # IDS_FW_NETDIS_GROUP

$Global:FirewallRuleHomeGroup    = "@%systemroot%\system32\provsvc.dll,-202"                                        # IDS_FIREWALL_GROUP

$Global:FirewallRulesSharing     = @{"File and Printer Sharing"                     = "@FirewallAPI.dll,-28502";    # IDS_FW_FPS_GROUP
                                     "Windows Media Player"                         = "@FirewallAPI.dll,-31002";    # IDS_FW_WMP_GROUP
                                     "Windows Media Player Network Sharing Service" = "@FirewallAPI.dll,-31252"}    # IDS_FW_WMPNSS_GROUP

function Get-HomeGroupId()
{
    [string]$hgid = $null;
    $regKey= Get-Item -path "HKLM:\SYSTEM\CurrentControlSet\Services\HomeGroupProvider\ServiceData"
    if ($regKey)
    {
        if ($regKey.SubKeyCount -eq 1)
        {
            $hgid = $regKey.GetSubKeyNames()[0];
        }
    }
    return $hgid;
}

function Get-HomeGroupName()
{
    $name = $null;
    [string]$hgid = Get-HomeGroupId;
    if ($hgid)
    {
        [string]$path = "HKLM:\SYSTEM\CurrentControlSet\Services\HomeGroupProvider\ServiceData\" + $hgid;
        [string]$item = "PeerGroupName";
        $name = (Get-ItemProperty -Path $path -Name $item).$item
    }
    return $name;
}

function Test-HomeGroupName()
{
    return [bool](Get-HomeGroupName)
}

function Check-IPv6()
{
    [bool]$disabled = $false
    $nics = [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces()
    foreach ($adapter in $nics)
    {
        if (($adapter.NetworkInterfaceType -ne "Tunnel") -and ($adapter.NetworkInterfaceType -ne "Loopback"))
        {
            if ($adapter.OperationalStatus -eq "Up")
            {
                if (-not($adapter.Supports([System.Net.NetworkInformation.NetworkInterfaceComponent]::IPv6)))
                {
                    # One of the connected adapters doesn't support IPv6
                    $disabled = $true
                    break
                }
            }
        }
    }
    return $disabled
}

function Check-RegKeys()
{
    # If we are not joined to a homegroup yet, these registry keys must be empty
    return ((-not(Test-HomeGroupName)) -and
             ((-not(((Get-Item -Path $Global:ExplorerPublishingPath).GetValueNames()).Count -eq 0)) -or
               (-not(((Get-Item -Path $Global:HomegroupPublishingPath).GetValueNames()).Count -eq 0))))
}

function Check-Permissions()
{
    [bool]$issueDetected = $true
    $everyone = (New-Object System.Security.Principal.SecurityIdentifier("S-1-1-0")).Translate([System.Security.Principal.NTAccount])

    $acl = Get-Acl -Path $Global:MachineKeysPath
    foreach ($ace in $acl.Access)
    {
        if ($ace.IdentityReference -eq $everyone)
        {
            if ($ace.AccessControlType -eq "Allow")
            {
                $issueDetected = ($ace.FileSystemRights -ne "Write, Read, Synchronize")
            }

            if ($issueDetected)
            {
                break
            }
        }
    }
    return $issueDetected
}

function Check-GroupMembership()
{
    [bool]$script:issueDetected = $true
    $ad = [ADSI]"WinNT://$ENV:ComputerName"

    &{
        $script:group = $ad.Children.Find("HomeUsers", "group")
    }
    trap [Exception]
    {
        # If the HomeUsers group doesn't exist, then there is something seriously wrong
        # Bail out and let the catch all interaction handle the issue
        $script:issueDetected = $false
        continue
    }

    if ($script:issueDetected)
    {
        $user = $ad.Children.Find("$ENV:UserName", "user")
        foreach ($item in $user.Groups())
        {
            $grp = New-Object System.DirectoryServices.DirectoryEntry($item)
            if ($grp.Name.Value -eq $script:group.Name.Value)
            {
                $script:issueDetected = $false
                break
            }
        }
    }

    return $script:issueDetected
}

function IsWindowsFirewallEnabled()
{
    $firewall = New-Object -COM HNetCfg.FwPolicy2
    return $firewall.FirewallEnabled($Global:NET_FW_PROFILE2_PRIVATE)
}

function Check-WindowsFirewallRules()
{
    [bool]$issueDetected = $false
    $firewall = New-Object -COM HNetCfg.FwPolicy2

    foreach ($RuleGroup in $Global:FirewallRulesHomeNetwork.Values)
    {
        if (-not($firewall.IsRuleGroupEnabled($Global:NET_FW_PROFILE2_PRIVATE, $RuleGroup)))
        {
            $issueDetected = $true
            break
        }
    }

    # Certain firewall rules are only enabled when we are joined to a HomeGroup
    if (-not($issueDetected) -and (Test-HomeGroupName))
    {
        $issueDetected = (-not($firewall.IsRuleGroupEnabled($Global:NET_FW_PROFILE2_PRIVATE, $Global:FirewallRuleHomeGroup)))

        # File sharing firewall rules are only enabled on non-domain-joined machines and non-ARM machines
        if (-not($issueDetected) -and -not(IsDomainJoined) -and (env:PROCESSOR_ARCHITECTURE -ne "ARM"))
        {
            foreach ($RuleGroup in $Global:FirewallRulesSharing.Values)
            {
                if (-not($firewall.IsRuleGroupEnabled($Global:NET_FW_PROFILE2_PRIVATE, $RuleGroup)))
                {
                    $issueDetected = $true
                    break
                }
            }
        }
    }

    return $issueDetected
}

function Check-RootCause($RootCause, [switch]$ShowDialog)
{
    $params = @{"SBSData" = "Rerun"}
    [bool]$checked = $true
    [bool]$detected = $false

    switch ($RootCause)
    {
        "PeerNetworkingGrouping" {
            Write-DiagProgress -activity $LocalizedStrings.TS_PeerNetworkingGrouping
            $checked = ((CheckForHomeNetwork) -and (Test-HomeGroupName) -and (ServiceRunning "HomeGroupProvider"))
            if ($checked)
            {
                $detected = (-not(ServiceRunning "p2psvc"))
            }
        }

        "HomeGroupProvider" {
            Write-DiagProgress -activity $LocalizedStrings.TS_HomeGroupProvider
            $checked = (CheckForHomeNetwork)
            if ($checked)
            {
                $detected = ((-not(ServiceRunning "HomeGroupProvider")) -or
                             (-not(ServiceRunning "netprofm")) -or
                             (-not(ServiceRunning "fdPHost")) -or
                             (-not(ServiceRunning "FDResPub")))
            }
        }

        "MultipleNetworks" {
            Write-DiagProgress -activity $LocalizedStrings.TS_MultipleNetworks
            $detected = ((NumNetworks) -gt 1)
        }

        "NetworkIsPublic" {
            Write-DiagProgress -activity $LocalizedStrings.TS_NetworkIsPublic
            $checked = ((NumNetworks) -gt 0)
            if ($checked)
            {
                $detected = (-not(CheckForHomeNetwork))
            }
        }

        "IPv6" {
            Write-DiagProgress -activity $LocalizedStrings.TS_IPv6
            $detected = (Check-IPv6)
        }

        "InformationCorruption" {
            Write-DiagProgress -activity $LocalizedStrings.TS_InformationCorruption
            $detected = (Check-RegKeys)
        }

        "Permissions" {
            Write-DiagProgress -activity $LocalizedStrings.TS_Permissions
            $detected = (Check-Permissions)
        }

        "GroupMembership" {
            Write-DiagProgress -activity $LocalizedStrings.TS_GroupMembership
            $checked = (Test-HomeGroupName)
            if ($checked)
            {
                $detected = (Check-GroupMembership)
            }
        }

        "Firewall" {
            Write-DiagProgress -activity $LocalizedStrings.TS_Firewall

            $params.Add("FirewallRootcauseName", $LocalizedStrings.DSP_RC_FirewallTitle)
            $params.Add("FirewallResolverName", $LocalizedStrings.DSP_RS_FirewallTitle)

            [string]$FirewallName = ""
            $detected = Check-Firewall([ref]$FirewallName)
            if ($detected)
            {
                if ($FirewallName.Length -gt 0)
                {
                    $params.Item("FirewallRootcauseName") = ($LocalizedStrings.DSP_RC_FirewallTitle_Name -f $FirewallName)
                    $params.Item("FirewallResolverName") = ($LocalizedStrings.DSP_RS_FirewallTitle_Name -f $FirewallName)
                }

                if ($ShowDialog.isPresent)
                {
                    $params.Item("SBSData") = "End"
                    Get-DiagInput -id IT_Firewall -Parameter @{"FirewallInteractionName" = $params.Item("FirewallResolverName")}
                }
            }
        }

        "FirewallConfiguration" {
            Write-DiagProgress -activity $LocalizedStrings.TS_FirewallConfiguration
            $checked = ((CheckForHomeNetwork) -and (IsWindowsFirewallEnabled))
            if ($checked)
            {
                $detected = (Check-WindowsFirewallRules)
            }
        }

        "HomeGroupNotConnected" {
            Write-DiagProgress -activity $LocalizedStrings.TS_HomeGroupNotConnected
            $checked = (CheckForHomeNetwork)
            if ($checked)
            {
                $detected = (-not(Test-HomeGroupName))
            }
        }

        default {
            $checked = $false
            throw "RootCause not found. `$RootCause = $RootCause"
        }
    }

    if ($checked)
    {
        Update-DiagRootCause -id "RC_$RootCause" -Detected $detected -Parameter $params
    }

    return [bool]$detected
}