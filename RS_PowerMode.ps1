# Copyright © 2008, Microsoft Corporation. All rights reserved.

#
# Set the power mode to balanced
#
Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData
. .\CL_Utility.ps1

Write-DiagProgress -activity $localizationString.progress_rs_powerMode

SetBalancedPowerPlan