# Copyright © 2017, Microsoft Corporation. All rights reserved.
# :: ======================================================= ::

#====================================================================================
# Initialize
#====================================================================================
Import-LocalizedData -BindingVariable LocalizedStrings -FileName CL_LocalizationData

#====================================================================================
# Load Utilities
#====================================================================================
. .\Utils_BlueScreen.ps1

#====================================================================================
# Main
#====================================================================================

if(ispostbackOnWin "BlueScreenDiagnostic")
{
 	return
}

$temp = (Get-WmiObject -Class Win32_OperatingSystem).Version.Split(".")
[Float] $OSVersion = ($temp[0] + "." + $temp[1])
if($OSVersion -lt [Float](10.0))
{
	Get-DiagInput -ID 'INT_OS_NotSupported'
	return
}


# Retrieving Blue Screen event message(s) from Windows event log in the Last 7 days
$bugCheckEvents = @()
Get-WinEvent -LogName System -EA SilentlyContinue | 
Where-Object{$_.ProviderName -eq "Microsoft-Windows-WER-SystemErrorReporting" -and $_.TimeCreated -ge ((Get-Date).Date).AddDays(-7)} | 
ForEach-Object {$bugCheckEvents += $_}

if($bugCheckEvents){
		
	#Get bugcheck details by type
	$bugCheckProblemDriver= @()
	$bugCheckMalware= @()
	$bugCheckDiskFailure= @()
	$bugCheckMemoryFailure= @()
	$bugCheckBadHardware= @()
	$bugCheckProblemService= @()
	$bugCheckUnknown= @()

	foreach($bugCheckEvent in $bugCheckEvents)
	{
		[xml] $xmlEvent = $bugCheckEvent.ToXml()
		$bugCheckCodeWithParameters = $xmlEvent.Event.EventData.Data.Substring($xmlEvent.Event.EventData.Data.IndexOf('0x'))
		$bugCheckCodeWithParameters = ($bugCheckCodeWithParameters.Substring(0, ($bugCheckCodeWithParameters.IndexOf(")") + 1)))
		$bugCheckCodeWithParameters = $bugCheckCodeWithParameters.Replace(' ','').Replace('(',',').Replace(')','').Split(',')

		$errorCode = $bugCheckCodeWithParameters[0]
		$param1 = $bugCheckCodeWithParameters[1]
		$param2 = $bugCheckCodeWithParameters[2]
		$param3 = $bugCheckCodeWithParameters[3]
		$param4 = $bugCheckCodeWithParameters[4]

		#Get BugCheck Type (ProblemDriver, Malware, DiskFailure, MemoryFailure, BadHardware, ProblemService, Unknown)
		$type = Get-BugCheckType $errorCode

		$bugCheckDetailed = "" | Select TimeCreated, Type, ErrorCode, Param1, Param2, Param3, Param4

		$bugCheckDetailed.TimeCreated = $bugCheckEvent.TimeCreated
		$bugCheckDetailed.Type = $type
		$bugCheckDetailed.ErrorCode = $errorCode
		$bugCheckDetailed.Param1 = $param1
		$bugCheckDetailed.Param2 = $param2
		$bugCheckDetailed.Param3 = $param3
		$bugCheckDetailed.Param4 = $param4

		# Get date difference if more than seven days, write to telemetry
		$bluescreenOccured = Get-DateDifference($bugCheckEvent.TimeCreated)
		Write-DiagTelemetry -Property "BlueScreenOccuredInLastSevenDays" -Value $bluescreenOccured

		if ($type -eq "ProblemDriver"){
			$bugCheckProblemDriver += $bugCheckDetailed
			Write-DiagTelemetry -Property "BluescreenType" -Value $type
		}
		elseif ($type -eq "Malware"){
			$bugCheckMalware += $bugCheckDetailed
			Write-DiagTelemetry -Property "BluescreenType" -Value $type
		}
		elseif ($type -eq "DiskFailure"){
			$bugCheckDiskFailure += $bugCheckDetailed
			Write-DiagTelemetry -Property "BluescreenType" -Value $type
		}
		elseif ($type -eq "MemoryFailure"){
			$bugCheckMemoryFailure += $bugCheckDetailed
			Write-DiagTelemetry -Property "BluescreenType" -Value $type
		}
		elseif ($type -eq "BadHardware"){
			$bugCheckBadHardware += $bugCheckDetailed
			Write-DiagTelemetry -Property "BluescreenType" -Value $type
		}
		elseif ($type -eq "ProblemService"){
			$bugCheckProblemService += $bugCheckDetailed
			Write-DiagTelemetry -Property "BluescreenType" -Value $type
		}
		else{
			$bugCheckUnknown += $bugCheckDetailed
			Write-DiagTelemetry -Property "BluescreenType" -Value $type
		}
	}

	if($bugCheckProblemDriver){
		#ProblemDriver
		. .\RC_ProblemDriverBlueScreen.ps1 $bugCheckProblemDriver
	}
	if($bugCheckMalware){
		#Malware
		. .\RC_MalwareBlueScreen.ps1 $bugCheckMalware
	}
	if($bugCheckDiskFailure){
		#DiskFailure
		. .\RC_DiskFailureBlueScreen.ps1 $bugCheckDiskFailure
	}

	if($bugCheckMemoryFailure){
		#MemoryFailure
		. .\RC_MemoryFailureBlueScreen.ps1 $bugCheckMemoryFailure
	}

	if($bugCheckBadHardware){
		#BadHardware
		. .\RC_BadHardwareBlueScreen.ps1 $bugCheckBadHardware
	}

	if($bugCheckProblemService){
		#ProblemService
		. .\RC_ProblemServiceBlueScreen.ps1 $bugCheckProblemService
	}

	if($bugCheckUnknown){
		#Unknown
		. .\RC_UnknownBlueScreen.ps1 $bugCheckUnknown
	}
}
else
{
	Write-DiagTelemetry -Property "BlueScreenOccuredInLastSevenDays" -Value $false

	Catch [System.Exception]
	{
		Write-ExceptionTelemetry "TS_Main" $_
		$errorMsg =  $_.Exception.Message
		$errorMsg | ConvertTo-Xml | Update-DiagReport -Id "TS_Main" -Name "TS_Main" -Verbosity Debug
	}
}