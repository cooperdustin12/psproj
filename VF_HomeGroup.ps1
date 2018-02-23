# Copyright © 2008, Microsoft Corporation. All rights reserved.


# param: $RootCause
# value: PeerNetworkingGrouping
#        HomeGroupProvider
#        MultipleNetworks
#        NetworkIsPublic
#        IPv6
#        InformationCorruption
#        Permissions
#        GroupMembership
#        FirewallConfiguration
#        HomeGroupNotConnected
#        IssuesFixed
#        UserIdentifiedIssues

param($RootCause)

. .\CL_Detection.ps1

switch ($RootCause)
{
    "IssuesFixed" {
        Update-DiagRootCause -id RC_IssuesFixed -Detected $false
     }

    "UserIdentifiedIssues" {
        $problem = Get-DiagInput -id IT_WhatProblem
        switch ($problem[0])
        {
            "Others" {
                $result = Get-DiagInput -id IT_Others
                if ($result[0] -eq "No")
                {
                    $result = Get-DiagInput -id IT_RunOnRemote
                }
            }

            "My" {
                if (IsDomainJoined)
                {
                    $result = Get-DiagInput -id IT_Domain
                }
                elseif (env:PROCESSOR_ARCHITECTURE -eq "ARM")
                {
                    $result = Get-DiagInput -id IT_Version
                }
                else
                {
                    $result = Get-DiagInput -id IT_RunOnRemote
                }
            }

            "Sharing" {
                if (IsDomainJoined)
                {
                    $result = Get-DiagInput -id IT_Domain
                }
                elseif (env:PROCESSOR_ARCHITECTURE -eq "ARM")
                {
                    $result = Get-DiagInput -id IT_Version
                }
                else
                {
                    $result = Get-DiagInput -id IT_CantShare
                }
            }

            "Printer" {
                $result = Get-DiagInput -id IT_Printer
                if ($result[0] -eq "Yes")
                {
                    Write-DiagProgress -Activity $LocalizedStrings.TS_PrinterDiagnostics
                    Start-Process -Wait -FilePath "$ENV:SystemRoot\System32\msdt.exe" -ArgumentList @("-skip", "-force", "-id", "PrinterDiagnostic")
                }
            }

            default {
                throw "Unexpected problem. '$Problem = $Problem"
            }
        }

        if ($result[0] -eq "Yes")
        {
            Update-DiagRootCause -id RC_UserIdentifiedIssues -Detected $false
        }
        else
        {
            Update-DiagRootCause -id RC_UserIdentifiedIssues -Detected $true
            Get-DiagInput -id IT_DepartAndRejoin
        }
    }

    default {
        (Check-RootCause $RootCause)
    }
}