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