# Copyright © 2008, Microsoft Corporation. All rights reserved.

$netListMgrInteropDllPath = "$ENV:SystemRoot\diagnostics\system\HomeGroup\Microsoft-Windows-HomeGroupDiagnostic.NetListMgr.Interop.dll"
[Reflection.Assembly]::LoadFile($netListMgrInteropDllPath);

function NumNetworks()
{
    return [Microsoft.Windows.Diagnosis.NetListManager]::NumberOfNetworksConnected()
}

function CheckForHomeNetwork()
{
    return [Microsoft.Windows.Diagnosis.NetListManager]::ConnectedToAHomeNetwork()
}

function CheckForDomainNetwork()
{
    return [Microsoft.Windows.Diagnosis.NetListManager]::ConnectedToADomainNetwork()
}

function SetNetworkToHome()
{
    [Microsoft.Windows.Diagnosis.NetListManager]::SetAllConnectedNetworksHome()
}