$groups = Get-EventLog -LogName "System" -ComputerName VBMPRDOM246.cbn.local -EntryType Warning -Message "*10.100.140.0*" -After ((Get-Date).Date.AddDays(-60)) |
  Group-Object {$_.TimeWritten.Date}

foreach ($grp in $groups) { $grp.Group | fl |
  Write-Host $groups }


  $EventCount=0; Get-EventLog -LogName "System" -ComputerName VBMPRDOM246.cbn.local -EntryType Warning -Message "*10.100.140.0*" -After ((Get-Date).Date.AddDays(-60)) | foreach{$_;$EventCount++}|Out-Null;"Total Events is:"+$EventCount