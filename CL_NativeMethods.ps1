# Copyright © 2008, Microsoft Corporation. All rights reserved.

function SkuCanCreate()
{
    return [Microsoft.Windows.Diagnosis.NativeMethods]::SkuCanCreate()
}

function IsDomainJoined()
{
    return [Microsoft.Windows.Diagnosis.NativeMethods]::IsDomainJoined()
}

function RepublishItemsFromOfflineCache()
{
    [Microsoft.Windows.Diagnosis.WebServicesDiscoveryPublisher]::RepublishItemsFromOfflineCache()
}