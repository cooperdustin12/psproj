# Copyright © 2008, Microsoft Corporation. All rights reserved.

param($RootCause)

. .\CL_INetwork.ps1
. .\CL_Service.ps1
. .\CL_Detection.ps1

Import-LocalizedData -BindingVariable LocalizedStrings -FileName CL_LocalizationData

switch ($RootCause)
{
    "NetworkIsPublic" {
        if ((NumNetworks) -gt 1)
        {
            Get-DiagInput -id IT_MultiplePublicNetworks
        }
        else
        {
            if (CheckForDomainNetwork)
            {
                Get-DiagInput -id IT_SingleDomainNetwork
            }
            else
            {
                $response = Get-DiagInput -id IT_SinglePublicNetwork
                if ($response[0] -eq "Apply")
                {
                    Write-DiagProgress -activity $LocalizedStrings.RS_NetworkIsPublic
                    SetNetworkToHome
                    WaitFor-ServiceStatus "HomeGroupProvider" ([ServiceProcess.ServiceControllerStatus]::Running)
                }
            }
        }
    }

    "InformationCorruption" {
        Write-DiagProgress -activity $LocalizedStrings.RS_InformationCorruption

        Clear-Item -Path $Global:ExplorerPublishingPath
        Clear-Item -Path $Global:HomegroupPublishingPath

        Restart-Service "p2psvc"
    }

    "Permissions" {
        Write-DiagProgress -activity $LocalizedStrings.RS_Permissions

        $acl = [System.IO.File]::GetAccessControl($Global:MachineKeysPath, [System.Security.AccessControl.AccessControlSections]::Access)

        # Break inheritance and delete inherited ACEs
        $acl.SetAccessRuleProtection($true, $false)

        # Give Everyone Read, Write, Synchronize access
        $everyone = New-Object System.Security.Principal.SecurityIdentifier("S-1-1-0")
        $acl.PurgeAccessRules($everyone)
        $ace = New-Object System.Security.AccessControl.FileSystemAccessRule($everyone, "Read, Write, Synchronize", [System.Security.AccessControl.AccessControlType]::Allow)
        $acl.SetAccessRule($ace)

        # Give BUILTIN\Administrators FullControl access
        $administrators = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")
        $acl.PurgeAccessRules($administrators)
        $ace = New-Object System.Security.AccessControl.FileSystemAccessRule($administrators, "FullControl", [System.Security.AccessControl.AccessControlType]::Allow)
        $acl.SetAccessRule($ace)

        [System.IO.File]::SetAccessControl($Global:MachineKeysPath, $acl)
    }

    "GroupMembership" {
        Write-DiagProgress -activity $LocalizedStrings.RS_GroupMembership

        $response = Get-DiagInput -id IT_GroupMembership
        if ($response[0] -eq "Apply")
        {
            $ad = [ADSI]"WinNT://$ENV:ComputerName"

            &{
                $group = $ad.Children.Find("HomeUsers", "Group")
                $user = $ad.Children.Find("$ENV:UserName", "User")
                $group.Add($user.Path)
                $group.SetInfo()
            }
            trap [Exception]
            {
                # Fail silentily if either the group or the user aren't found
                continue
            }
        }
    }

    "FirewallConfiguration" {
        Write-DiagProgress -activity $LocalizedStrings.RS_FirewallConfiguration

        $firewall = New-Object -COM HNetCfg.FwPolicy2
        foreach ($RuleGroup in $Global:FirewallRulesHomeNetwork.Values)
        {
            $firewall.EnableRuleGroup($Global:NET_FW_PROFILE2_PRIVATE, $RuleGroup, $true)
        }

        # Certain firewall rules are only enabled when we are joined to a HomeGroup
        if (Test-HomeGroupName)
        {
            $firewall.EnableRuleGroup($Global:NET_FW_PROFILE2_PRIVATE, $Global:FirewallRuleHomeGroup)

            # File sharing firewall rules are only enabled on non-domain-joined machines and non-ARM machines
            if (-not(IsDomainJoined) -and (env:PROCESSOR_ARCHITECTURE -ne "ARM"))
            {
                [bool]$enabled = $firewall.IsRuleGroupEnabled($Global:NET_FW_PROFILE2_PRIVATE, $Global:FirewallRulesSharing["File and Printer Sharing"])

                foreach ($RuleGroup in $Global:FirewallRulesSharing.Values)
                {
                    $firewall.EnableRuleGroup($Global:NET_FW_PROFILE2_PRIVATE, $RuleGroup, $true)
                }

                # Only republish if File and Printer Sharing was disabled and we successfully enabled it
                if (-not($enabled) -and $firewall.IsRuleGroupEnabled($Global:NET_FW_PROFILE2_PRIVATE, $Global:FirewallRulesSharing["File and Printer Sharing"]))
                {
                    RepublishItemsFromOfflineCache
                }
            }
        }
    }

    "IssuesFixed" {
        # This is a dummy resolver - do nothing
    }

    "UserIdentifiedIssues" {
        # This is a dummy resolver - do nothing
    }

    default {
        $checked = $false
        throw "RootCause not found. `$RootCause = $RootCause"
    }
}