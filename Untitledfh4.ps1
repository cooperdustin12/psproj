Select-String -Path "C:\tmp\dhcp\DhcpSrvLog-Tue.log" -Pattern "10.100.35.246" 


Get-ChildItem -recurse -Include C:\tmp\dhcp\DhcpSrvLog-Tue.log | 
where { $_ | Select-String -pattern ('10.100.35.246') -SimpleMatch}