# Copyright © 2017, Microsoft Corporation. All rights reserved.
# ============================================================
# Load Utilities
# ============================================================
. .\CL_Service.ps1

# ============================================================= 
# Main
# =============================================================

$rcdetected = $true
$checkState = SideBySide
$imgState = $checkState::GetImageState()

if($imgState -eq 1)
{
	$rcdetected = $false
}

Update-DiagRootCause -Id RC_SideBySideCorruption -Detected $rcdetected