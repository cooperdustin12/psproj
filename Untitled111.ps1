cls


Write-Host 1. Enter Remote PSSession
Write-Host 2. Find the top five processes using the most memory
Write-Host 3. Cycle a service "(stop, and then restart it)" like DHCP
Write-Host 4. Restart a Remote Windows Machine
Write-Host 5. Get Event Log
Write-Host 6. Get information about the make and model of a computer
Write-Host 7. List installed hotfixes -- QFEs, or Windows Update files
Write-Host 8. Get the username of the person currently logged on to a computer 
Write-Host 9. Find just the names of installed applications on the current computer 
Write-Host 10. Get IP addresses assigned to the current computer 
Write-Host 11. Get a more detailed IP configuration report for the current machine
Write-Host 12. Ping 
Write-Host 13. Tracert
Write-Host 14. Netstat 
Write-Host 15. TODO


$RH = Read-Host -Prompt "Enter the number associated with the function you'd like to perform" 



if($RH -eq '1')
{ 
$PC = Read-Host -Prompt 'Input Machine Name'
$Cred = Read-Host -Prompt 'Enter "NTD1\USERNAME" here and press "Enter'
Enter-PSSession -ComputerName $PC -Credential $Cred }


elseif($RH -eq '2')
{ 
$PC = Read-Host -Prompt 'Input Machine Name'
ps -ComputerName $PC | sort –p ws | select –last 5 }



elseif($RH -eq '3')
{ 
$Service = Read-Host -Prompt 'Input Service Name Here'
$PC = Read-Host -Prompt 'Input Machine Name'
$Status = Read-Host -Prompt ' Set Desired Status (Running,Stopped,Paused)'
Get-Service -Name $Service -ComputerName $PC  | Set-Service -Status $Status }


elseif($RH -eq '4')
{ 
$PC = Read-Host -Prompt 'Input Machine Name'
$Cred = Read-Host -Prompt 'Enter "NTD1\USERNAME" here and press "Enter'
Restart-Computer -ComputerName $PC -force -Credential
}


elseif($RH -eq '5')
{ 
$PC = Read-Host -Prompt 'Input Machine Name'
$log = Read-Host -Prompt 'Input Log Source'
Get-EventLog -Logname $log  -ComputerName $PC -Newest 10
}

elseif($RH -eq '6')
{ 
$PC = Read-Host -Prompt 'Input Machine Name'
Get-WmiObject -Class Win32_ComputerSystem -ComputerName $PC
}


else
{ Start-Sleep -Milliseconds 10 }










# Common entries

# 1. Enter Remote PSSession
$1 = Enter-PSSession -ComputerName VBMDESQL788 -Credential ntd1\nocmonitoring


# 2. Find the five processes using the most memory:
$2 = ps -ComputerName $PC | sort –p ws | select –last 5


#Navigate the Windows Registry like the file system:
cd hkcu:

# Search recursively for a certain string within files:
dir –r | select string "searchforthis"

# 3. Cycle a service (stop, and then restart it) like DHCP:
Restart-Service DHCP

# List all items within a folder:
Get-ChildItem – Force

# Recurse over a series of directories or folders:
Get-ChildItem –Force c:\directory –Recurse

# Remove all files within a directory without being prompted for each:
Remove-Item C:\tobedeleted –Recurse

# 4. Restart the current computer:
(Get-WmiObject -Class Win32_OperatingSystem -ComputerName .).Win32Shutdown(2)

#Stop Process
Stop-Process -processname calc*
Get-Process abc | Stop Process -force

#Get Services and HTML report or CSV
Get-Service | ConvertTo-HTML -Property Name, Status > C:\services.htm 
Get-Service | Select-Object Name, Status | Export-CSV c:\service.csv 

# 5. Get Event Log
Get-EventLog -Log $logname

#Get Drivers
DriverQuery -si

#Get Unsigned Drivers
DriverQuery -si | Select-String False


###############################################################################################################################################

#Collecting Information

# 6. Get information about the make and model of a computer:
Get-WmiObject -Class Win32_ComputerSystem

# Get information about the BIOS of the current computer:
Get-WmiObject -Class Win32_BIOS -ComputerName .

# 7. List installed hotfixes -- QFEs, or Windows Update files:
Get-WmiObject -Class Win32_QuickFixEngineering -ComputerName .

# 8. Get the username of the person currently logged on to a computer:
Get-WmiObject -Class Win32_ComputerSystem -Property UserName -ComputerName .

# 9. Find just the names of installed applications on the current computer:
Get-WmiObject -Class Win32_Product -ComputerName . | Format-Wide -Column 1

# 10. Get IP addresses assigned to the current computer:
Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE -ComputerName . | Format-Table -Property IPAddress

# 11 Get a more detailed IP configuration report for the current machine:
Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE -ComputerName . | Select-Object -Property [a-z]* -ExcludeProperty IPX*,WINS*

# Find network cards with DHCP enabled on the current computer:
Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter "DHCPEnabled=true" -ComputerName .

# Enable DHCP on all network adapters on the current computer:
Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=true -ComputerName . | ForEach-Object -Process {$_.EnableDHCP()}

#Show IP
Get-NetIPConfiguration

# 12 Ping
Test-NetConnection -ComputerName www.microsoft.com -InformationLevel Detailed
Test-NetConnection -ComputerName 172.30.0.10  | Select -ExpandProperty PingReplyDetails | FT Address, Status, RoundTripTime -Autosize
1..10 | % { Test-NetConnection -ComputerName 172.30.0.10 -RemotePort 162 } | FT -AutoSize

# 13 Tracert
Test-NetConnection www.microsoft.com –TraceRoute
Test-NetConnection outlook.com -TraceRoute | Select -ExpandProperty TraceRoute | % { Resolve-DnsName $_ -type PTR -ErrorAction SilentlyContinue }

# 14 Netstat
Get-NetTCPConnection | Group State, RemotePort | Sort Count | FT Count, Name -Autosize
Get-NetTCPConnection | ? State -eq Established | FT -Autosize
Get-NetTCPConnection | ? State -eq Established | ? RemoteAddress -notlike 127* | % { $_; Resolve-DnsName $_.RemoteAddress -type PTR -ErrorAction SilentlyContinue }

###################################################################################################################################################

#Software Management 

# Install an MSI package on a remote computer:
(Get-WMIObject -ComputerName TARGETMACHINE -List | Where-Object -FilterScript {$_.Name -eq "Win32_Product"}).Install(\\MACHINEWHEREMSIRESIDES\path\package.msi)

# Upgrade an installed application with an MSI-based application upgrade package:
(Get-WmiObject -Class Win32_Product -ComputerName . -Filter "Name='name_of_app_to_be_upgraded'").Upgrade(\\MACHINEWHEREMSIRESIDES\path\upgrade_package.msi)

# Remove an MSI package from the current computer:
(Get-WmiObject -Class Win32_Product -Filter "Name='product_to_remove'" -ComputerName . ).Uninstall()

#Last 10 Installed Updates
Get-WmiObject -Class Win32_QuickFixEngineering -ComputerName . | Sort -P InstalledOn | Select -Last 10 | Format-Table -Auto

######################################################################################################################################################

#Machine Management 

# Remotely shut down another machine after one minute:
Start-Sleep 60; Restart-Computer –Force –ComputerName TARGETMACHINE

# 15 Enter into a remote PowerShell session -- you must have remote management enabled:
enter-pssession TARGETMACHINE

#Get Current Logged in users
Get-WmiObject –ComputerName CLIENT1 –Class Win32_ComputerSystem | Select-Object UserName

# Use the PowerShell invoke command to run a script on a remote servers:
invoke-command -computername machine1, machine2 -filepath c:\Script\script.ps1

# Add a printer:
(New-Object -ComObject WScript.Network).AddWindowsPrinterConnection("\\printerserver\hplaser3")

# Remove a printer:
(New-Object -ComObject WScript.Network).RemovePrinterConnection("\\printerserver\hplaser3 ")





























#########################################################################################################################################################



#Test-PortConnectivity -Source '127.0.0.1' -RemoteDestination 'dc1' -Port 57766
#Test-PortConnectivity '127.0.0.1' 'dc1' 57766 -Protocol UDP -Iterate
#Test-PortConnectivity 'localhost' 'dc2' 51753 -Protocol UDP
#Test-PortConnectivity -Source $EUCAS -RemoteDestination $EUMBX -Port 135 -Iterate
#Test-PortConnectivity -Source 'localhost' -RemoteDestination '127.0.0.1' -Port 135 -Iterate -protocol TCP

Function Test-PortConnectivity()
{

Param
(
    [Parameter(Position=0)] $Source,
    [Parameter(Mandatory=$true,Position=1)] $RemoteDestination,
    [Parameter(Mandatory=$true,Position=2)][ValidateScript({
      
      If($_ -match "^[0-9]+$"){
      $True
      }
      else{
      Throw "A port should be a numeric value, and $_ is not a valid number"
      }
    })
    ]$Port,
    [Parameter(Position=3)][ValidateSet('TCP','UDP')] $Protocol = 'TCP',
    [Switch] $Iterate
)

    #If $source is a local name, invoke command is not required and we can test port, withhout credentials
    If($Source -like "127.*" -or $source -like "*$(hostname)*" -or $Source -like 'localhost')
    {
        Do
        {
                Telnet-Port $RemoteDestination $Port $Protocol;
                Start-Sleep -Seconds 1   #Initiate sleep to slow down Continous telnet

        }While($Iterate)
       
    }
    Else  #Prompt for credentials when Source is not the local machine.
    {     
        $creds = Get-Credential

        Do
        {
            Foreach($Src in $Source)
            {          
            Invoke-command -ComputerName $Src -Credential $creds -ScriptBlock ${Function:Telnet-Port} -ArgumentList $RemoteDestination,$port, $Protocol                                            
            }

            #Initiate sleep to slow down Continous telnet
            Start-Sleep -Seconds 1
        }While($Iterate)
       
    }

}
  
Function Telnet-Port($RemoteDestination, $port, $Protocol)
{
    foreach($Target in $RemoteDestination)
    {
            Foreach($CurrentPort in $Port)
            {
                If($Protocol -eq 'TCP')
                {
                    
                    try
                    {
                        If((New-Object System.Net.Sockets.TCPClient ($Target,$currentPort) -ErrorAction SilentlyContinue).connected)
                        {
                            Write-host "$((hostname).toupper()) connected to $($Target.toupper()) on $Protocol port : $currentPort " -back green -ForegroundColor White
                        }
                    }
                    catch
                    {
                            Write-host "$((hostname).toupper()) Not connected to $($Target.toupper()) on $Protocol port : $currentPort" -back red -ForegroundColor white
                    }            
                }
                Else
                {   
                                                              
                    #Create object for connecting to port on computer   
                    $UDPClient = new-Object system.Net.Sockets.Udpclient 
                    
                    #Set a timeout on receiving message, to avoid source machine to Listen forever. 
                    $UDPClient.client.ReceiveTimeout = 5000 
                    
                    #Datagrams must be sent with Bytes, hence the text is converted into Bytes
                    $ASCII = new-object system.text.asciiencoding
                    $Bytes = $ASCII.GetBytes("Hi")
                    
                    #UDP datagram is send
                    [void]$UDPClient.Send($Bytes,$Bytes.length,$Target,$Port)  
                    $RemoteEndpoint = New-Object system.net.ipendpoint([system.net.ipaddress]::Any,0)  
                     
                        Try
                        {
                            #Waits for a UDP response until timeout defined above
                            $RCV_Bytes = $UDPClient.Receive([ref]$RemoteEndpoint)  
                            $RCV_Data = $ASCII.GetString($RCV_Bytes) 
                            If ($RCV_Data) 
                            {
                           
                                Write-host "$((hostname).toupper()) connected to $($Target.toupper()) on $Protocol port : $currentPort " -back green -ForegroundColor White
                            }
                        }
                        catch
                        {
                            #if the UDP recieve is timed out
                            #it's infered that no response was received.
                            Write-host "$((hostname).toupper()) Not connected to $($Target.toupper()) on $Protocol port : $currentPort " -back red -ForegroundColor White
                        }
                        Finally
                        {

                            #Disposing Variables
                            $UDPClient.Close()
                            $RCV_Data=$RCV_Bytes=$null
                        }                                    
                }

             }
     }
}

########################################################################

function Get-LoggedOnUser
 {
     [CmdletBinding()]
     param
     (
         [Parameter()]
         [ValidateScript({ Test-Connection -ComputerName $_ -Quiet -Count 1 })]
         [ValidateNotNullOrEmpty()]
         [string[]]$ComputerName = $env:COMPUTERNAME
     )
     foreach ($comp in $ComputerName)
     {
         $output = @{ 'ComputerName' = $comp }
         $output.UserName = (Get-WmiObject -Class win32_computersystem -ComputerName $comp).UserName
         [PSCustomObject]$output
     }
 }