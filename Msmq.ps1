Import-LocalizedData -BindingVariable _system_translations -filename Msmq.psd1

#  
# ------------------  
# CONSTANTS - START  
# ------------------  
# 

$XmlTargetNamespace = "http://schemas.microsoft.com/mbca/models/msmq/2011/11"
$MsmqCompositeType = "MsmqComposite"
$MsmqName = "MSMQ"

#  
# ------------------  
# CONSTANTS - END  
# ------------------  
#  

#
# ------------------
# FUNCTIONS - START
# ------------------
#

function isServiceInstalled ($serviceName)
{
    $service = Get-Service $serviceName
    $service -ne $null
}

function createXmlDocument( $ns, $name )
{
    [xml] "<$name xmlns='$ns'></$name>"
}

function getIsDomainController
{  
    $isDc = $false
    $operatingSystem = Get-WmiObject -class Win32_OperatingSystem | Select-Object -Property ProductType  
    if ($operatingSystem.ProductType -eq 2)
    {
        $isDc = $true
    }
    
    "<IsDomainController>$isDc</IsDomainController>"
}

function getRegistryValue($path, $name, $default)
{
    if (test-path $path)
    {
        $item = Get-ItemProperty -Path $path
        if ($item -ne $null -and $item.$name -ne $null)
        {
            $item.$name
        }
        else
        {
            $default
        }
    }
    else
    {
        $default
    }
}

function getServices
{
    $list = New-Object 'System.Collections.Generic.List[string]'
    $list.Add($MsmqName)
    $list
}

function getServiceConfiguration ($svcName)
{
    $rootKey = "HKLM:\Software\Microsoft\MSMQ\"
    if ($svcName -ne $MsmqName)
    {
        $rootKey += "Clustered QMs\$svcName\"
    }
    $rootKey += "Parameters\MachineCache";
    
    $machineQuota = getRegistryValue $rootKey "MachineQuota" 0
    $machineJournalQuota = getRegistryValue $rootKey "MachineJournalQuota" 0

@"
<Service>
  <Name>$svcName</Name>
  <MachineQuota>$machineQuota</MachineQuota>
  <MachineJournalQuota>$machineJournalQuota</MachineJournalQuota>
</Service>
"@
}

function main($document)
{
    $execIsDomainControllerText = getIsDomainController
    if ($execIsDomainControllerText.Length -gt 0)
    {
        $document.DocumentElement.CreateNavigator().AppendChild($execIsDomainControllerText)
    }

    $services = getServices
    foreach ($svc in $services)
    {
        $execServiceConfigurationText = getServiceConfiguration($svc)
        if ($execServiceConfigurationText.Length -gt 0)
        {
            $document.DocumentElement.CreateNavigator().AppendChild($execServiceConfigurationText)
        }
    }
}

#
# ------------------
# FUNCTIONS - END
# ------------------
#

#
# ------------------------
# SCRIPT MAIN BODY - START
# ------------------------
#

#
# Check if MSMQ is installed
#
$msmqInstalled = (isServiceInstalled $MsmqName)

#
# Create a new XmlDocument
#
$doc = createXmlDocument $XmlTargetNamespace $MsmqCompositeType

#
# If MSMQ is installed, we need to discover data related to that
#
if ($msmqInstalled -eq $true )
{
    main $doc
}

$doc

#
# ------------------------
# SCRIPT MAIN BODY - END
# ------------------------
#
