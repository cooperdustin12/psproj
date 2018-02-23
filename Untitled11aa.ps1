#this is two separate scripts which must be run in Tandem all files need to be in the same directory

################################ Script 1. ############################################

###################### Monitor Script ###########################
# By Ryan Jones                                                 #
# This is the script which will run the monitor script          #
# You can call this what you would like I call it Run This.ps1  #
# Change details (if required) anywhere you see **CHANGE THIS** #
#################################################################
 $date = Get-Date
 $d = $date.day
 $m = $date.month
 $y = $date.year
#**CHANGE THIS** Set the location the report is saved to (must exist)
$File ="C:\monitor\report_$d.$m.$y.txt"

"Running Reports"
.\monitor.ps1 | out-file -filepath $File -append

"Sending Email"
#**CHANGE THIS** change these to what you require
$EmailFrom = "something@yourdomain.com"
$EmailTo = "something@yourdomain.com"
$EmailSubject = "Server Reports" 
$emailbody = @"
               D A I L Y  S E R V E R  R E P O R T

Attached is the daily server report for the $d/$m/$y please check and review issues.

"@
#**CHANGE THIS** change this to your SMTP server 
$SMTPServer = "mail.yourdomain.com"

$emailattachment = $file

function send_email {
$mailmessage = New-Object system.net.mail.mailmessage
$mailmessage.from = ($emailfrom)
$mailmessage.To.add($emailto)
$mailmessage.Subject = $emailsubject
$mailmessage.Body = $emailbody

$attachment = New-Object System.Net.Mail.Attachment($emailattachment, 'text/plain')
  $mailmessage.Attachments.Add($attachment)


#$mailmessage.IsBodyHTML = $true
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 25) 
$SMTPClient.Send($mailmessage)
}
send_email
"Email Sent"

#################################### Script 2. ########################################

###################### Monitor Script ###########################
# By Ryan Jones                                                 #
# This is the monitor script                                    #
# This script must be called monitor.ps1                        #
# You will need to create a txt file called computers.txt       #
# The file needs to be in the same directory                    #
# the Format of the file is one computer name per line          #
# Change details (if required) anywhere you see **CHANGE THIS** #
#################################################################
# **CHANGE THIS** 
$listloc="C:\somefolder\computers.txt";
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