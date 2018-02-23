# Copyright © 2017, Microsoft Corporation. All rights reserved.
# ============================================================
# Load Utilities
# ============================================================
. .\CL_Service.ps1

# =============================================================
# Initialize
# =============================================================
Import-LocalizedData -BindingVariable RS_SideBySideCorruption_LocalizedStrings -FileName CL_LocalizationData

# ============================================================= 
# Main
# =============================================================
Write-DiagProgress -Activity $RS_SideBySideCorruption_LocalizedStrings.ID_dism_check -Status $RC_SideBySideCorruption_LocalizedStrings.ID_pending_updates_status


$RepairSxS = Repair-WindowsImage –Online -RestoreHealth 

