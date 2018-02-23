#>
 
param(
  [Parameter(Mandatory = $false,
                    Position = 0,
                    ValueFromPipelineByPropertyName = $true)]
  [Boolean]$ShowPendingUpdates=$false,
 
  [Parameter(Mandatory = $false,
                    Position = 1,
                    ValueFromPipelineByPropertyName = $true)]
  [String]$LogFile=""
)
 
[Boolean]$ErrFound = $false
 
"Computer Name: " + $env:COMPUTERNAME
""
"Microsoft AutoUpdate settings"
# The output below starts with two line breaks, so omit the newline here
Write-Host -NoNewLine ("-----------------------------")
 
try {
  $objAutoUpdateSettings = (New-Object -ComObject "Microsoft.Update.AutoUpdate").Settings
  $objSysInfo = New-Object -ComObject "Microsoft.Update.SystemInfo"
  $objAutoUpdateSettings
  "Reboot required               : " + $objSysInfo.RebootRequired
   
  # NoAutoReboot can apparently only be set by policy, so report that here.
  # Reference: https://technet.microsoft.com/en-us/library/cc720464%28v=ws.10%29.aspx.
  Write-Host -NoNewLine ("NoAutoRebootWithLoggedOnUsers : ")
  try { 
    # If Get-ItemProperty fails, value is not in registry. Do not fail entire script. 
    # "-ErrorAction Stop" forces it to catch even a non-terminating error.
    $output = Get-ItemProperty -Path HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU -Name NoAutoRebootWithLoggedOnUsers -ErrorAction Stop
    switch ($output.NoAutoRebootWithLoggedOnUsers)
    {
      0 {"False (set in registry)"}
      1 {"True (set in registry)"}
    }
  }
  catch { 
    "Unknown (local policy registry value not found)" 
  }
 
  # WSUS server info, if available
  # Reference: https://technet.microsoft.com/en-us/library/dd939844(v=ws.10).aspx
  ""
  Write-Host -NoNewLine ("WSUS Server               : ")
  try { 
    # If Get-ItemProperty fails, value is not in registry. Do not fail entire script. 
    # "-ErrorAction Stop" forces it to catch even a non-terminating error.
    $output = Get-ItemProperty -Path HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate -Name WUServer -ErrorAction Stop
    $output.WUServer
  }
  catch { 
    "WSUS not configured. The machine must be contacting Windows Update directly." 
  }
  Write-Host -NoNewLine ("WSUS Status Server        : ")
  try { 
    $output = Get-ItemProperty -Path HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate -Name WUStatusServer -ErrorAction Stop
    $output.WUStatusServer
  }
  catch { 
    "WSUS not configured. The machine must be contacting Windows Update directly." 
  }
 
  # Static info on the meaning of various Settings.
  ""
  "NotificationLevel:"
  "1 - Never check for updates"
  "2 - Check for updates but let me choose whether to download and install them"
  "3 - Download updates but let me choose whether to install them"
  "4 - Install updates automatically"
  ""
  "ScheduledInstallationDay:"
  "0 - Every day"
  "1-7 - Sunday through Saturday"
  "Note:  On Windows 8/8.1/2012/2012R2, ScheduledInstallationDay and"
  "       ScheduledInstallationTime are only reliable if the values" 
  "       are set through Group Policy."
  ""
 
# For Windows 8/8.1/2012/2012R2, show start trigger of the Regular Maintenance task
   
# Per http://stackoverflow.com/a/26003354/550712 .NET OS Version is inaccurate on an 
# upgraded Windows 8.1 machine, so use Get-CimInstance if available, else fall back to .NET.
# Cast as [Version] to allow accurate comparisons even when Version.Major is two digits (Windows 10).
[Version]$OSVersion = $null
try {
  $OSVersion = (Get-CimInstance Win32_OperatingSystem).Version
}
catch {
  # Get-CimInstance requires PowerShell 3. Fall back to .NET if Get-CimInstance doesn't work.
  $OSVersion = [System.Environment]::OSVersion.Version
}
 
# List of Windows versions:  http://www.robvanderwoude.com/ver.php
if ( ($OSVersion -ge [Version]"6.2.9200") -and ($OSVersion -le [Version]"6.3.9600") ) {
  "Windows 8 / 8.1 / 2012 / 2012R2 scheduled maintenance"
  "-----------------------------------------------------"
  try {
    """\Microsoft\Windows\TaskScheduler\Regular Maintenance"" task trigger:"
    $task = Get-ScheduledTask –TaskName "Regular Maintenance" -TaskPath "\Microsoft\Windows\TaskScheduler\" -ErrorAction Stop
    $task.Triggers    
  }
  catch { 
    "Error:  Could not retrieve \Microsoft\Windows\TaskScheduler\Regular Maintenance task"
    ""
  }
 
# To change, use 
# $TaskTime = New-ScheduledTaskTrigger -At 12:00 -Daily  
# Set-ScheduledTask –TaskName "Regular Maintenance" -TaskPath "\Microsoft\Windows\TaskScheduler\" –Trigger $TaskTime -ErrorAction Stop
}
 
"Pending Software Updates including Hidden Updates"
"-------------------------------------------------"
  if ($ShowPendingUpdates) {
    #Get All Assigned updates in $SearchResult.
    $UpdateSession = New-Object -ComObject Microsoft.Update.Session
    $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
    # Available search criteria:  https://msdn.microsoft.com/en-us/library/windows/desktop/aa386526%28v=vs.85%29.aspx
    # "BrowseOnly=0" omits updates that are considered "Optional" (e.g. Silverlight, hardware drivers).
    # As of 4/8/2015, omit "BrowseOnly=0" so we'll see all available updates.
    # Include "IsAssigned=1" to only see updates intended for deployment by Automatic Updates:
    #   $SearchResult = $UpdateSearcher.Search("IsAssigned=1 and IsHidden=0 and IsInstalled=0")
    # Omit "IsAssigned=1" to also see Recommended updates:
    $SearchResult = $UpdateSearcher.Search("IsInstalled=0")
 
    #Extract Results for type of updates that are needed.  For to be arrays so we can .count them.
    [Object[]] $Critical = $SearchResult.updates | where { $_.MsrcSeverity -eq "Critical" }
    [Object[]] $Important = $SearchResult.updates | where { $_.MsrcSeverity -eq "Important" }
    [Object[]] $Moderate = $SearchResult.updates | where { $_.MsrcSeverity -eq "Moderate" }
    [Object[]] $Low = $SearchResult.updates | where { $_.MsrcSeverity -eq "Low" }
    [Object[]] $Unspecified = $SearchResult.updates | where { $_.MsrcSeverity -eq "Unspecified" }
    [Object[]] $Other = $SearchResult.updates | where { $_.MsrcSeverity -eq $null }
 
    #Write Results
    "Critical    : $($Critical.count)"
    "Important   : $($Important.count)"
    "Moderate    : $($Moderate.count)"
    "Low         : $($Low.count)"
    "Unspecified : $($Unspecified.count)"
    "Other       : $($Other.count)"  
    "Total       : $($SearchResult.updates.count)"
    ""
    "Notes:  ""BrowseOnly"" updates are considered optional."
    "         Microsoft anti-virus updates include sub-updates"
    "         that are already installed, so size is inaccurate."
    # "If" statement in Expression: 
    #   http://blogs.technet.com/b/josebda/archive/2014/04/19/powershell-tips-for-building-objects-with-custom-properties-and-special-formatting.aspx
    # Formatting number as MB:  https://technet.microsoft.com/en-us/library/ff730948.aspx
    # Available update properties (IUpdate interface):  https://msdn.microsoft.com/en-us/library/windows/desktop/aa386099(v=vs.85).aspx
    # Use Out-String to keep AutoSize from truncating columns based on screen size:
    #   https://poshoholic.com/2010/11/11/powershell-quick-tip-creating-wide-tables-with-powershell/
     
    ""
    "Ready to Install"
    "----------------"
    $NotHiddenUpdates = $SearchResult.updates | Where-Object {$_.IsHidden -eq $false}
    If ($NotHiddenUpdates -eq $null) { 
      "None" 
    } else {
      $NotHiddenUpdates | Sort-Object MsrcSeverity, Title | `
        Format-Table -AutoSize @{Expression={if ($_.MsrcSeverity -eq $null) {"Other"} else {$_.MsrcSeverity} };Label="Severity"}, `
        @{Expression={$_.Title};Label="Title"}, `
        @{Expression={"{" + $_.Identity.UpdateID + "}." + $_.Identity.RevisionNumber};Label="UpdateID and RevisionNumber"}, `
        @{Expression={$_.BrowseOnly};Label="BrowseOnly"}, `
        @{Expression={$_.IsDownloaded};Label="IsDownloaded"}, `
        @{Expression={"{0:N1} MB" -f ($_.MaxDownloadSize / 1MB) };Label="MaxDownload";align="right"} | `
        Out-String -Width 200 
    }
    ""
    "Hidden Updates"
    "--------------"
    $HiddenUpdates = $SearchResult.updates | Where-Object {$_.IsHidden -eq $true}
    If ($HiddenUpdates -eq $null) { 
      "None" 
    } else {
      $HiddenUpdates | Sort-Object MsrcSeverity, Title | `
        Format-Table -AutoSize @{Expression={if ($_.MsrcSeverity -eq $null) {"Other"} else {$_.MsrcSeverity} };Label="Severity"}, `
        @{Expression={$_.Title};Label="Title"}, `
        @{Expression={"{" + $_.Identity.UpdateID + "}." + $_.Identity.RevisionNumber};Label="UpdateID and RevisionNumber"}, `
        @{Expression={$_.BrowseOnly};Label="BrowseOnly"}, `
        @{Expression={$_.IsDownloaded};Label="IsDownloaded"}, `
        @{Expression={"{0:N1} MB" -f ($_.MaxDownloadSize / 1MB) };Label="MaxDownload";align="right"} | `
        Out-String -Width 200
    }
  } else {
    "The ShowPendingUpdates parameter is False, so pending updates not listed."
    ""
  } # if $ShowPendingUpdates
   
  "Script execution succeeded"
  $ExitCode = 0
} # try
catch {
  ""
  $error[0]
  ""
  "Script execution failed"
  $ExitCode = 1001 # Cause script to report failure in MaxFocus RM dashboard
}
 
""
"Local Machine Time:  " + (Get-Date -Format G)
"Exit Code: " + $ExitCode
Exit $ExitCode