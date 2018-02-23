$proc = (Get-Process | Sort-Object -Property CPU -Descending)[0];
$info = [String]::Format("PID: {0}; Name: {1}; Company: {2}", $proc.Id, $proc.ProcessName, $proc.Company);

Write-Host "Message.Cpu: Cpu - $($info)";
Write-Host "Statistic.Cpu: $($proc.CPU)";

Write-Host "Message.PM: PM - $($info)";
Write-Host "Statistic.PM: $($proc.PM)";

Write-Host "Message.VM: VM - $($info)";
Write-Host "Statistic.VM: $($proc.VM)";

Exit(0);