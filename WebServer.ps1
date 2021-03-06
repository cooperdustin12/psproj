#
# ---------------------
# XSD SCHEMA DEFINITION
# ---------------------
#


#
# -----------------------------
# SCHEMATRON RULES DEFINITION
# -----------------------------
#


#
# -----------------------------
# TRANSLATIONS DEFINITION
# -----------------------------
#
data _system_translations {
   ConvertFrom-StringData @'
    	# ultimate fallback text

    	#
	# Execute/Script and Write for handler
	#
ExecuteWritePermissionsCheck_Title=Grant a handler execute/script or write permissions, but not both
ExecuteWritePermissionsCheck_Problem=The attribute 'accessPolicy' in the handlers section under path '{0}' is set to allow both Execute/Script and Write permissions.
ExecuteWritePermissionsCheck_Impact=By allowing both Execute/Script and Write permissions, a handler can run malicious code on the target server.
ExecuteWritePermissionsCheck_Resolution=Determine if the handler requires both Execute/Script and Write permissions, and revoke the one that is not needed.
ExecuteWritePermissionsCheck_Compliant=The IIS Best Practices Analyzer scan has determined that you are in compliance with this best practice.
	
	#
	# Expired Certificates
	#
ExpiredCertificatesCheck_Title=Make sure that your certificates are current
ExpiredCertificatesCheck_Problem=SSL Binding '{0}:{1}:' has a certificate that has expired, or will expire in 30 days. The certificate has thumbprint '{2}' and is located in store '{3}'.
ExpiredCertificatesCheck_Impact=An expired certificate becomes invalid and can prevent users from accessing your site.
ExpiredCertificatesCheck_Resolution=Renew the certificate or choose a new certificate for the site.
ExpiredCertificatesCheck_Compliant=The IIS Best Practices Analyzer scan has determined that you are in compliance with this best practice.
	
	#
	# notListedIsapisAllowed should not be true
	#
NotListedISAPIsAllowedCheck_Title=The configuration attribute 'notListedIsapisAllowed' should be false
NotListedISAPIsAllowedCheck_Problem=The configuration attribute 'notListedIsapisAllowed' in section 'system.webServer/security/isapiCgiRestriction' is set to true.
NotListedISAPIsAllowedCheck_Impact=Any unlisted ISAPI extension, including potentially malicious extensions, will be allowed to run.
NotListedISAPIsAllowedCheck_Resolution=Set 'notListedIsapisAllowed' to false and add each ISAPI extension to the list of allowed extensions.
NotListedISAPIsAllowedCheck_Compliant=The IIS Best Practices Analyzer scan has determined that you are in compliance with this best practice.
	
	#
	# notListedCgisAllowed should not be true
	#
NotListedCGIsAllowedCheck_Title=The configuration attribute 'notListedCgisAllowed' should be false
NotListedCGIsAllowedCheck_Problem=The configuration attribute 'notListedCgisAllowed' in section 'system.webServer/security/isapiCgiRestriction' is set to true.
NotListedCGIsAllowedCheck_Impact=Any unlisted CGI extension, including potentially malicious extensions, will be allowed to run.
NotListedCGIsAllowedCheck_Resolution=Set 'notListedCgisAllowed' to false and add each CGI extension to the allowed list.
NotListedCGIsAllowedCheck_Compliant=The IIS Best Practices Analyzer scan has determined that you are in compliance with this best practice.
	
	#
	# Application Pool should not be priviliged
	#
AppPoolIdentityCheck_Title=Application pools should be set to run as application pool identities
AppPoolIdentityCheck_Problem=Application pool '{0}' is set to run as an administrator, as local system, or to 'Act as part of the operating system'.
AppPoolIdentityCheck_Impact=The application pool can execute high-privileged code, including potentially malicious code that can negatively affect your server.
AppPoolIdentityCheck_Resolution=Set the application pool to run as the application pool identity.
AppPoolIdentityCheck_Compliant=The IIS Best Practices Analyzer scan has determined that you are in compliance with this best practice.

	#
	# Custom errors should be set to LocalOnly or Custom
	#
CustomErrorsCheck_Title=Hide Custom Errors from displaying remotely
CustomErrorsCheck_Problem=The errorMode attribute of section '{0}' [path:{1}] is set to Detailed.
CustomErrorsCheck_Impact=Users browsing to your site or application could see some privileged information that is contained in the detailed error pages being sent remotely.
CustomErrorsCheck_Resolution=Set the Custom Errors 'errorMode' to 'DetailedLocalOnly' or 'Custom'.
CustomErrorsCheck_Compliant=The IIS Best Practices Analyzer scan has determined that you are in compliance with this best practice.
	
	#
	# Basic Authentication should not be used without SSL
	#
BasicAuthSSLCheck_Title=Use SSL when you use Basic authentication
BasicAuthSSLCheck_Problem=Basic authentication is enabled for configuration path '{0}' but it lacks a required SSL binding.
BasicAuthSSLCheck_Impact=If you use Basic authentication without SSL, credentials will be sent in clear text that might be intercepted by malicious code.
BasicAuthSSLCheck_Resolution=Use Basic authentication with an SSL binding, and make sure that the site or application is set to require SSL. Alternatively, use a different method of authentication.
BasicAuthSSLCheck_Compliant=The IIS Best Practices Analyzer scan has determined that you are in compliance with this best practice.

'@
}
Import-LocalizedData -BindingVariable _system_translations -filename WebServer.psd1

#
# ------------------
# FUNCTIONS - START
# ------------------
#

#
# Function Description:
#  Creates the Document element for the Xml Document
#
# Arguments:
#  $ns - Namespace Name
#  $name - Name of the document element
#
# Return Value:
#  returns the created document element
#
function Create-DocumentElement( $ns, $name )
{
    [xml] "<$name xmlns='$ns'></$name>"
}

#
# Function Description:
#
#  This function will add the Server Manager module so that Roles
#  can be queried
#
# Arguments:
#
#  None
#
# Return Value:
#
#  None
#
function RoleQueryInitialize
{
    Import-Module ServerManager
}

#
# Function Description:
#
#  This function will remove the Server Manager module after the Roles
#  have been queried
#
# Arguments:
#
#  None
#
# Return Value:
#
#  None
#
function RoleQueryShutdown
{
    Remove-Module ServerManager
}

#
# Function Description:
#
#  This function will check to see if the specified role is installed
#
# Arguments:
#
#  $roleId - Id of the Role 
#
# Return Value:
#
#  $true - If Role is Installed
#  $false - If Role is not Installed
#
function IsRoleInstalled ( $roleId )
{
    $roleInstalled = $false
    
    #
    # Use the Server Manager CmdLet to obtain detail about Role
    #
    $Role = Get-WindowsFeature $roleId
    if ( $Role -ne $null ) 
    {
        $roleInstalled = $Role.Installed
    }

    $roleInstalled
}

function getExecuteAndWritePermissionHandlers
{
    $objects = @()
    $objects += get-webconfiguration '/system.webServer/handlers[(contains(@accessPolicy, "Script") and contains(@accessPolicy, "Write")) or (contains(@accessPolicy, "Execute") and contains(@accessPolicy, "Write"))]' -recurse
    if ($objects -ne $null)
    {
@"
<ExecuteWritePermissions>
$(
    foreach ($o in $objects)
    {
        $xpathQuery = $o.ItemXPath
        $commitPath = $o.PSPath
@"
<Section>
<Path>$xpathQuery</Path>
<Location>$commitPath</Location>
<AreWriteAndExecuteGranted>true</AreWriteAndExecuteGranted>
</Section>
"@
    }
)    
</ExecuteWritePermissions>
"@
    }
    else
    {
@"
<ExecuteWritePermissions>
<Section>
<Path></Path>
<Location></Location>
<AreWriteAndExecuteGranted>false</AreWriteAndExecuteGranted>
</Section>
</ExecuteWritePermissions>
"@
    }

}

function getExpiredCertificates
{
	$result = @()
	$sslBind = get-item iis:\sslbindings\*
	foreach ($b in $sslBind)
	{
		if ($b.Sites -eq $null -or $b.Sites.Count -eq 0) {continue}
		$p = join-path "cert:\LocalMachine" $b.Store
		$p = join-path $p $b.Thumbprint
		$cert = get-item $p
		if ($cert.NotAfter -le ([DateTime]::Now).AddDays(30))
		{
			$result += $b
		}
	}
	if ($result -ne $null)
	{
@"
<ExpiredCertificates>
$(	
		foreach ($b in $result)
		{
			$ip = $b.IPAddress
			$port = $b.port
			$hash = $b.Thumbprint
			$store = $b.Store
@"
<Binding>
	<IPAddress>$ip</IPAddress>
	<Port>$port</Port>
	<Hash>$hash</Hash>
	<Store>$store</Store>
	<Expired>true</Expired>
</Binding>		
"@
		}
)
</ExpiredCertificates>
"@		
	}
	else
	{
@"
<ExpiredCertificates>
<Binding>
<IPAddress></IPAddress>
<Port></Port>
<Hash></Hash>
<Store></Store>
<Expired>false</Expired>
</Binding>		
</ExpiredCertificates>
"@		
	}
}

function getNonListedIsapiAllowed
{
    $moduleInstalled = get-webconfiguration "/system.webServer/globalModules/add[@name='IsapiModule']" MACHINE/WEBROOT/APPHOST
    $moduleEnabled = get-webconfiguration "/system.webServer/modules/add[@name='IsapiModule']" MACHINE/WEBROOT/APPHOST -recurse
    if ($moduleInstalled -ne $null -and $moduleEnabled -ne $null)
    {
        $test = (get-webconfiguration /system.webServer/security/isapiCgiRestriction/@notListedIsapisAllowed MACHINE/WEBROOT/APPHOST).Value.ToString().ToLower()
@"
<NotListedIsapisAllowed>
<Enabled>$test</Enabled>
</NotListedIsapisAllowed>
"@
    }
}

function getNonListedCgiAllowed
{
    $moduleInstalled = get-webconfiguration "/system.webServer/globalModules/add[@name='CgiModule']" MACHINE/WEBROOT/APPHOST
    $moduleEnabled = get-webconfiguration "/system.webServer/modules/add[@name='CgiModule']" MACHINE/WEBROOT/APPHOST -recurse
    if ($moduleInstalled -ne $null -and $moduleEnabled -ne $null)
    {
        $test = (get-webconfiguration /system.webServer/security/isapiCgiRestriction/@notListedCgisAllowed MACHINE/WEBROOT/APPHOST).Value.ToString().ToLower()
@"
<NotListedCgisAllowed>
<Enabled>$test</Enabled>
</NotListedCgisAllowed>
"@
    }
}

function getAppPoolPrivilegedIdentity
{
	$ad = [adsi] "WinNT://$((get-item env:\computername).Value),computer"
	$admins = $ad.Children.Find("Administrators","group")
	$badPools = @()
	$sysPools = get-webconfiguration '/system.applicationHost/applicationPools/add/processModel[compare-string-ordinal(@identityType, "LocalSystem",false())=0]/parent::node()' -pspath MACHINE/WEBROOT/APPHOST
    if ($sysPools -ne $null)
    {
        $badPools += $sysPools
    }
	$servicePools = get-webconfiguration '/system.applicationHost/applicationPools/add/processModel[compare-string-ordinal(@identityType, "LocalService",false())=0]/parent::node()' -pspath MACHINE/WEBROOT/APPHOST
    if ($servicePools -ne $null)
    {
		$priv = [Microsoft.IIS.Powershell.Framework.LSAUtility]::GetUserRights("LocalService")
		if ($priv -contains 'SeTcbPrivilege')
		{
       		$badPools += $servicePools
		}
    }
	$servicePools = get-webconfiguration '/system.applicationHost/applicationPools/add/processModel[compare-string-ordinal(@identityType, "NetworkService",false())=0]/parent::node()' -pspath MACHINE/WEBROOT/APPHOST
    if ($servicePools -ne $null)
    {
		$priv = [Microsoft.IIS.Powershell.Framework.LSAUtility]::GetUserRights("NetworkService")
		if ($priv -contains 'SeTcbPrivilege')
		{
       		$badPools += $servicePools
		}
    }
	$specificUserPools = get-webconfiguration '/system.applicationHost/applicationPools/add/processModel[compare-string-ordinal(@identityType, "SpecificUser",false())=0]/parent::node()' -pspath MACHINE/WEBROOT/APPHOST
	foreach ($pool in $specificUserPools)
	{
		if ($pool -eq $null) {continue}
    
		trap {
			continue
		}
		$userName = $pool.processModel.userName
		if ($userName.Length -gt 0)
		{
			$adUser = $ad.Children.Find($userName,"user")
			$isAdmin = $admins.IsMember($adUser.Path)
			if ($isAdmin -eq $true)
			{
				$badPools += $pool
			}
			else
			{
				$priv = [Microsoft.IIS.Powershell.Framework.LSAUtility]::GetUserRights($userName)
				if ($priv -contains 'SeTcbPrivilege')
				{
					$badPools += $pool
				}
			}
		}	
	}
	if ($badPools -ne $null)
	{
@"
<AppPoolPrivilegedIdentity>
$(
	foreach ($o in $badPools)
	{
		$name = $o.name
@"
<ApplicationPool>
	<Name>$name</Name>
	<IsIdentityPrivileged>true</IsIdentityPrivileged>
</ApplicationPool>
"@		
	}
)
</AppPoolPrivilegedIdentity>
"@	
	}
	else
	{
@"
<AppPoolPrivilegedIdentity>
<ApplicationPool>
	<Name></Name>
	<IsIdentityPrivileged>false</IsIdentityPrivileged>
</ApplicationPool>
</AppPoolPrivilegedIdentity>
"@		
	}
}

function getCustomErrors
{
	$moduleInstalled = get-webconfiguration "/system.webServer/modules/add[@name='CustomErrorModule']" MACHINE/WEBROOT/APPHOST
	if ($moduleInstalled -ne $null)
	{
		$badSections = @()
		$badSections = get-webconfiguration "/system.webServer/httpErrors[@errorMode != '' and (compare-string-ordinal(@errorMode, 'DetailedLocalOnly', false())!=0 and compare-string-ordinal(@errorMode, 'Custom', false())!=0)]" MACHINE/WEBROOT/APPHOST -recurse
		if ($badSections -ne $null)
		{
@"
<CustomErrors>
$(
			foreach ($o in $badSections)
			{
				$xpathQuery = $o.ItemXPath
				$commitPath = $o.PSPath
@"
<Section>
<Path>$xpathQuery</Path>
<Location>$commitPath</Location>
<ErrorModeCompliant>false</ErrorModeCompliant>
</Section>
"@
			}
)			
</CustomErrors>
"@
		}
		else
		{
@"
<CustomErrors>
<Section>
<Path></Path>
<Location></Location>
<ErrorModeCompliant>true</ErrorModeCompliant>
</Section>
</CustomErrors>
"@
		}
	}
}

function getBasicAuthSSL
{
	$moduleInstalled = get-webconfiguration "/system.webServer/globalModules/add[@name='BasicAuthenticationModule']" MACHINE/WEBROOT/APPHOST
	$moduleEnabled = get-webconfiguration "/system.webServer/modules/add[@name='BasicAuthenticationModule']" MACHINE/WEBROOT/APPHOST -recurse
	if (($moduleInstalled -ne $null) -and ($moduleEnabled -ne $null))
	{
		$result = @()
		$enabledSites = @()
		$enabledSites = get-webconfiguration "/system.webServer/security/authentication/basicAuthentication[@enabled='true']" MACHINE/WEBROOT/APPHOST -recurse
		if ($enabledSites -ne $null)
		{
			foreach ($s in $enabledSites)
			{
				$p = $s.PSPath
				if ($s.Location -ne $null -and $s.Location -ne "")
				{
						$p += "/" + $s.Location
				}
				$flags = get-webconfiguration "/system.webServer/security/access/@sslFlags" $p
				if ( $flags -ne $null )
				{
					try {
					$arr = $flags.Split(",")
					}
					catch {	
					}
					
					if ($arr -contains "Ssl") {continue}
					$result += $s
				}
				
			}
		}
		if ($result -ne $null)
		{
@"
<BasicAuthSSL>
$(
			foreach ($o in $result)
			{
				$name = $o.PSPath + "/" + $o.Location
@"
<Section>
<Location>$name</Location>
<IsBasicAuthEnabledWithoutSSL>true</IsBasicAuthEnabledWithoutSSL>
</Section>
"@		
			}
)
</BasicAuthSSL>
"@
		}
		else
		{
@"
<BasicAuthSSL>
<Section>
<Location></Location>
<IsBasicAuthEnabledWithoutSSL>false</IsBasicAuthEnabledWithoutSSL>
</Section>
</BasicAuthSSL>
"@
		}
	}
}

function main($document)
{
    $execWriteHandlersText = getExecuteAndWritePermissionHandlers
    if ($execWriteHandlersText.Length -gt 0)
    {
        $document.DocumentElement.CreateNavigator().AppendChild($execWriteHandlersText)
    }

    $poolPrivText = getAppPoolPrivilegedIdentity
    if ($poolPrivText.Length -gt 0)
    {
        $document.DocumentElement.CreateNavigator().AppendChild($poolPrivText)
    }
    
    $isapis = getNonListedIsapiAllowed
    if ($isapis.Length -gt 0)
    {
        $document.DocumentElement.CreateNavigator().AppendChild($isapis)
    }

    $cgis = getNonListedCgiAllowed
    if ($cgis.Length -gt 0)
    {
        $document.DocumentElement.CreateNavigator().AppendChild($cgis)
    }

    $errorMode = getCustomErrors
    if ($errorMode.Length -gt 0)
    {
        $document.DocumentElement.CreateNavigator().AppendChild($errorMode)
    }
    
    $expiredCerts = getExpiredCertificates
    if ($expiredCerts.Length -gt 0)
    {
		$document.DocumentElement.CreateNavigator().AppendChild($expiredCerts)
    }
    
    $authSsl = getBasicAuthSSL
    if ($authSsl.Length -gt 0)
    {
		$document.DocumentElement.CreateNavigator().AppendChild($authSsl)
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
# Initialize to perform querying Role information
#
RoleQueryInitialize

$WSWebInstalled = IsRoleInstalled "Web-WebServer"

#
# Role Information obtained.
#
RoleQueryShutdown

# 
# Set the Target Namespace to be used by XML
#
$tns="http://schemas.microsoft.com/bestpractices/models/ServerManager/WebServer/WebServerComposite/2008/04"

#
# Create a new XmlDocument
#
$doc = Create-DocumentElement $tns "WebServerComposite"

import-module WebAdministration

#
# If WSWebServer installed, we need to discover data related to that
#
if ( $WSWebInstalled -eq $true )
{
    main $doc
}

$doc

#
# ------------------------
# SCRIPT MAIN BODY - END
# ------------------------
#