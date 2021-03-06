# Copyright © 2008, Microsoft Corporation. All rights reserved.

PARAM($printerName)
#
# Share the specified printer
#
Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData
Write-DiagProgress -activity $localizationString.progress_rs_homeGroup

. .\CL_Utility.ps1


function EnablePrinterSharing()
{
	# NET_FW_PROFILE_TYPE2 Enumeration
	$Global:NET_FW_PROFILE2_PRIVATE = 0x0002

	$Global:FirewallRulesHomeNetwork = @{"Core Networking" = "@FirewallAPI.dll,-25000";    # IDS_FW_CORENET_GROUP
									 "Network Discovery" = "@FirewallAPI.dll,-32752"}    # IDS_FW_NETDIS_GROUP

	$firewall = New-Object -COM HNetCfg.FwPolicy2

	foreach ($RuleGroup in $Global:FirewallRulesHomeNetwork.Values)
	{
		$firewall.EnableRuleGroup($Global:NET_FW_PROFILE2_PRIVATE, $RuleGroup, $true)
	}


	$Global:FirewallRulesSharing     = @{"File and Printer Sharing" = "@FirewallAPI.dll,-28502";  }    # IDS_FW_FPS_GROUP
				  

	foreach ($RuleGroup in $Global:FirewallRulesSharing.Values)
	{
		$firewall.EnableRuleGroup($Global:NET_FW_PROFILE2_PRIVATE, $RuleGroup, $true)
	}
}
try{
EnablePrinterSharing

Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\HomeGroup\PrintingPreferences" "Printers" 1

[int]$PRINTER_ATTRIBUTE_SHARED = 0x00000008
SetPrinterAttributes $printerName $PRINTER_ATTRIBUTE_SHARED
}
catch [System.Exception]
{
	Write-ExceptionTelemetry "MAIN" $_
}
