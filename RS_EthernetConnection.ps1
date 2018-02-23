# Copyright © 2017, Microsoft Corporation. All rights reserved.
# :: ======================================================= ::
#====================================================================================
# Initialize
#====================================================================================
Import-LocalizedData -BindingVariable Strings_EthernetConnection -FileName CL_LocalizationData

#====================================================================================
# Load Utilities
#====================================================================================
. .\CL_Utility.ps1

#====================================================================================
# Main
#====================================================================================

$strINTDesc = $Strings_EthernetConnection.ID_SecondaryDevConnected

$choices = Get-DiagInput -ID "IT_EthernetConnection" -Parameter @{'INT_Desc' = $strINTDesc;}

if($choices -eq 1)
{
	$strINTDesc = $Strings_EthernetConnection.ID_CablePlugged
	$choices = Get-DiagInput -ID "IT_EthernetConnection" -Parameter @{'INT_Desc' = $strINTDesc;}
	if($choices -eq 0)
	{
		$strINTDesc = $Strings_EthernetConnection.ID_Cablelights
		$choices = Get-DiagInput -ID "IT_EthernetConnection" -Parameter @{'INT_Desc' = $strINTDesc;}
		if($choices -eq 0)
		{
			$strINTDesc = $Strings_EthernetConnection.ID_LightColor
			$choices = Get-DiagInput -ID "IT_EthernetConnection" -Parameter @{'INT_Desc' = $strINTDesc;}
			if($choices -eq 0)
			{
				Write-DiagTelemetry -Property "EthernetConnection:CableNoLight" -Value "Yes"

				$strINTDesc = $Strings_EthernetConnection.ID_NoLight
				Get-DiagInput -ID "INT_EthernetConnection" -Parameter @{'INT_Desc' = $strINTDesc;}
				
				$strINTDesc = $Strings_EthernetConnection.ID_BadCard
				Get-DiagInput -ID "INT_EthernetConnection" -Parameter @{'INT_Desc' = $strINTDesc;}
				
			}
			else
			{
				$strINTDesc = $Strings_EthernetConnection.ID_ModemConnection
				Get-DiagInput -ID "INT_EthernetConnection" -Parameter @{'INT_Desc' = $strINTDesc;}

				$strINTDesc = $Strings_EthernetConnection.ID_CableDamaged
				$choices = Get-DiagInput -ID "IT_EthernetConnection" -Parameter @{'INT_Desc' = $strINTDesc;}
				if($choices -eq 0)
				{
					Write-DiagTelemetry -Property "EthernetConnection:CableDamaged" -Value "No"
					$strINTDesc = $Strings_EthernetConnection.ID_ChangePort
					$choices = Get-DiagInput -ID "IT_EthernetConnection" -Parameter @{'INT_Desc' = $strINTDesc;}
					if($choices -eq 0)
					{
						$strINTDesc = $Strings_EthernetConnection.ID_ResetNetwork
						$strLink = $Strings_EthernetConnection.ID_Link_ResetNetwork
						Get-DiagInput -ID "INT_EthernetConnection_Link" -Parameter @{'INT_Desc' = $strINTDesc;'URL' = $strLink}
					}
					else
					{
						Write-DiagTelemetry -Property "EthernetConnection:ChangePortSolved" -Value "Yes"
					}
				}
				else
				{
					Write-DiagTelemetry -Property "EthernetConnection:CableDamaged" -Value "Yes"
					$strINTDesc = $Strings_EthernetConnection.ID_ReplaceCable
					Get-DiagInput -ID "INT_EthernetConnection" -Parameter @{'INT_Desc' = $strINTDesc;}
				}
			}
		}
		else
		{
			Write-DiagTelemetry -Property "EthernetConnection:CablePluggedGreen" -Value "Yes"
		}		
	}
	else
	{
		Write-DiagTelemetry -Property "EthernetConnection:CablePluggedFirmly" -Value "Yes"
	}
}
else
{
	#Drop to rebooting the router/modem
	Write-DiagTelemetry -Property "EthernetConnection:ModemRebooting" -Value "Yes"
}
