function Get-DhcpServerLog {
    param(
        [parameter(Position=0,Mandatory=$false)]
        [Alias("count")]
        [int]$Lines = 20,

        [parameter(Position=3,Mandatory=$false)]
        [ValidateSet("mon","tue", "wed", "thu", "fri", IgnoreCase=$true)]
        [string]$Day= (get-date).DayOfWeek.ToString().Substring(0,3)
    )
    Write-Verbose "Get-DHCPServerLog called with parameters - Lines:$Lines, Day:$Day"

    # CSV header fields, to be used later when converting each line of the tailed log from CSV
    $headerFields = @("ID","Date","Time","Description","IP Address","Host Name","MAC Address","User Name","TransactionID","QResult","Probationtime","CorrelationID","Dhcid","VendorClass(Hex)","VendorClass(ASCII)","UserClass(Hex)","UserClass(ASCII)","RelayAgentInformation","DnsRegError")

    # Translations of the ID field, as per the description inside the log file itself
    $idMeanings = @{ 
        00 = "The log was started.";
        01 = "The log was stopped.";
        02 = "The log was temporarily paused due to low disk space.";
        10 = "A new IP address was leased to a client.";
        11 = "A lease was renewed by a client.";
        12 = "A lease was released by a client.";
        13 = "An IP address was found to be in use on the network.";
        14 = "A lease request could not be satisfied because the scope's address pool was exhausted.";
        15 = "A lease was denied.";
        16 = "A lease was deleted.";
        17 = "A lease was expired and DNS records for an expired leases have not been deleted.";
        18 = "A lease was expired and DNS records were deleted.";
        20 = "A BOOTP address was leased to a client.";
        21 = "A dynamic BOOTP address was leased to a client.";
        22 = "A BOOTP request could not be satisfied because the scope's address pool for BOOTP was exhausted.";
        23 = "A BOOTP IP address was deleted after checking to see it was not in use.";
        24 = "IP address cleanup operation has begun.";
        25 = "IP address cleanup statistics.";
        30 = "DNS update request to the named DNS server.";
        31 = "DNS update failed.";
        32 = "DNS update successful.";
        33 = "Packet dropped due to NAP policy.";
        34 = "DNS update request failed as the DNS update request queue limit exceeded.";
        35 = "DNS update request failed.";
        36 = "Packet dropped because the server is in failover standby role or the hash of the client ID does not match.";
        # Event descriptions for 50-64 sourced from https://technet.microsoft.com/en-us/library/cc776384(v=ws.10).aspx
        50 = "The DHCP server could not locate the applicable domain for its configured Active Directory installation.";
        51 = "The DHCP server was authorized to start on the network.";
        52 = "The DHCP server was recently upgraded to a Windows Server 2003 operating system, and, therefore, the unauthorized DHCP server detection feature (used to determine whether the server has been authorized in Active Directory) was disabled."
        53 = "The DHCP server was authorized to start using previously cached information. Active Directory was not currently visible at the time the server was started on the network.";
        54 = "The DHCP server was not authorized to start on the network. When this event occurs, it is likely followed by the server being stopped.";
        55 = "The DHCP server was successfully authorized to start on the network.";
        56 = "The DHCP server was not authorized to start on the network and was shut down by the operating system. You must first authorize the server in the directory before starting it again.";
        57 = "Another DHCP server exists and is authorized for service in the same domain.";
        58 = "The DHCP server could not locate the specified domain.";
        59 = "A network-related failure prevented the server from determining if it is authorized.";
        60 = "No Windows Server 2003 domain controller (DC) was located. For detecting whether the server is authorized, a DC that is enabled for Active Directory is needed.";
        61 = "Another DHCP server was found on the network that belongs to the Active Directory domain.";
        62 = "Another DHCP server was found on the network.";
        63 = "The DHCP server is trying once more to determine whether it is authorized to start and provide service on the network.";
        64 = "The DHCP server has its service bindings or network connections configured so that it is not enabled to provide service."
    }

    $qResultMeanings = @{0 = "No Quarantine"; 1 = "Quarantine"; 2 = "Drop Packet"; 3 = "Probation"; 6 = "No Quarantine Information"}

    $filePath = "C:\tmp\dhcp\DhcpSrvLog-$Day.log"
    
    Write-Verbose "Attempting to search for DHCP log at location: $filePath"
    if ((Test-Path $filePath) -eq $false) { throw "Couldn't locate DHCP log at $filePath" }

    Write-Verbose "Reading last $Lines lines from DHCP log at location: $filePath"
    Get-Content $filePath -tail $Lines | ConvertFrom-Csv -Header $headerFields | Select-Object *,@{n="ID Description";e={$idMeanings[[int]::parse($_.ID)]}},@{n="QResult Description";e={$qResultMeanings[[int]::parse($_.QResult)]}}

}