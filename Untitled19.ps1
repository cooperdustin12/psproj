$yesterday = (Get-Date).AddHours(-24)
$ErrWarn4App = Get-WinEvent -FilterHashTable @{LogName='Application','System'; Level=2,3; StartTime=$yesterday} -ErrorAction SilentlyContinue | Select-Object TimeCreated,LogName,ProviderName,Id,LevelDisplayName,Message
$ErrWarn4App | Sort TimeCreated | ft -AutoSize 