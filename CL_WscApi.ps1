# Copyright © 2008, Microsoft Corporation. All rights reserved.

function Check-Firewall([ref]$FirewallName)
{
    [bool]$issueDetected = $false
    $firewalls = [Microsoft.Windows.Diagnosis.FirewallApi]::Firewalls

    foreach ($fw in $firewalls)
    {
        $owner = [Microsoft.Windows.Diagnosis.FirewallApi]::GetProductOwner($fw)
        if ($owner -ne [Microsoft.Windows.Diagnosis.ProductOwners]::Windows)
        {
            $state = [Microsoft.Windows.Diagnosis.FirewallApi]::GetProductState($fw)
            if ($state -eq [Microsoft.Windows.Diagnosis.ProductStates]::Enabled)
            {
                $issueDetected = $true
                $FirewallName.Value = $fw.ProductName
                break
            }
        }
    }
    return $issueDetected
}