# Copyright © 2008, Microsoft Corporation. All rights reserved.


#
# Check multiple users
#

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData
. .\CL_Utility.ps1

Write-DiagProgress -activity $localizationString.progress_ts_multipleUsers

[string]$USER_NAME = "userName"

$userInfoArray = GetLogonUsersInfo

if($userInfoArray.Count -gt 1 -and $userInfoArray[0] -ne $null)
{
    Update-DiagRootCause -id "RC_MultipleUsers" -Detected $true
} else {
    Update-DiagRootCause -id "RC_MultipleUsers" -Detected $false
}

$userInfoArray | select-object -Property @{Name=$localizationString.multipleUsers_userName; Expression={$_[$USER_NAME]}} | convertto-xml | Update-DiagReport -id LogonUser -name $localizationString.logonUser_name -verbosity Informational -rid "RC_MultipleUsers"