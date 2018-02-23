

# 2014-07-21 Node Unmanage script for SolarWinds SDK Powershell

# by Joe Dissmeyer | Thwack - @JoeDissmeyer | Twitter - @JoeDissmeyer | www.joedissmeyer.com

# This script will unmanage a single node in the Orion database. First, it finds the node number in the Orion database, then it will unmanage it for 99 years.

# This script assumes you are running it LOCALLY from an already managed node AND that the machine has the Orion SDK v1.9 installed on it.

# If the machine is not already managed in SolarWinds this script will fail without warning.

# Replace ORIONSERVERNAME with the appropriate values.

# ORIONSERVERNAME = Your Orion poller instance. (Ex. 'SOLARWINDS01.DOMAIN.LOCAL'). Single quotes are important.

 

# Load the SolarWinds Powershell snapin. Needed in order to execute the script. Requires the Orion SDK 1.9 installed on the machine this script is running from.

Add-PSSnapin SwisSnapin

 

 

# SolarWinds user name and password section. Create an Orion local account that only has node management rights. Enter the user name and password here.

$username = "NTD1\dscoop"

$password = "#$ERDFCV34erdfcv"

 

# This section allows the password to be embedded in this script. Without it the script will not work.

$secstr = New-Object -TypeName System.Security.SecureString

$password .ToCharArray() | ForEach-Object {$secstr.AppendChar($_)}

$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username,$secstr

 

# The actual job

$ORIONSERVERNAME = 'nms.cbn.local'

$nodename = $env:COMPUTERNAME

 

$swis = Connect-Swis -Credential $cred -host $orionservername

$nodeid = Get-SwisData $swis "SELECT NodeID FROM Orion.Nodes WHERE SysName LIKE '$nodename%'"

$now =[DateTime ]:: Now

$later =$now.AddYears(99)

Invoke-SwisVerb $swis Orion.Nodes Unmanage @("N: $nodeid ", $now ,$later , "false")

 