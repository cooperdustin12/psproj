# Copyright © 2008, Microsoft Corporation. All rights reserved.

trap { break }

#
# Check whether devices are running in PIO mode.
#

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

Write-DiagProgress -activity $localizationString.progress_ts_pioMode

[string]$IDEChannel = "HKLM:\SYSTEM\CurrentControlSet\Enum\PCIIDE\IDEChannel\"

[bool]$result = $false

if((Test-Path $IDEChannel) -eq $true)
{
	$IDEs = get-childItem -path $IDEChannel

	$IDEArray = New-Object System.Collections.ArrayList
	foreach ($IDE in $IDEs)
	{
		[string]$itemPath = $IDE.psPath + "\Device Parameters"
		$target = (get-childItem -path "$itemPath") | where { $_.PSChildName -eq "Target0" }
		if($target -ne $null -and (Get-ItemProperty $target.PSPath).UserTimingModeAllowed -eq 0x1f)
		{
			$result = $true
			$IDEArray += (Get-ItemProperty $IDE.PSPath).FriendlyName
		}
	}
}

if($result)
{
    Update-DiagRootCause -id "RC_PIOMode" -Detected $true
   $IDEArray | select-object -Property @{Name=$localizationString.pioModeIDE_friendlyName; Expression={$_}} | convertto-xml | Update-DiagReport -id PIOModeIDE -name $localizationString.pioModeIDE_name -description $localizationString.pioModeIDE_description -verbosity Error -rid "RC_PIOMode"
} else {
    Update-DiagRootCause -id "RC_PIOMode" -Detected $false
}
