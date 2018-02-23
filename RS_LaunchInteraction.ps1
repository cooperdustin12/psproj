# Copyright © 2008, Microsoft Corporation. All rights reserved.

# param: $RootCause
# value: MultipleNetworks
#        IPv6
#        Firewall
#        HomeGroupNotConnected

param($RootCause)

. .\CL_NativeMethods.ps1
. .\CL_Detection.ps1

switch ($RootCause)
{
    "MultipleNetworks" {
        Get-DiagInput -id IT_MultipleNetworks
    }

     "IPv6" {
        Get-DiagInput -id IT_IPv6
    }

    "Firewall" {
        # This is a dummy resolver - do nothing
    }

    "HomeGroupNotConnected" {
        [string]$FirewallName = ""
        $detected = Check-Firewall([ref]$FirewallName)
        if ($detected)
        {
            if ($FirewallName.Length -gt 0)
            {
                $FirewallInteractionName = ($LocalizedStrings.DSP_RS_FirewallTitle_Name -f $FirewallName)
            }
            else
            {
                $FirewallInteractionName = $LocalizedStrings.DSP_RS_FirewallTitle
            }
        }

        $result = Get-DiagInput -id IT_CreateOrJoin
        if ($result[0] -eq "Create")
        {
            if (IsDomainJoined)
            {
                Get-DiagInput -id IT_HomeGroupNotConnectedDomain
            }       
            else
            {
                if ((env:PROCESSOR_ARCHITECTURE -eq "ARM") -or -not(SkuCanCreate))
                {
                    Get-DiagInput -id IT_HomeGroupNotConnectedVersion
                }
                else
                {
                    if ($detected)
                    {
                        Get-DiagInput -id IT_Firewall -Parameter @{"FirewallInteractionName" = $FirewallInteractionName}
                    }
                    Get-DiagInput -id IT_HomeGroupNotConnected
                }
            }
        }
        else
        {
            $result = Get-DiagInput -id IT_TimeDate
            if ($result -eq "No")
            {
                if ($detected)
                {
                    Get-DiagInput -id IT_Firewall -Parameter @{"FirewallInteractionName" = $FirewallInteractionName}
                }
                Get-DiagInput -id IT_RunOnRemoteThenJoin
            }
        }
    }

    default {
        throw "RootCause not found. `$RootCause = $RootCause"
    }
}