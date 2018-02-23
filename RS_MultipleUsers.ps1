# Copyright © 2008, Microsoft Corporation. All rights reserved.


#
# Log other users off of the system
#

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData
. .\CL_Utility.ps1

Write-DiagProgress -activity $localizationString.progress_rs_multipleUsers

$userInfoArray = GetLogonUsersInfo

if($userInfoArray -eq $null -or $userInfoArray.Count -lt 2)
{
    return
}

[string]$SESSOIN_ID = "sessionID"
[string]$USER_NAME = "userName"

$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
if ($currentUser -eq $null) {
    return
}

#
# Ask the user which users need be logged off
#
$choices = New-Object System.Collections.ArrayList

for([int]$i = 0; $i -lt $userInfoArray.Count; $i++)
{
    $ht = $userInfoArray[$i]
    if($ht -eq $null) {
        Continue
    }

    $userName = $ht["$USER_NAME"]
    if($userName -eq $currentUser)
    {
        Continue
    }
    $value = $ht["$SESSOIN_ID"]
    $choices += @{"Name" = "$userName"; "Description" = "$userName"; "Value" = "$value"}
}

if ($choices.Length -ge 1) {
    $sessionIDArray = Get-DiagInput -id "IT_MultipleUsers" -choice $choices
}
#
# Logs off a specified Terminal Services session.
#

if($sessionIDArray -ne $null)
{
$logoffDefinition = @"
    [DllImport("wtsapi32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool WTSLogoffSession(IntPtr hServer, int SessionId, [MarshalAs(UnmanagedType.Bool)] bool bWait);
"@
    $logoffType = Add-Type -MemberDefinition $logoffDefinition -Name "logoffType" -UsingNamespace "System.Reflection","System.Diagnostics" -PassThru

    [string]$fileName = "RS_MultipleUsers"

    foreach($sessionID in $sessionIDArray)
    {
        [bool]$result = $logoffType::WTSLogoffSession([IntPtr]::Zero, $sessionID, $true)
        [int]$errorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
        if(-not $result)
        {
            WriteFileAPIExceptionReport $fileName "WTSLogoffSession" $errorCode
            return
        }
    }

    #
    # update report
    #
    $userArray = New-Object System.Collections.ArrayList
    for([int]$i = 0; $i -lt $userInfoArray.Count; $i++)
    {
        foreach($sessionID in $sessionIDArray)
        {
            if($userInfoArray[$i][$SESSOIN_ID] -eq $sessionID)
            {
                $userArray += $userInfoArray[$i][$USER_NAME]
            }
        }
    }
    $userArray | select-object -Property @{Name=$localizationString.multipleUsers_userName; Expression={$_}} | convertto-xml | Update-DiagReport -id LogoffUser -name $localizationString.logoffUser_name -verbosity Informational
}
