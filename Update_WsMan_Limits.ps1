[CmdletBinding()]
Param (
	[Parameter(Mandatory = $false, Position = 1)]
	[Int32]$maxConcurrentUsersDefaultValue = 5,
	[Parameter(Mandatory = $false, Position = 2)]
	[Int32]$maxShellsPerUserDefaultValue = 5,
	[Parameter(Mandatory = $false, Position = 3)]
	[Int32]$maxMemoryPerShellMBDefaultValue = 150,
	[Parameter(Mandatory = $false, Position = 4)]
	[Boolean]$serviceRestartRequired = $false
)

function Update-WsMan-Limits {
	param
	(
		[Int32]$maxConcurrentUsersDefaultValue,
		[Int32]$maxShellsPerUserDefaultValue,
		[Int32]$maxMemoryPerShellMBDefaultValue,
		[Boolean]$serviceRestartRequired
	)
	
	$winRM = Get-Item WSMan:\localhost\Shell\* | Select-Object Name,Value;

	[int]$maxUsers = $WinRM | Where-Object {$_.Name -eq "MaxConcurrentUsers"} | Select -ExpandProperty Value;
	Write-Output "PowerShell quota management - 'MaxConcurrentUsers' current value: $($maxUsers)";

	if ($maxUsers -le $maxConcurrentUsersDefaultValue) {
		$maxUsers = $maxUsers + 20;
		Set-Item WSMan:\localhost\Shell\MaxConcurrentUsers $maxUsers -WarningAction SilentlyContinue;
		Write-Output "PowerShell quota management - has increased 'MaxConcurrentUsers' value up to: $($maxUsers)";
		$serviceRestartRequired = $true;
	}

	[int]$maxShells = $winRM | Where-Object {$_.Name -eq "MaxShellsPerUser"} | Select -ExpandProperty Value;
	Write-Output "PowerShell quota management - 'MaxShellsPerUser' current value: $($maxShells)";

	if ($maxShells -le $maxShellsPerUserDefaultValue) {
		$maxShells = $maxShells + 20;
		Set-Item WSMan:\localhost\Shell\MaxShellsPerUser $maxShells -WarningAction SilentlyContinue;
		Write-Output "PowerShell quota management - has increased 'MaxShellsPerUser' value up to: $($maxShells)";
		$serviceRestartRequired = $true;
	}

		[int]$maxMemory = $WinRM | Where-Object {$_.Name -eq "MaxMemoryPerShellMB"} | Select -ExpandProperty Value;
		Write-Output "PowerShell quota management - 'MaxMemoryPerShellMB' current value: $($maxMemory)";

	If ($maxMemory -le $maxMemoryPerShellMBDefaultValue) {
		$maxMemory = 512;
		Set-Item WSMan:\localhost\Shell\MaxMemoryPerShellMB $maxMemory -WarningAction SilentlyContinue;
		Write-Output "PowerShell quota management - has increased 'MaxMemoryPerShellMB' value up to: $($maxMemory)";
		$serviceRestartRequired = $true;
	}

	if ($serviceRestartRequired) {
		# Once the changes have been made, we should stop and restart the WinRM service
		Write-Output "PowerShell quota management - restarting WinRM service...";
		Restart-Service WinRM -force;
	}
}

Update-WsMan-Limits $maxConcurrentUsersDefaultValue $maxShellsPerUserDefaultValue $maxMemoryPerShellMBDefaultValue $serviceRestartRequired;