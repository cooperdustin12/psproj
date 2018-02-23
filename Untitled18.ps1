Get-ADComputer -Filter { Name -like "*" } `
  -SearchBase "OU=Servers,DC=CBN,DC=com" |
  Select-Object -ExpandProperty Name | Sort-Object |
  Get-Uptime