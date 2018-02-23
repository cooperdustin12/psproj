$svcs = Get-Service;

$running = @();
$svcs | Where-Object {$_.Status -eq "Running"} | ForEach-Object {
	$running += [String]::Format("{0} ({1})", $_.Name, $_.DisplayName);
}
$stopped = @();
$svcs | Where-Object {$_.Status -eq "Stopped"} | ForEach-Object {
	$stopped += [String]::Format("{0} ({1})", $_.Name, $_.DisplayName);
}

Write-Host "Statistic.RunningServices: $($running.Length)";
Write-Host "Message.RunningServices: $([String]::Join(", ", $running))";

Write-Host "Statistic.StoppedServices: $($stopped.Length)";
Write-Host "Message.StoppedServices: $([String]::Join(", ", $stopped))";

Exit (0)
