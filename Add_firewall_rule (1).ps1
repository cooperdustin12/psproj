[CmdletBinding()]
Param (
	[Parameter(Mandatory = $false, Position = 1)]
	[String]$defaultWinRMPort = "5986",
	[Parameter(Mandatory = $false, Position = 2)]
	[String]$firewallRuleName = "Windows Remote Management HTTP/SSL"
)

function Add-FirewallRule {
	param($name, $tcpPorts, $appName = $null, $serviceName = $null);
		
	$fw = New-Object -ComObject hnetcfg.fwpolicy2;
	$rule = New-Object -ComObject HNetCfg.FWRule;
	        
	$rule.Name = $name;
	if ($appName -ne $null) { $rule.ApplicationName = $appName };
	if ($serviceName -ne $null) { $rule.serviceName = $serviceName };
	$rule.Protocol = 6; # NET_FW_IP_PROTOCOL_TCP
	$rule.LocalPorts = $tcpPorts;
	$rule.Enabled = $true;
	$rule.Grouping = "@firewallapi.dll,-23255";
	$rule.Profiles = 7; # all
	$rule.Action = 1; # NET_FW_ACTION_ALLOW
	$rule.EdgeTraversal = $false;
	    
	$fw.Rules.Add($rule);
}

Add-FirewallRule $firewallRuleName $defaultWinRMPort $null $null;