# Copyright © 2017, Microsoft Corporation. All rights reserved.
# ============================================================
# Load Utilities
# ============================================================
. .\CL_Service.ps1

# =============================================================
# Initialize
# =============================================================
Import-LocalizedData -BindingVariable RC_SideBySideCorruption_LocalizedStrings -FileName CL_LocalizationData

# ============================================================= 
# Main
# =============================================================

$rcdetected = $false
$checkStatus = Repair-WindowsImage -Online -ScanHealth

if(!$checkStatus.ImageHealthState -eq "Healthy")
{
	$rcdetected = $true;
}

Update-DiagRootCause -Id RC_SideBySideCorruption -Detected $rcdetected
