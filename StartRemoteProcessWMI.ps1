#This scrit will remotely execute an exe through WMI.
#
#This script was basedlined from Jeffery Hicks (http://serverfault.com/questions/77585/execute-program-on-remote-computer-using-powershell)
#and JNK (#http://stackoverflow.com/questions/7834656/create-log-file-in-powershell)
#
#Modified by Thwack user Chad.Every
#
#
#Accept parameters to be passed into script:
#RemoteNodeUserName = Windows username of remote server
#RemoteNodePassword = Windows password of remote server
#RemoteNodeName = Windows server name of remote server
#LocalPathToExecutable = The local path of the executable to run on the remote server.
param([string]$RemoteNodeUserName, [string]$RemoteNodePassword, [string]$RemoteNodeName, [string]$LocalPathToExecutable)

#Function to write output to file for auditing and troubleshooting.
Function Write-Log
{
   Param ([string]$LogString)
   Add-content $LogFile -value "$(Get-Date -format 'u') $LogString"
   }

Function New-RemoteProcess {
    Param([string]$cmd=$(Throw "You must enter the full path to the command which will create the process.", $Credentials)
    )

    $ErrorActionPreference="SilentlyContinue"

    Trap {
        Write-Log "There was an error connecting to the remote computer or creating the process: \n$error[0].Exception.Message";
        Continue
    }    

    Write-Log "Connecting to $RemoteNodeName"
    Write-Log "Process to create is $cmd"

    #Call remote process through wmi
	[wmiclass]$wmi = Get-WmiObject -ComputerName $RemoteNodeName -Query "SELECT * FROM Meta_Class WHERE __Class = 'Win32_Process'" -Credential $Credentials

    #Bail out if the object didn't get created
    if (!$wmi) {return}

    $remote=$wmi.Create($cmd)

    #Test if remote command was sucessful
    if ($remote.returnvalue -eq 0) 
       {
        $remoteProcessId = $remote.processid
        Write-Log "Successfully launched $cmd on $RemoteNodeName with a process id of $remoteProcessId"
        exit 0
    }
    else {
        #If error occur write Powershell error to log
        $remoteReturnValue = $remote.ReturnValue
        Write-Log "Failed to launch $cmd on $RemoteNodeName. ReturnValue is $remoteReturnValue"
        exit 1
    }
}

#Create combined username/password variable for authentication
$Credentials = New-Object System.Management.Automation.PSCredential($RemoteNodeUserName,(ConvertTo-SecureString $RemoteNodePassword -AsPlainText -Force))

#Output logfile to defined path with the server name in the file name
$LogFile = "C:\SolarWindsScripts\Log\StartRemoteProcess_$RemoteNodeName.log"

#Function to call remote process through WMI
New-RemoteProcess -cmd $LocalPathToExecutable -Credentials $Credentials