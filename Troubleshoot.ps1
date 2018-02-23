



Write-Host 1. Enter Remote PSSession
Write-Host 2. Find the top five processes using the most memory
Write-Host 3. Cycle a service "(stop, and then restart it)" like DHCP
Write-Host 4. Restart a Remote Windows Machine
Write-Host 5. Get Event Log
Write-Host 6. Get System Info + Last Reboot + Users logged in
Write-Host 7. List installed hotfixes -- QFEs, or Windows Update files
Write-Host 8. Get the username of the person currently logged on to a computer 
Write-Host 9. Find just the names of installed applications on the current computer 
Write-Host 10. Get IP addresses assigned to the current computer 
Write-Host 11. Get a more detailed IP configuration report for the current machine
Write-Host 12. Advanced TCP/UDP Ping 
Write-Host 13. Tracert - TO DO
Write-Host 14. Netstat - TO DO
Write-Host 15. Advanced System report
Write-Host 16. Manual input
Write-Host 17. Exit



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
#$Service = Read-Host -Prompt 'Input Service Name Here'
#$PC = Read-Host -Prompt 'Input Machine Name'
#$Status = Read-Host -Prompt ' Set Desired Status (Running,Stopped,Paused)'
#Get-Service -Name $Service -ComputerName $PC  | Set-Service -Status $Status
###########################
Write-Host "cmdlet has been lodaded into memory. Examples of Function" -foregroundcolor 'magenta'
Write-Host "Restart-Service -SERVERNAME VBMPRSQL001 -SERVICENAME MSSQLSERVER" -foregroundcolor 'magenta'
Write-Host "Use Option 16 (Manual Input) to restart service" -foregroundcolor 'magenta'


FUNCTION Restart-Service
{
PARAM([STRING]$SERVERNAME=$env:COMPUTERNAME,[STRING]$SERVICENAME) #MSSQLSERVER FOR DEFAULT INSTANCE FOR NAMED INSTANCE MSSQL`$KAT

$SERVICE = GET-SERVICE -COMPUTERNAME $SERVERNAME -NAME $SERVICENAME -ERRORACTION SILENTLYCONTINUE

IF( $SERVICE.STATUS -EQ "RUNNING" )
{
	$DEPSERVICES = GET-SERVICE -COMPUTERNAME $SERVERNAME -Name $SERVICE.SERVICENAME -DEPENDENTSERVICES | WHERE-OBJECT {$_.STATUS -EQ "RUNNING"}
	IF( $DEPSERVICES -NE $NULL )
	{
		FOREACH($DEPSERVICE IN $DEPSERVICES)
		{
		Stop-Service -InputObject (Get-Service -ComputerName $SERVERNAME -Name $DEPSERVICES.ServiceName)
		}
	}
  Stop-Service -InputObject (Get-Service -ComputerName $SERVERNAME -Name $SERVICE.SERVICENAME) -Force
   if($?)
   {
   Start-Service -InputObject (Get-Service -ComputerName $SERVERNAME -Name $SERVICE.SERVICENAME)
	$DEPSERVICES = GET-SERVICE -COMPUTERNAME $SERVERNAME -NAME $SERVICE.SERVICENAME -DEPENDENTSERVICES | WHERE-OBJECT {$_.STATUS -EQ "STOPPED"}
	IF( $DEPSERVICES -NE $NULL )
	{
		FOREACH($DEPSERVICE IN $DEPSERVICES)
		{
			Start-Service -InputObject (Get-Service -ComputerName $SERVERNAME -Name $DEPSERVICE.SERVICENAME)
		}
	}
    }
 }
ELSEIF ( $SERVICE.STATUS -EQ "STOPPED" )
{
	Start-Service -InputObject (Get-Service -ComputerName $SERVERNAME -Name $SERVICE.SERVICENAME)
	$DEPSERVICES = GET-SERVICE -COMPUTERNAME $SERVERNAME -NAME $SERVICE.SERVICENAME -DEPENDENTSERVICES | WHERE-OBJECT {$_.STATUS -EQ "STOPPED"}
	IF( $DEPSERVICES -NE $NULL )
	{
		FOREACH($DEPSERVICE IN $DEPSERVICES)
		{
			Start-Service -InputObject (Get-Service -ComputerName $SERVERNAME -Name $DEPSERVICE.SERVICENAME)
		}
	}
}
ELSE
{

	"THE SPECIFIED SERVICE DOES NOT EXIST"


}

}



###########################
}
 


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
$ET = Read-Host -Prompt 'Entry Type (Error, Information, FailureAudit, SuccessAudit, Warning)'
Get-EventLog -Logname $log  -ComputerName $PC -Newest 50 -EntryType $ET
}

elseif($RH -eq '6')
{ 
$PC = Read-Host -Prompt 'Input Machine Name'
    $PCSystem = get-wmiobject Win32_ComputerSystem -Computer $PC
    $PCBIOS = get-wmiobject Win32_BIOS -Computer $PC
    $PCOS = get-wmiobject Win32_OperatingSystem -Computer $PC
    $PCCPU = get-wmiobject Win32_Processor -Computer $PC
    $PCHDD = Get-WmiObject Win32_LogicalDisk -ComputerName $PC -Filter drivetype=3
        write-host "System Information for: " $PCSystem.Name -BackgroundColor DarkCyan
        "-------------------------------------------------------"
        "Manufacturer: " + $PCSystem.Manufacturer
        "Model: " + $PCSystem.Model
        "Serial Number: " + $PCBIOS.SerialNumber
        "CPU: " + $PCCPU.Name
        "HDD Capacity: "  + "{0:N2}" -f ($PCHDD.Size[0]/1GB) + "GB"
        "HDD Space: " + "{0:P2}" -f ($PCHDD.FreeSpace[0]/$PCHDD.Size[0]) + " Free (" + "{0:N2}" -f ($PCHDD.FreeSpace[0]/1GB) + "GB)"
        "RAM: " + "{0:N2}" -f ($PCSystem.TotalPhysicalMemory/1GB) + "GB"
        "Operating System: " + $PCOS.caption + ", Service Pack: " + $PCOS.ServicePackMajorVersion
        "User logged In: " + $PCrSystem.UserName
        "Last Reboot: " + $PCOS.ConvertToDateTime($PCOS.LastBootUpTime)
        ""
        "-------------------------------------------------------"
}

elseif($RH -eq '7')
{ 
$PC = Read-Host -Prompt 'Input Machine Name'
Get-WmiObject -Class Win32_QuickFixEngineering -ComputerName $PC
}


elseif($RH -eq '8')
{ 
$PC = Read-Host -Prompt 'Input Machine Name'
Get-WmiObject -Class Win32_ComputerSystem -Property UserName -ComputerName $PC
}


elseif($RH -eq '9')
{ 
$PC = Read-Host -Prompt 'Input Machine Name'
Get-WmiObject -Class Win32_Product -ComputerName $PC | Format-Wide -Column 1
}


elseif($RH -eq '10')
{ 
$PC = Read-Host -Prompt 'Input Machine Name'
Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE -ComputerName $PC | Format-Table -Property IPAddress
}


elseif($RH -eq '11')
{ 
$PC = Read-Host -Prompt 'Input Machine Name'
Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE -ComputerName $PC | Select-Object -Property [a-z]* -ExcludeProperty IPX*,WINS*
}

elseif($RH -eq '12')
{


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

"Examples of Function"
"Test-PortConnectivity -Source '127.0.0.1' -RemoteDestination 'dc1' -Port 57766"
"Test-PortConnectivity '127.0.0.1' 'dc1' 57766 -Protocol UDP -Iterate"
"Test-PortConnectivity 'localhost' 'dc2' 51753 -Protocol UDP"
'Test-PortConnectivity -Source $EUCAS -RemoteDestination $EUMBX -Port 135 -Iterate'
"Test-PortConnectivity -Source 'localhost' -RemoteDestination '127.0.0.1' -Port 135 -Iterate -protocol TCP"

    
}




elseif($RH -eq '15')
{ 

$computers=Read-Host -Prompt 'Input Machine Name'
 $date = Get-Date
 $d = $date.day
 $m = $date.month
 $y = $date.year
 
	####################### Function For CPU Usage ###########################

function get-CPUUSAGE {
    param(
        #**CHANGE THIS** Set the CPU threshold
        [int] $threshold = 10
    )
 
    $ErrorActionPreference = "SilentlyContinue"
 
    # Test connection to computer
    if( !(Test-Connection -Destination $computersname -Count 1) ){
        "Could not connect to :: $computersname"
        return
    }
 
    # Get all the processes
    $processes = Get-WmiObject -ComputerName $computersname `
    -Class Win32_PerfFormattedData_PerfProc_Process `
    -Property Name, PercentProcessorTime
 
    $return= @()
 
    # Build up a return list
    foreach( $process in $processes ){
        if( $process.PercentProcessorTime -ge $threshold `
        -and $process.Name -ne "Idle" `
        -and $process.Name -ne "_Total"){
            $item = "" | Select Name, CPU
            $item.Name = $process.Name
            $item.CPU = $process.PercentProcessorTime
            $return += $item
            $item = $null
        }
    }
 
    # Sort the return data
    $return = $return | Sort-Object -Property CPU -Descending
    return $return
}
$cpuuage=get-CPUUSAGE 

 
""
"=== S T A R T  R E P O R T ==="
""
""

foreach ($computersname in $computers) { 


#Does all the checking   
       
   if (Test-Connection $computersname -erroraction silentlyContinue  ) {
	""
	"-------------------------"
     $computersname.ToUpper()
	"-------------------------"
	 ""
     ""
     $label="$computersname Status:	"
	 $label = $label.ToUpper()
     $labelup="UP";
	 ""
	 "****************************************"
     $label+$labelup 
	 "****************************************"
	 ""
     ""
     "Current CPU Usage"
     Get-WmiObject win32_processor -ComputerName $computersname | select LoadPercentage  |fl
     "Processes using above 10% cpu"
     ""
     if (!$cpuuage)
     {"No processes currently running above 10% CPU usage"}
     else {$cpuuage}
     ""
     ""
     "===== Memory Usage ====="
     ""
"-------PROCESS LIST BY MEMORY USAGE-------"
$fields = "Name",@{label = "Memory (MB)"; Expression = {$_.ws / 1mb}; Align = "Right"}
$processlist=get-process -ComputerName $computersname 
$processlist | Sort-Object -Descending WS | format-table $fields | Out-String
"------------------------------------------"
""
""
$freemem = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $computersname

# Display free memory on PC/Server
"---------FREE MEMORY----------"
""
"System Name     : {0}" -f $freemem.csname
"Free Memory (MB): {0}" -f ([math]::round($freemem.FreePhysicalMemory / 1024, 2))
"Free Memory (GB): {0}" -f ([math]::round(($freemem.FreePhysicalMemory / 1024 / 1024), 2))
""
"------------------------------"
     ""
     ""
     ""
    "===list automatic services which are currently stopped==="
    ""
# get Auto that not Running:
Get-WmiObject Win32_Service -ComputerName $computersname |
Where-Object { $_.StartMode -eq 'Auto' -and $_.State -ne 'Running' } |
# process them; in this example we just show them:
Format-Table -AutoSize @(
    'Name'
    'DisplayName'
    @{ Expression = 'State'; Width = 9 }
    @{ Expression = 'StartMode'; Width = 9 }
    'StartName'
) | Out-String -Width 300
    ""
    ""
    "===== ERRORS IN APPLICATION AND SYSTEM EVENT LOGS ====="
    $today=$Date.ToShortDateString()
    ""
    ""
    "--- Errors in Application event log for $today ---"
    ""
    $appevent=get-eventlog -log "Application" -entrytype Error -ComputerName $computersname -after $today
    If(!$appevent)
            {
                ""
                "No errors"
                ""
            }
    else    {
                ""
                $appevent | Format-Table -AutoSize -Wrap | Out-String -Width 300
                ""
            }
    ""
    "--- Errors in System event log for $today ---"
    ""
    $sysevent=get-eventlog -log "System" -entrytype Error -ComputerName $computersname  -after $today
        If(!$sysevent)
            {
                ""
                "No errors"
                ""
            }
    else    {
                ""
                $sysevent | Format-Table -AutoSize -Wrap | Out-String -Width 300
                ""
            }
    ""
    ""
   }
   else {
     $computersname
     ""
     $label="$computersname Status:	";
     $labeldown="DOWN";
     $label+$labeldown
     ""
     ""
   }
 }
    ""
   "=== E N D  O F  R E P O R T ==="



}

elseif($RH -eq '16')
{ 
Read-Host -Prompt 'Input Command'
}


elseif($RH -eq '17')
{ break 

}

else
{
Start-Sleep -Milliseconds 10

 }

 



