# Copyright © 2008, Microsoft Corporation. All rights reserved.


# param: $ServiceName
# value: PeerNetworkingGrouping
#        HomeGroupProvider

param($ServiceName)

. .\CL_Service.ps1

Import-LocalizedData -BindingVariable LocalizedStrings -FileName CL_LocalizationData

Write-DiagProgress -activity $LocalizedStrings."RS_$ServiceName"

switch ($ServiceName)
{
    "PeerNetworkingGrouping" {
        FixService "p2psvc"
    }

    "HomeGroupProvider" {
        FixService "netprofm"
        FixService "fdPHost"
        FixService "FDResPub"
        FixService "HomeGroupProvider"
    }

    default {
        throw "ServiceName not found. `$ServiceName = $ServiceName"
    }
}