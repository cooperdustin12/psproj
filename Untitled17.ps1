    [CmdletBinding()] 
    Param 
    ( 
        [Parameter(HelpMessage="Computer or computers to gather information from", 
                   ValueFromPipeline=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   Position=0)] 
        [ValidateNotNullOrEmpty()] 
        [Alias('DNSHostName','PSComputerName')] 
        [string[]] 
        $ComputerName=$env:computername, 
        
        [Parameter(HelpMessage="Maximum number of concurrent threads")] 
        [ValidateRange(1,65535)] 
        [int32] 
        $ThrottleLimit = 32, 
  
        [Parameter(HelpMessage="Timeout before a thread stops trying to gather the information")] 
        [ValidateRange(1,65535)] 
        [int32] 
        $Timeout = 120, 
  
        [Parameter(HelpMessage="Display progress of function")] 
        [switch] 
        $ShowProgress, 
         
        [Parameter(HelpMessage="Set this if you want the function to prompt for alternate credentials")] 
        [switch] 
        $PromptForCredential, 
         
        [Parameter(HelpMessage="Set this if you want to provide your own alternate credentials")] 
        [System.Management.Automation.Credential()] 
        $Credential = [System.Management.Automation.PSCredential]::Empty 
    ) 
 
    BEGIN 
    { 
        # Gather possible local host names and IPs to prevent credential utilization in some cases 
        Write-Verbose -Message 'Remote Applied GPOs: Creating local hostname list' 
        $IPAddresses = [net.dns]::GetHostAddresses($env:COMPUTERNAME) | Select-Object -ExpandProperty IpAddressToString 
        $HostNames = $IPAddresses | ForEach-Object { 
            try { 
                [net.dns]::GetHostByAddress($_) 
            } catch { 
                # We do not care about errors here... 
            } 
        } | Select-Object -ExpandProperty HostName -Unique 
        $LocalHost = @('', '.', 'localhost', $env:COMPUTERNAME, '::1', '127.0.0.1') + $IPAddresses + $HostNames 
  
        Write-Verbose -Message 'Remote Applied GPOs: Creating initial variables' 
        $runspacetimers       = [HashTable]::Synchronized(@{}) 
        $runspaces            = New-Object -TypeName System.Collections.ArrayList 
        $bgRunspaceCounter    = 0 
         
        if ($PromptForCredential) 
        { 
            $Credential = Get-Credential 
        } 
         
        Write-Verbose -Message 'Remote Applied GPOs: Creating Initial Session State' 
        $iss = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault() 
        foreach ($ExternalVariable in ('runspacetimers', 'Credential', 'LocalHost')) 
        { 
            Write-Verbose -Message "Remote Applied GPOs: Adding variable $ExternalVariable to initial session state" 
            $iss.Variables.Add((New-Object -TypeName System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList $ExternalVariable, (Get-Variable -Name $ExternalVariable -ValueOnly), '')) 
        } 
         
        Write-Verbose -Message 'Remote Applied GPOs: Creating runspace pool' 
        $rp = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $ThrottleLimit, $iss, $Host) 
        $rp.ApartmentState = 'STA' 
        $rp.Open() 
  
        # This is the actual code called for each computer 
        Write-Verbose -Message 'Remote Applied GPOs: Defining background runspaces scriptblock' 
        $ScriptBlock = { 
            [CmdletBinding()] 
            Param 
            ( 
                [Parameter(Position=0)] 
                [string] 
                $ComputerName, 
  
                [Parameter(Position=1)] 
                [int] 
                $bgRunspaceID 
            ) 
            $runspacetimers.$bgRunspaceID = Get-Date 
             
            try 
            { 
                Write-Verbose -Message ('Remote Applied GPOs: Runspace {0}: Start' -f $ComputerName) 
                $WMIHast = @{ 
                    ComputerName = $ComputerName 
                    ErrorAction = 'Stop' 
                } 
                if (($LocalHost -notcontains $ComputerName) -and ($Credential -ne $null)) 
                { 
                    $WMIHast.Credential = $Credential 
                } 
 
                # General variables 
                $GPOPolicies = @() 
                $PSDateTime = Get-Date 
                 
                #region GPO Data 
 
                $GPOQuery = Get-WmiObject @WMIHast ` 
                                          -Namespace "ROOT\RSOP\Computer" ` 
                                          -Class RSOP_GPLink ` 
                                          -Filter "AppliedOrder <> 0" | 
                            Select @{n='linkOrder';e={$_.linkOrder}}, 
                                   @{n='appliedOrder';e={$_.appliedOrder}}, 
                                   @{n='GPO';e={$_.GPO.ToString().Replace("RSOP_GPO.","")}}, 
                                   @{n='Enabled';e={$_.Enabled}}, 
                                   @{n='noOverride';e={$_.noOverride}}, 
                                   @{n='SOM';e={[regex]::match( $_.SOM , '(?<=")(.+)(?=")' ).value}}, 
                                   @{n='somOrder';e={$_.somOrder}} 
                foreach($GP in $GPOQuery) 
                { 
                    $AppliedPolicy = Get-WmiObject @WMIHast ` 
                                                   -Namespace 'ROOT\RSOP\Computer' ` 
                                                   -Class 'RSOP_GPO' -Filter $GP.GPO 
                        $ObjectProp = @{ 
                            'Name' = $AppliedPolicy.Name 
                            'GuidName' = $AppliedPolicy.GuidName 
                            'ID' = $AppliedPolicy.ID 
                            'linkOrder' = $GP.linkOrder 
                            'appliedOrder' = $GP.appliedOrder 
                            'Enabled' = $GP.Enabled 
                            'noOverride' = $GP.noOverride 
                            'SourceOU' = $GP.SOM 
                            'somOrder' = $GP.somOrder 
                        } 
                         
                        $GPOPolicies += New-Object PSObject -Property $ObjectProp 
                } 
                           
                Write-Verbose -Message ('Remote Applied GPOs: Runspace {0}: Share session information' -f $ComputerName) 
 
                # Modify this variable to change your default set of display properties 
                $defaultProperties    = @('ComputerName','AppliedGPOs') 
                $ResultProperty = @{ 
                    'PSComputerName' = $ComputerName 
                    'PSDateTime' = $PSDateTime 
                    'ComputerName' = $ComputerName 
                    'AppliedGPOs' = $GPOPolicies 
                } 
                $ResultObject = New-Object -TypeName PSObject -Property $ResultProperty 
                 
                # Setup the default properties for output 
                $ResultObject.PSObject.TypeNames.Insert(0,'My.AppliedGPOs.Info') 
                $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet('DefaultDisplayPropertySet',[string[]]$defaultProperties) 
                $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet) 
                $ResultObject | Add-Member MemberSet PSStandardMembers $PSStandardMembers 
                #endregion GPO Data 
 
                Write-Output -InputObject $ResultObject 
            } 
            catch 
            { 
                Write-Warning -Message ('Remote Applied GPOs: {0}: {1}' -f $ComputerName, $_.Exception.Message) 
            } 
            Write-Verbose -Message ('Remote Applied GPOs: Runspace {0}: End' -f $ComputerName) 
        } 
  
        function Get-Result 
        { 
            [CmdletBinding()] 
            Param  
            ( 
                [switch]$Wait 
            ) 
            do 
            { 
                $More = $false 
                foreach ($runspace in $runspaces) 
                { 
                    $StartTime = $runspacetimers.($runspace.ID) 
                    if ($runspace.Handle.isCompleted) 
                    { 
                        Write-Verbose -Message ('Remote Applied GPOs: Thread done for {0}' -f $runspace.IObject) 
                        $runspace.PowerShell.EndInvoke($runspace.Handle) 
                        $runspace.PowerShell.Dispose() 
                        $runspace.PowerShell = $null 
                        $runspace.Handle = $null 
                    } 
                    elseif ($runspace.Handle -ne $null) 
                    { 
                        $More = $true 
                    } 
                    if ($Timeout -and $StartTime) 
                    { 
                        if ((New-TimeSpan -Start $StartTime).TotalSeconds -ge $Timeout -and $runspace.PowerShell) 
                        { 
                            Write-Warning -Message ('Timeout {0}' -f $runspace.IObject) 
                            $runspace.PowerShell.Dispose() 
                            $runspace.PowerShell = $null 
                            $runspace.Handle = $null 
                        } 
                    } 
                } 
                if ($More -and $PSBoundParameters['Wait']) 
                { 
                    Start-Sleep -Milliseconds 100 
                } 
                foreach ($threat in $runspaces.Clone()) 
                { 
                    if ( -not $threat.handle) 
                    { 
                        Write-Verbose -Message ('Remote Applied GPOs: Removing {0} from runspaces' -f $threat.IObject) 
                        $runspaces.Remove($threat) 
                    } 
                } 
                if ($ShowProgress) 
                { 
                    $ProgressSplatting = @{ 
                        Activity = 'Remote Applied GPOs: Getting info' 
                        Status = 'Remote Applied GPOs: {0} of {1} total threads done' -f ($bgRunspaceCounter - $runspaces.Count), $bgRunspaceCounter 
                        PercentComplete = ($bgRunspaceCounter - $runspaces.Count) / $bgRunspaceCounter * 100 
                    } 
                    Write-Progress @ProgressSplatting 
                } 
            } 
            while ($More -and $PSBoundParameters['Wait']) 
        } 
    } 
    PROCESS 
    { 
        foreach ($Computer in $ComputerName) 
        { 
            $bgRunspaceCounter++ 
            $psCMD = [System.Management.Automation.PowerShell]::Create().AddScript($ScriptBlock) 
            $null = $psCMD.AddParameter('bgRunspaceID',$bgRunspaceCounter) 
            $null = $psCMD.AddParameter('ComputerName',$Computer) 
            $null = $psCMD.AddParameter('Verbose',$VerbosePreference) 
            $psCMD.RunspacePool = $rp 
  
            Write-Verbose -Message ('Remote Applied GPOs: Starting {0}' -f $Computer) 
            [void]$runspaces.Add(@{ 
                Handle = $psCMD.BeginInvoke() 
                PowerShell = $psCMD 
                IObject = $Computer 
                ID = $bgRunspaceCounter 
           }) 
           Get-Result 
        } 
    } 
    END 
    { 
        Get-Result -Wait 
        if ($ShowProgress) 
        { 
            Write-Progress -Activity 'Remote Applied GPOs: Getting share session information' -Status 'Done' -Completed 
        } 
        Write-Verbose -Message "Remote Applied GPOs: Closing runspace pool" 
        $rp.Close() 
        $rp.Dispose() 
    } 
