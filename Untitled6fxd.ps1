# reset the lists of hosts prior to looping 
$OutageHosts = $Null 
# specify the time you want email notifications resent for hosts that are down 
$EmailTimeOut = 30 
# specify the time you want to cycle through your host lists. 
$SleepTimeOut = 3600 
# specify the maximum hosts that can be down before the script is aborted 
$MaxOutageCount = 1000 
# specify who gets notified 
$notificationto = "dustin.cooper@cbn.org" 
# specify where the notifications come from 
$notificationfrom = "Pingtest@cbn.org" 
# specify the SMTP server 
$smtpserver = "mail.cbn.local" 
 
# start looping here 
Do{ 
$available = $Null 
$notavailable = $Null 
Write-Host (Get-Date) 
 
# Read the File with the Hosts every cycle, this way to can add/remove hosts 
# from the list without touching the script/scheduled task,  
# also hash/comment (#) out any hosts that are going for maintenance or are down. 
get-content C:\tmp\DNS2.txt | Where-Object {!($_ -match "#")} |  
ForEach-Object { 
if(Test-Connection -ComputerName $_ -Count 1 -ea silentlycontinue) 
    { 
     # if the Host is available then just write it to the screen 
     write-host "Available host ---> "$_ -BackgroundColor Green -ForegroundColor White 
     [Array]$available += $_ 
    } 
else 
    { 
     # If the host is unavailable, give a warning to screen 
     write-host "Unavailable host ------------> "$_ -BackgroundColor Magenta -ForegroundColor White 
     if(!(Test-Connection -ComputerName $_ -Count 4 -ea silentlycontinue)) 
       { 
        # If the host is still unavailable for 4 full pings, write error and send email 
        write-host "Unavailable host ------------> "$_ -BackgroundColor Red -ForegroundColor White 
        [Array]$notavailable += $_ 
 
        if ($OutageHosts -ne $Null) 
            { 
                if (!$OutageHosts.ContainsKey($_)) 
                { 
                 # First time down add to the list and send email 
                 Write-Host "$_ Is not in the OutageHosts list, first time down" 
                 $OutageHosts.Add($_,(get-date)) 
                 $Now = Get-date 
                 $Body = "$_ has not responded for 5 pings at $Now" 
                 #Send-MailMessage -Body "$body" -to $notificationto -from $notificationfrom ` 
                 # -Subject "Host $_ is down" -SmtpServer $smtpserver 
                } 
                else 
                { 
                    # If the host is in the list do nothing for 1 hour and then remove from the list. 
                    Write-Host "$_ Is in the OutageHosts list" 
                    if (((Get-Date) - $OutageHosts.Item($_)).TotalMinutes -gt $EmailTimeOut) 
                    {$OutageHosts.Remove($_)} 
                } 
            } 
        else 
            { 
                # First time down create the list and send email 
                Write-Host "Adding $_ to OutageHosts." 
                $OutageHosts = @{$_=(get-date)} 
                $Body = "$_ has not responded for 5 pings at $Now"  
                #Send-MailMessage -Body "$body" -to $notificationto -from $notificationfrom ` 
                 #-Subject "Host $_ is down" -SmtpServer $smtpserver 
            }  
       } 
    } 
} 
# Report to screen the details 
Write-Host "Available count:"$available.count 
Write-Host "Not available count:"$notavailable.count 
Write-Host "Not available hosts:" 
$OutageHosts 
Write-Host "" 
Write-Host "Sleeping $SleepTimeOut seconds" 
sleep $SleepTimeOut 
if ($OutageHosts.Count -gt $MaxOutageCount) 
{ 
    # If there are more than a certain number of host down in an hour abort the script. 
    $Exit = $True 
    $body = $OutageHosts | Out-String 
    #Send-MailMessage -Body "$body" -to $notificationto -from $notificationfrom ` 
     #-Subject "More than $MaxOutageCount Hosts down, monitoring aborted" -SmtpServer $smtpServer 
} 
} 
while ($Exit -ne $True) 
