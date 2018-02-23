# This script will output the number of days remaining until an SSL certificate will expire.
# The script argument was designed so that the Node Name is also the name of the domain name.
# If the node name and the domain name do not match then replace ${Node.Caption} with the 
#  respective domain name 
# The baseline for the script was found at http://www.zerrouki.com/checkssl/
# Modified by Chad Every to use within SolarWinds. Date: 10/9/2015

#$WebsiteDomainName=$args[0]
$WebsiteDomainName="www.solarwinds.com"
#$WebsiteDomainName="www.inmoment.com"
$WebsitePort=443 
 
Try 
{
    $Conn = New-Object System.Net.Sockets.TcpClient($WebsiteDomainName,$WebsitePort) 
  
    Try 
	{
        $Stream = New-Object System.Net.Security.SslStream($Conn.GetStream())
        $Stream.AuthenticateAsClient($WebsiteDomainName) 
   
        $Cert = $Stream.Get_RemoteCertificate()
        
		$CertCA = $Cert.GetIssuerName()
		$CertCAStart = $CertCA.IndexOf(" O=") + 3
		$CertCAEnd = $CertCA.IndexOf(" OU=") - $CertCAStart - 1

        If ($CertCAStart -lt 1 -or $CertCAEnd -lt 1 )
        {
            $CertCA = "Unable to parse Certificate Authority"
        }
        else
        {
            $CertCA = $CertCA.Substring($CertCAStart,$CertCAEnd)
        }
        

        $CertCN = $Cert.Subject | %{ $_.Split(',')[0]; }
        $ValidTo = [datetime]::Parse($Cert.GetExpirationDateString())
 
        [int]$ValidDays = $($ValidTo - [datetime]::Now).Days

        Write-Host "Message : Website: $WebsiteDomainName, Certificate Expiration: $ValidTo, Common Name: $CertCN, Certificate Authority: $CertCA"
        Write-Host "Statistic : $ValidDays"

    }
    Catch { Throw $_ }
    Finally { $Conn.close() }
    exit 0
    }
Catch 
{
            Write-Host "Message : Error occurred connecting to $($WebsiteDomainName), Code: $_.exception.innerexception.message"
            Write-Host "Statistic : 0"
            exit 1
}