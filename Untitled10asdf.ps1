$userProfiles = Get-CimInstance -Class Win32_UserProfile |
  # add property "UserName" that translates SID to username
  Add-Member -MemberType ScriptProperty -Name UserName -Value { 
    ([Security.Principal.SecurityIdentifier]$this.SID).Translate([Security.Principal.NTAccount]).Value
  } -PassThru |
  # create a hash table that uses "Username" as key
  Group-Object -Property UserName -AsHashTable -AsString

  $userProfiles.Keys | Sort-Object