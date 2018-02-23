$pshost = Get-Host
$pswindow = $pshost.UI.RawUI
$newsize = $pswindow.windowsize
$newsize.height = 80
$pswindow.windowsize = $newsize

if(($args.Count -gt 0) -and (($args[0].ToLower() -eq "/?") -or ($args[0].ToLower() -eq "/help") -or ($args[0].ToLower() -eq "-h") -or ($args[0].ToLower() -eq "--help") -or ($args[0].ToLower() -eq "-help"))){
    Write-Host("YASIS - Yet Another System Info Script")
    Write-Host("USAGE:")
    Write-Host("    - Get Local PC Info: GetPCInfo")
    Write-Host("    - Get Remote PC Info: GetPCInfo <COMPUTER NAME | IP>")
    Write-Host("    - Get Many Remote PC's Info: GetPCInfo <COMPUTER NAME | IP> <COMPUTER NAME | IP> (Repeat as many times as needed")
    Write-Host("    - Show this help: GetPCInfo /? | /help | -h | --help")

} Else {
    if($args.Count -eq 0) {$args = ("localhost")}

    Foreach($computer in $args){
        $system = (Get-WmiObject -Class Win32_ComputerSystem)
        If($computer -eq $system.Name){
            $cpu = (Get-WmiObject -Class Win32_Processor)
            $memory = (Get-WMIObject -Class Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum | % {[Math]::Round(($_.sum / 1GB),2)})
            $productNumber = (Get-WmiObject -Namespace root\wmi  -Class MS_SystemInformation) | Select SystemSKU
            $disk = (Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'" | Measure-Object -Property Size -Sum | % {[Math]::Round(($_.sum / 1GB),2)})
            $enclosure = (Get-WmiObject -Class Win32_SystemEnclosure)
            $activeAdapters = (Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE | Select Description,IPAddress, MACAddress)
        } Else {
            $system = (Get-WmiObject -Class Win32_ComputerSystem -ComputerName $computer)
            $cpu = (Get-WmiObject -Class Win32_Processor -ComputerName $computer)
            $memory = (Get-WMIObject -Class Win32_PhysicalMemory -ComputerName $computer | Measure-Object -Property Capacity -Sum | % {[Math]::Round(($_.sum / 1GB),2)})
            $productNumber = (Get-WmiObject -Namespace root\wmi  -Class MS_SystemInformation -ComputerName $computer) | Select SystemSKU
            $disk = (Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'" -ComputerName $computer | Measure-Object -Property Size -Sum | % {[Math]::Round(($_.sum / 1GB),2)})
            $enclosure = (Get-WmiObject  -Class Win32_SystemEnclosure -ComputerName $computer)
            $activeAdapters = (Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE -ComputerName $computer | Select Description,IPAddress, MACAddress)
        }
        Write-Host(" - Computer Name: ") -f DarkCyan -nonewline;Write-Host($system.Name) -f DarkYellow
        Write-Host("    - Manufacturer: ") -f DarkCyan -nonewline;Write-Host($system.Manufacturer) -f Gray
        Write-Host("    - Model: ") -f DarkCyan -nonewline;Write-Host($system.Model) -f DarkYellow
        Write-Host("        - Product Number: ") -f DarkCyan -nonewline;Write-Host($productNumber.SystemSKU) -f DarkYellow
        Write-Host("    - Serial Number: ") -f DarkCyan -nonewline;Write-Host($enclosure.SerialNumber) -f DarkYellow
        if(($enclosure.SMBIOSAssetTag -notmatch $enclosure.SerialNumber) -and ( -not [string]::IsNullOrEmpty($enclosure.SerialNumber))) {
            Write-Host("    - Asset Tag: ") -f DarkCyan -nonewline;Write-Host($enclosure.SMBIOSAssetTag) -f DarkYellow
        }
        # Get Asset Tag from Computer Name (Unreliable)
        # else{Write-Host(" - Asset Tag: ") -f DarkCyan -nonewline;Write-Host("0" + ($system.Name.Substring($system.Name.Length - 5, 5))) -f DarkYellow}
        Write-Host("    - Processor: ") -f DarkCyan -nonewline;Write-Host($cpu.Name) -f Gray
        Write-Host("    - Memory: ") -f DarkCyan -nonewline;Write-Host("$memory GB") -f Gray
        Write-Host("    - HDD: ") -f DarkCyan -nonewline;Write-Host("$disk GB") -f Gray
        Write-Host("    - Network Adapters:") -f DarkCyan 
        ForEach($adapter in $activeAdapters){
            Write-Host("        - ") -f DarkCyan -nonewline;Write-Host("$($adapter.Description):") -f DarkYellow
            Write-Host("            - IP Address(s):") -f DarkCyan
            ForEach($IP in $adapter.IPAddress) {
                Write-Host("                - ") -f DarkCyan -nonewline;Write-Host("$IP") -f Gray
            }
            Write-Host("            - MAC: ") -f DarkCyan -nonewline;Write-Host("$($adapter.MACAddress)") -f Gray
        }
    }
}
