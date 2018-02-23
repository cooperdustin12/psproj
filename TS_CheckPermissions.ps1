# Copyright © 2008, Microsoft Corporation. All rights reserved.

# Check permissions on the indexer data directories.

# Load utility library
. .\CL_Utility.ps1

Write-DiagProgress -activity $localizationString.progress_ts_checkPermissions

$dataDirectory = (Get-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Windows Search").DataDirectory
$obj = ConvertStringToPSObject "dataDirectory" $dataDirectory
$obj | select-object -Property @{Name=$localizationString.dataDirectory_name; Expression={$_.dataDirectory}} | convertto-xml | Update-DiagReport -id DataDirectory -name $localizationString.dataDirectory_name -description $localizationString.dataDirectory_description -verbosity Informational

# First check that owner is SYSTEM
$acl = get-acl $dataDirectory
[bool]$ownerOK = ($acl.Owner -eq  "NT AUTHORITY\SYSTEM")

[bool]$accessOK = $true
# Verify that Administrators have read and write access
$accessOK = $accessOK -and (Get-AccessGranted $dataDirectory "S-1-5-32-544" $GENERIC_READ -bor $GENERIC_WRITE)
# Verify that Users have neither read nor write access
$accessOK = $accessOK -and -not(Get-AccessGranted $dataDirectory "S-1-5-32-545" $GENERIC_READ)
$accessOK = $accessOK -and -not(Get-AccessGranted $dataDirectory "S-1-5-32-545" $GENERIC_WRITE)
# Verify that LOCAL SYSTEM has full control
$accessOK = $accessOK -and (Get-AccessGranted $dataDirectory "S-1-5-18" $GENERIC_ALL)

if (-not ($ownerOK -and $accessOK))
{
    Update-DiagRootCause -id "RC_BadPermissions" -Detected $true
    if (-not $ownerOK)
    {
        $acl.Owner  | convertto-xml | Update-DiagReport -id BadPermissions -name $localizationString.dataDirectoryPermissions_name -description $localizationString.dataDirectoryPermissions_description -verbosity Error -rid "RC_BadPermissions"
    }
    if (-not $accessOK)
    {
        $aces = $acl | foreach-object -process {$_.Access}
        $aces | convertto-xml | Update-DiagReport -id BadPermissions -name $localizationString.dataDirectoryPermissions_name -description $localizationString.dataDirectoryPermissions_description -verbosity Error -rid "RC_BadPermissions"
    }
}
else
{
    Update-DiagRootCause -id "RC_BadPermissions" -Detected $false
}
