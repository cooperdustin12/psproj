[CmdletBinding()]
Param (
	[Parameter(Mandatory = $true, Position = 1)]
	[String]$localIP = "__LOCALIPADDRESS__",
	[Parameter(Mandatory = $false, Position = 2)]
	[Int32]$lifeTimeDays = 365 * 50
)

function Create-SelfSignedCertificate {
    param ($hostname, $lifeTimeDays);

	$name = new-object -com "X509Enrollment.CX500DistinguishedName.1";
	$name.Encode("CN=$hostname", 0);

	$key = new-object -com "X509Enrollment.CX509PrivateKey.1";
	$key.ProviderName = "Microsoft RSA SChannel Cryptographic Provider";
	$key.KeySpec = 1;
	$key.Length = 2048;
	$key.SecurityDescriptor = "D:PAI(A;;0xd01f01ff;;;SY)(A;;0xd01f01ff;;;BA)(A;;0x80120089;;;NS)";
	$key.MachineContext = 1;
	$key.Create();

	$serverauthoid = new-object -com "X509Enrollment.CObjectId.1";
	$serverauthoid.InitializeFromValue("1.3.6.1.5.5.7.3.1");
	$ekuoids = new-object -com "X509Enrollment.CObjectIds.1";
	$ekuoids.add($serverauthoid);
	$ekuext = new-object -com "X509Enrollment.CX509ExtensionEnhancedKeyUsage.1";
	$ekuext.InitializeEncode($ekuoids);

	$cert = new-object -com "X509Enrollment.CX509CertificateRequestCertificate.1";
	$cert.InitializeFromPrivateKey(2, $key, "");
	$cert.Subject = $name;
	$cert.Issuer = $cert.Subject;

	# We subtract one day from the start time to avoid timezone or other 
	# time issues where cert is not yet valid
	$SubtractDays = New-Object System.TimeSpan 1, 0, 0, 0, 0;
	$curdate = get-date;
	$cert.NotBefore = $curdate.Subtract($SubtractDays);
	$cert.NotAfter = $cert.NotBefore.AddDays($lifeTimeDays);

	$cert.X509Extensions.Add($ekuext);
	$cert.Encode();

	$enrollment = new-object -com "X509Enrollment.CX509Enrollment.1";
	$enrollment.InitializeFromRequest($cert);
	$certdata = $enrollment.CreateRequest(0);
	$enrollment.InstallResponse(2, $certdata, 0, "");
}

$hostname = $localIP + "_Solarwinds_Zero_Configuration";
Create-SelfSignedCertificate $hostname $lifeTimeDays;