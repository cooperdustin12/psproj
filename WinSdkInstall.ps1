#
# This script launches a setup executable from a folder under TEMP to mitigate potential conflicts with Visual Studio 2015.
#

$ct = (Get-Variable MyInvocation).Value.MyCommand.CommandType
if ($ct -eq "ExternalScript")
{
    param(
        [string]$SetupExe = $null,
        [string]$SetupLogFolder = $null,
        [string]$PackageId = $null,
        [string]$SetupParameters = $null,
        [string]$LogFile = $null,
        [string]$CeipSetting = "on",
        [switch]$PayloadsNotYetDownloaded
    )

    $ScriptPath = $null
}

$ErrorActionPreference = "Stop"

$ErrorCodes = Data {
    ConvertFrom-StringData @'
    Success = 0
    NoScriptPath = 1
    InvalidArguments = 2
    AccessDenied = 3
    MissingSetupExe = 4
    ScriptException = 5
'@
}

function PrintMessage($Message)
{
    Write-Host $Message
    if ($LogFile)
    {
        Out-File -FilePath $LogFile -InputObject $Message -Append
    }
}

function PrintMessageAndExit($Message, $ReturnCode)
{
    PrintMessage $Message
    exit $ReturnCode
}

$Retry_SleepIntervalInSeconds = 120
$Retry_ErrorCodesAndRetryCounts = @{
    1618 = 3     # Another install is already in progress
    15605 = 3    # Download failure
}

$SdkError_InvalidOptionSpecified = 1001

$ERROR_EXE_MACHINE_TYPE_MISMATCH = 216

#
# Main execution sequence
#

try
{
    if (!$ScriptPath)
    {
        $ScriptPath = (Get-Variable MyInvocation).Value.MyCommand.Path
    }
    $ScriptDir = Split-Path -Parent $ScriptPath
}
catch {}

if (!$ScriptPath)
{
    PrintMessageAndExit "Unable to determine the script location." $ErrorCodes.NoScriptPath
}

if (!$SetupExe)
{
    PrintMessageAndExit "-setupexe argument is missing." $ErrorCodes.InvalidArguments
}

if ($LogFile -and !$SetupLogFolder)
{
    PrintMessageAndExit "-setuplogfolder argument is required when -logfile is specified." $ErrorCodes.InvalidArguments
}

if (!$PackageId)
{
    PrintMessageAndExit "-packageid argument is missing." $ErrorCodes.InvalidArguments
}

if (!$SetupParameters)
{
    PrintMessageAndExit "-setupparameters argument is missing." $ErrorCodes.InvalidArguments
}

try
{
    $TempDir = [IO.Path]::GetTempPath()

    # We sometimes support installing from internal shares using this script.
    # When doing this check for the appropriate package ID and set SetupExePath as desired.
    if ($FALSE)
    {
        switch ($PackageId)
        {
            default { throw [System.InvalidOperationException] "No internal path defined for $PackageId." }
        }

        Try
        {
            if (!(Test-Path $SetupExePath))
            {
                PrintMessage "Can't find setup executable at $SetupExePath"
                Exit $ErrorCodes.MissingSetupExe
            }
        }
        Catch [System.UnauthorizedAccessException]
        {
            PrintMessage "Current user is unable to access setup exectuable at $SetupExePath"
            Exit $ErrorCodes.AccessDenied
        }

        PrintMessage "Using temporary internal setup path $SetupExePath"
    }
    else
    {
        $OriginalSetupExe = (Join-Path $ScriptDir $SetupExe)
        if (!(Test-Path $OriginalSetupExe))
        {
            PrintMessageAndExit "$SetupExe not found in $ScriptDir." $ErrorCodes.MissingSetupExe
        }

        if ($PayloadsNotYetDownloaded)
        {
            # Create a folder under %TEMP% for the package
            $TargetDirName = $PackageId + "_" + (Get-Random)
            $TargetDir = Join-Path $TempDir $TargetDirName
        
            if ((Test-Path $TargetDir))
            {
                PrintMessage "Removing existing target folder $TargetDir."
                Remove-Item $TargetDir -Recurse -Force
            }
        
            PrintMessage "Creating target folder $TargetDir."
            New-Item $TargetDir -ItemType directory | out-null
            if (!(Test-Path $TargetDir))
            {
                PrintMessageAndExit "Unable to create target folder $TargetDir." $ErrorCodes.AccessDenied
            }
        
            Copy-Item $OriginalSetupExe $TargetDir
            $SetupExePath = Join-Path $TargetDir $SetupExe
        }
        else
        {
            # This is the case where we've already copied the necessary payloads locally.
            # So skip copying the setup exe to temp so all those msis and cabs get used instead of them being re-downloaded.
            $SetupExePath = $OriginalSetupExe
        }
    }

    if ($CeipSetting -ne "[CEIPConsentOnOff]")
    {
        $SetupParameters += " /Ceip $CeipSetting"
    }

    $NumAttempt = 1;
    Do
    {
        $SetupParametersLocal = $SetupParameters
        if ($LogFile)
        {
            $SetupExeBaseName = [Io.Path]::GetFileNameWithoutExtension($SetupExe)
            $LogFileBaseName = [Io.Path]::GetFileNameWithoutExtension($LogFile)
            $SdkLogFile = (Join-Path (Join-Path $TempDir $SetupLogFolder) ($LogFileBaseName + "." + $SetupExeBaseName + "_" + $NumAttempt + ".log"))
            $SetupParametersLocal += " /Log ""$SdkLogFile""" 
        }

        $Retry = $FALSE
        PrintMessage "Launching '$SetupExe' with arguments '$SetupParametersLocal'."
        $SetupProcess = Start-Process -FilePath $SetupExePath -ArgumentList $SetupParametersLocal -PassThru

        PrintMessage "Waiting for child process to terminate."
        Wait-Process -InputObject $SetupProcess

        $SetupProcessExitCode = $SetupProcess.ExitCode
        PrintMessage "Child process terminated with exit code $SetupProcessExitCode."

        # Special error codes
        if ($SetupProcessExitCode -eq $SdkError_InvalidOptionSpecified)
        {
            # This error code means that an invalid OptionId has been specified on the command line.
            # Because we know that we are passing the right OptionIds, the usual reason for getting this error
            # is when the SDK installer is running in Vista compatibility mode on Windows 7 and some of the options
            # are invalid on older OSes.
            # Re-map it to something more useful:
            $SetupProcessExitCode = $ERROR_EXE_MACHINE_TYPE_MISMATCH

            if ($LogFile)
            {
                PrintMessage "Error code $SdkError_InvalidOptionSpecified from the Windows SDK installer usually indicates that it was run in legacy OS compatibility mode."
                PrintMessage ""
                PrintMessage "Check the following registry keys and remove any instances of Visual Studio and Windows SDK Setup-related executables:"
                PrintMessage "    HKEY_CURRENT_USER\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"
                PrintMessage "    HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"
                PrintMessage "On 64-bit Windows, also check these registry keys:"
                PrintMessage "    HKEY_CURRENT_USER\Software\WOW6432Node\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"
                PrintMessage "    HKEY_LOCAL_MACHINE\Software\WOW6432Node\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"
                PrintMessage ""

                PrintMessage "Printing main log file:"
                Out-File -FilePath $LogFile -InputObject (Get-Content $SdkLogFile) -Append
            }
            Exit $SetupProcessExitCode
        }

        if (($Retry_ErrorCodesAndRetryCounts.ContainsKey($SetupProcessExitCode)) -and
            ($NumAttempt -le $($Retry_ErrorCodesAndRetryCounts.Get_Item($SetupProcessExitCode))))
        {
            $Retry = $TRUE
            $NumAttempt++
            PrintMessage "Encountered error $SetupProcessExitCode, sleeping for $Retry_SleepIntervalInSeconds seconds then retrying setup operation..."
            Start-Sleep -s $Retry_SleepIntervalInSeconds
            PrintMessage "Retrying setup operation, attempt $NumAttempt."
        }
    } While ($Retry)

    if ($LogFile -and ($SetupProcessExitCode -ne 0) -and ($SetupProcessExitCode -ne 3010))
    {
        PrintMessage "Unknown exit code detected. Printing main log file:"
        Out-File -FilePath $LogFile -InputObject (Get-Content $SdkLogFile) -Append
    }

    Exit $SetupProcessExitCode
}
catch
{
    PrintMessage $_.Exception.Message
    PrintMessage "  +CategoryInfo: " $_.CategoryInfo
    PrintMessage "  +FullyQualifiedErrorId: " $_.FullyQualifiedErrorId
    PrintMessage $_.ScriptStackTrace
    Exit $ErrorCodes.ScriptException
}
# SIG # Begin signature block
# MIIh9wYJKoZIhvcNAQcCoIIh6DCCIeQCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDmnJ80M+eS3cKt
# U5R2P8/x2HdNOp4ezZOiA+Xi3MKCtaCCC4IwggUKMIID8qADAgECAhMzAAABTjzx
# c/TdU1KlAAAAAAFOMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTAwHhcNMTYxMTE3MjE1OTEzWhcNMTgwMjE3MjE1OTEzWjCBgjEL
# MAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1v
# bmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEMMAoGA1UECxMDQU9D
# MR4wHAYDVQQDExVNaWNyb3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEB
# AQUAA4IBDwAwggEKAoIBAQC58xaRUfuTb7e5retoql6bh8UQIHbL7NTInOp1aKla
# gTVPjiHpEjqAiZ1vCfp5P2K/x7kAeQFzLwrzZznob1YPXaJu1UwZnB2sxQ4IFw88
# KsIkp6571Flb20zfJEZ0RH/w928jQh69E5f8InQbBBtUYxBcamMkXYk6TpVob5q8
# G9o81Tgy1Z9inFjIa4dBbSLOP6la//B2ot2T6JjkYlFd1M39J9x3wpKzBPw6IN7B
# tB5M6cgn8p4tz2kPo8W/o6K1mfmegp6S2kl0wIRyYD6wqAXd44XDEE67D7Z8tGLd
# 4wxctGnDIRovv8AwRgXFH+7KPsTe7bGWhmZV2E3t8kV/AgMBAAGjggF6MIIBdjAf
# BgNVHSUEGDAWBgorBgEEAYI3PQYBBggrBgEFBQcDAzAdBgNVHQ4EFgQUJjQeyo/y
# dAqO4lMtLxMqMxdTW4QwUQYDVR0RBEowSKRGMEQxDDAKBgNVBAsTA0FPQzE0MDIG
# A1UEBRMrMjMwODY1K2I0YjEyODc4LWUyOTMtNDNlOS1iMjFlLTdkMzA3MTlkNDUy
# ZjAfBgNVHSMEGDAWgBTm/F97uyIAWORyTrX0IXQjMubvrDBWBgNVHR8ETzBNMEug
# SaBHhkVodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9N
# aWNDb2RTaWdQQ0FfMjAxMC0wNy0wNi5jcmwwWgYIKwYBBQUHAQEETjBMMEoGCCsG
# AQUFBzAChj5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY0Nv
# ZFNpZ1BDQV8yMDEwLTA3LTA2LmNydDAMBgNVHRMBAf8EAjAAMA0GCSqGSIb3DQEB
# CwUAA4IBAQC9+Q5if4CpT6WHVNhhFj5CJv/i5cm/rFPoaBbnfRyg+AOi9iDtGq5c
# IN8UpX4XJP4ehzWEDoSsklYHQVOirfX8FVVGWCj4qj9swAh3nnP7nk7cWhmsCbK7
# 91CBDH71Rcj9NKkXpJpSkbcQ5QZyuu0YPGsAlrJw4sjewz738q7T2E8b4d1JCIN/
# S5zAqdmH45xPTwQJt/IxPgWdgWu43mlYCnNWhLZh+X4Tc9GFWmwxXJlEL89jbXQV
# F16qIpqC7hCBSYxa8vGUYvi7JIslKt8lVg17QOnDI06ti58ydAOUC22AygTJOR80
# ryuTlWvb/37N5+uLADMMDHVobyZ5G2WuMIIGcDCCBFigAwIBAgIKYQxSTAAAAAAA
# AzANBgkqhkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0
# aG9yaXR5IDIwMTAwHhcNMTAwNzA2MjA0MDE3WhcNMjUwNzA2MjA1MDE3WjB+MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYDVQQDEx9NaWNy
# b3NvZnQgQ29kZSBTaWduaW5nIFBDQSAyMDEwMIIBIjANBgkqhkiG9w0BAQEFAAOC
# AQ8AMIIBCgKCAQEA6Q5kUHlntcTj/QkATJ6UrPdWaOpE2M/FWE+ppXZ8bUW60zmS
# tKQe+fllguQX0o/9RJwI6GWTzixVhL99COMuK6hBKxi3oktuSUxrFQfe0dLCiR5x
# lM21f0u0rwjYzIjWaxeUOpPOJj/s5v40mFfVHV1J9rIqLtWFu1k/+JC0K4N0yiuz
# O0bj8EZJwRdmVMkcvR3EVWJXcvhnuSUgNN5dpqWVXqsogM3Vsp7lA7Vj07IUyMHI
# iiYKWX8H7P8O7YASNUwSpr5SW/Wm2uCLC0h31oVH1RC5xuiq7otqLQVcYMa0Kluc
# IxxfReMaFB5vN8sZM4BqiU2jamZjeJPVMM+VHwIDAQABo4IB4zCCAd8wEAYJKwYB
# BAGCNxUBBAMCAQAwHQYDVR0OBBYEFOb8X3u7IgBY5HJOtfQhdCMy5u+sMBkGCSsG
# AQQBgjcUAgQMHgoAUwB1AGIAQwBBMAsGA1UdDwQEAwIBhjAPBgNVHRMBAf8EBTAD
# AQH/MB8GA1UdIwQYMBaAFNX2VsuP6KJcYmjRPZSQW9fOmhjEMFYGA1UdHwRPME0w
# S6BJoEeGRWh0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3Rz
# L01pY1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNybDBaBggrBgEFBQcBAQROMEwwSgYI
# KwYBBQUHMAKGPmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWlj
# Um9vQ2VyQXV0XzIwMTAtMDYtMjMuY3J0MIGdBgNVHSAEgZUwgZIwgY8GCSsGAQQB
# gjcuAzCBgTA9BggrBgEFBQcCARYxaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL1BL
# SS9kb2NzL0NQUy9kZWZhdWx0Lmh0bTBABggrBgEFBQcCAjA0HjIgHQBMAGUAZwBh
# AGwAXwBQAG8AbABpAGMAeQBfAFMAdABhAHQAZQBtAGUAbgB0AC4gHTANBgkqhkiG
# 9w0BAQsFAAOCAgEAGnTvV08pe8QWhXi4UNMi/AmdrIKX+DT/KiyXlRLl5L/Pv5PI
# 4zSp24G43B4AvtI1b6/lf3mVd+UC1PHr2M1OHhthosJaIxrwjKhiUUVnCOM/PB6T
# +DCFF8g5QKbXDrMhKeWloWmMIpPMdJjnoUdD8lOswA8waX/+0iUgbW9h098H1dly
# ACxphnY9UdumOUjJN2FtB91TGcun1mHCv+KDqw/ga5uV1n0oUbCJSlGkmmzItx9K
# Gg5pqdfcwX7RSXCqtq27ckdjF/qm1qKmhuyoEESbY7ayaYkGx0aGehg/6MUdIdV7
# +QIjLcVBy78dTMgW77Gcf/wiS0mKbhXjpn92W9FTeZGFndXS2z1zNfM8rlSyUkdq
# wKoTldKOEdqZZ14yjPs3hdHcdYWch8ZaV4XCv90Nj4ybLeu07s8n07VeafqkFgQB
# pyRnc89NT7beBVaXevfpUk30dwVPhcbYC/GO7UIJ0Q124yNWeCImNr7KsYxuqh3k
# hdpHM2KPpMmRM19xHkCvmGXJIuhCISWKHC1g2TeJQYkqFg/XYTyUaGBS79ZHmaCA
# QO4VgXc+nOBTGBpQHTiVmx5mMxMnORd4hzbOTsNfsvU9R1O24OXbC2E9KteSLM43
# Wj5AQjGkHxAIwlacvyRdUQKdannSF9PawZSOB3slcUSrBmrm1MbfI5qWdcUxghXL
# MIIVxwIBATCBlTB+MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQ
# MA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
# MSgwJgYDVQQDEx9NaWNyb3NvZnQgQ29kZSBTaWduaW5nIFBDQSAyMDEwAhMzAAAB
# Tjzxc/TdU1KlAAAAAAFOMA0GCWCGSAFlAwQCAQUAoIG6MBkGCSqGSIb3DQEJAzEM
# BgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqG
# SIb3DQEJBDEiBCDOHHAy3cQrNXVXM/tVxKxaW1TcT9J7WF50ue/wURLixzBOBgor
# BgEEAYI3AgEMMUAwPqAkgCIAVwBpAG4AUwBkAGsASQBuAHMAdABhAGwAbAAuAHAA
# cwAxoRaAFGh0dHA6Ly9taWNyb3NvZnQuY29tMA0GCSqGSIb3DQEBAQUABIIBAApX
# POmgCC3K04UKA9N70ELcjGSEPtl3CVndR6ngz2ntmu7vAKwNHtwWT/zjmdjx85J+
# SbocvExHaeutY5EbOS0iMfkOhsf0JnXLatlypcaAcFFj8i5Usn2V3kXw8V7kMBFQ
# xvm+5+vs1jnaB9MFle6MJq3qMVOI4prd+6QoMsQBHLAxj1lmkC9uEJ6ZIwI8PsF5
# JTohxu7dAgBOhvvsug/TiFpVaDBN5JD2Xl0l3x+SXpV9Kk/WzGtd/bSInO8Ju+/q
# fbwP/+phkU3rSdd+6SsNrwJtAatftr5Ucdg8SfNSOlA/tBJtuNHsF7SCDfh1NdZ+
# AvxQCoNRvYVlgDnyHu+hghNJMIITRQYKKwYBBAGCNwMDATGCEzUwghMxBgkqhkiG
# 9w0BBwKgghMiMIITHgIBAzEPMA0GCWCGSAFlAwQCAQUAMIIBPAYLKoZIhvcNAQkQ
# AQSgggErBIIBJzCCASMCAQEGCisGAQQBhFkKAwEwMTANBglghkgBZQMEAgEFAAQg
# eIXIygD9VrAecWPHMQLyFoi4uJFDPS8t3n2VFnFV6RQCBlnXhynwbRgTMjAxNzEw
# MDYyMDM5NTEuNzQ5WjAHAgEBgAIB9KCBuKSBtTCBsjELMAkGA1UEBhMCVVMxEzAR
# BgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1p
# Y3Jvc29mdCBDb3Jwb3JhdGlvbjEMMAoGA1UECxMDQU9DMScwJQYDVQQLEx5uQ2lw
# aGVyIERTRSBFU046RDIzNi0zN0RBLTk3NjExJTAjBgNVBAMTHE1pY3Jvc29mdCBU
# aW1lLVN0YW1wIFNlcnZpY2Wggg7NMIIGcTCCBFmgAwIBAgIKYQmBKgAAAAAAAjAN
# BgkqhkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0
# b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3Jh
# dGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9y
# aXR5IDIwMTAwHhcNMTAwNzAxMjEzNjU1WhcNMjUwNzAxMjE0NjU1WjB8MQswCQYD
# VQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEe
# MBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3Nv
# ZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC
# AQoCggEBAKkdDbx3EYo6IOz8E5f1+n9plGt0VBDVpQoAgoX77XxoSyxfxcPlYcJ2
# tz5mK1vwFVMnBDEfQRsalR3OCROOfGEwWbEwRA/xYIiEVEMM1024OAizQt2TrNZz
# MFcmgqNFDdDq9UeBzb8kYDJYYEbyWEeGMoQedGFnkV+BVLHPk0ySwcSmXdFhE24o
# xhr5hoC732H8RsEnHSRnEnIaIYqvS2SJUGKxXf13Hz3wV3WsvYpCTUBR0Q+cBj5n
# f/VmwAOWRH7v0Ev9buWayrGo8noqCjHw2k4GkbaICDXoeByw6ZnNPOcvRLqn9Nxk
# vaQBwSAJk3jN/LzAyURdXhacAQVPIk0CAwEAAaOCAeYwggHiMBAGCSsGAQQBgjcV
# AQQDAgEAMB0GA1UdDgQWBBTVYzpcijGQ80N7fEYbxTNoWoVtVTAZBgkrBgEEAYI3
# FAIEDB4KAFMAdQBiAEMAQTALBgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAf
# BgNVHSMEGDAWgBTV9lbLj+iiXGJo0T2UkFvXzpoYxDBWBgNVHR8ETzBNMEugSaBH
# hkVodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNS
# b29DZXJBdXRfMjAxMC0wNi0yMy5jcmwwWgYIKwYBBQUHAQEETjBMMEoGCCsGAQUF
# BzAChj5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY1Jvb0Nl
# ckF1dF8yMDEwLTA2LTIzLmNydDCBoAYDVR0gAQH/BIGVMIGSMIGPBgkrBgEEAYI3
# LgMwgYEwPQYIKwYBBQUHAgEWMWh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9QS0kv
# ZG9jcy9DUFMvZGVmYXVsdC5odG0wQAYIKwYBBQUHAgIwNB4yIB0ATABlAGcAYQBs
# AF8AUABvAGwAaQBjAHkAXwBTAHQAYQB0AGUAbQBlAG4AdAAuIB0wDQYJKoZIhvcN
# AQELBQADggIBAAfmiFEN4sbgmD+BcQM9naOhIW+z66bM9TG+zwXiqf76V20ZMLPC
# xWbJat/15/B4vceoniXj+bzta1RXCCtRgkQS+7lTjMz0YBKKdsxAQEGb3FwX/1z5
# Xhc1mCRWS3TvQhDIr79/xn/yN31aPxzymXlKkVIArzgPF/UveYFl2am1a+THzvbK
# egBvSzBEJCI8z+0DpZaPWSm8tv0E4XCfMkon/VWvL/625Y4zu2JfmttXQOnxzplm
# kIz/amJ/3cVKC5Em4jnsGUpxY517IW3DnKOiPPp/fZZqkHimbdLhnPkd/DjYlPTG
# pQqWhqS9nhquBEKDuLWAmyI4ILUl5WTs9/S/fmNZJQ96LjlXdqJxqgaKD4kWumGn
# Ecua2A5HmoDF0M2n0O99g/DhO3EJ3110mCIIYdqwUB5vvfHhAN/nMQekkzr3ZUd4
# 6PioSKv33nJ+YWtvd6mBy6cJrDm77MbL2IK0cs0d9LiFAR6A+xuJKlQ5slvayA1V
# mXqHczsI5pgt6o3gMy4SKfXAL1QnIffIrE7aKLixqduWsqdCosnPGUFN4Ib5Kpqj
# EWYw07t0MkvfY3v1mYovG8chr1m1rtxEPJdQcdeh0sVV42neV8HR3jDA/czmTfsN
# v11P6Z0eGTgvvM9YBS7vDaBQNdrvCScc1bN+NR4Iuto229Nfj950iEkSMIIE2TCC
# A8GgAwIBAgITMwAAAK4O1k6WidsA9QAAAAAArjANBgkqhkiG9w0BAQsFADB8MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNy
# b3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDAeFw0xNjA5MDcxNzU2NTVaFw0xODA5
# MDcxNzU2NTVaMIGyMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQ
# MA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
# MQwwCgYDVQQLEwNBT0MxJzAlBgNVBAsTHm5DaXBoZXIgRFNFIEVTTjpEMjM2LTM3
# REEtOTc2MTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZTCC
# ASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAN6SL8OklXL1Pg1mZMP65ugi
# D3SMTcGex7ZUuPGPTn0f+0YwvnzLe57bxGdYki/6VIAGn6M+nxch/an/8MphvSj9
# BI4nyQZSgVh6w1M+2rJ/+qiEtbWtwuKOIWgwsAEf8YOcNuBFkfFUXEdQb4o3B990
# LQFgLdV+rf7a447xzNGWPXSBEdTYEryahLPndWjZnAXdMxnJWC8C+WDmxqs2BHAB
# jBvBZbnASql44MVfVUD+cB4uSOKsKaDzvkzVeITI+2tcMAUueDn/LkyUBxQxgnp0
# e5IEOosteKmONhqRCikHcfX72zyLIOgEzTsmo/27nlU/lraf8hkU03Akd4JNK8sC
# AwEAAaOCARswggEXMB0GA1UdDgQWBBR+j+U0NESL8nlAuMag0ZxDHiElsTAfBgNV
# HSMEGDAWgBTVYzpcijGQ80N7fEYbxTNoWoVtVTBWBgNVHR8ETzBNMEugSaBHhkVo
# dHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNUaW1T
# dGFQQ0FfMjAxMC0wNy0wMS5jcmwwWgYIKwYBBQUHAQEETjBMMEoGCCsGAQUFBzAC
# hj5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY1RpbVN0YVBD
# QV8yMDEwLTA3LTAxLmNydDAMBgNVHRMBAf8EAjAAMBMGA1UdJQQMMAoGCCsGAQUF
# BwMIMA0GCSqGSIb3DQEBCwUAA4IBAQA9WU148PRcNAjRtUFgA1MM+YymTeUiHqA8
# iKWDSEpClk0wAMtuaP6Rq/QZlzG1afCsGhH5+kGy5qjBaDDETEIcGjqaLHtEt4m8
# 3I1iUKTYlBP8ZrzRJFXM4Avk3GWzU+q8NuAWCENxFOalky8AN+rB27lHoU3IiB5x
# g2jJvsDgCoIt9XVbHc+s/Jpdtq2ySTmZPw2pYtguyEHO3YJrRuEkll/qpDCDqvaD
# PWkbXm57qcOr+aNilOYIOFjPjpvyvGsifSxDGcVOa2e2/PZnWMIaz32fWuvZkWsZ
# c4lLgGGfW3IoQXAYmOt9DgZvanID1opHBTIr0EcspYLlksPSEBogoYIDdzCCAl8C
# AQEwgeKhgbikgbUwgbIxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9u
# MRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRp
# b24xDDAKBgNVBAsTA0FPQzEnMCUGA1UECxMebkNpcGhlciBEU0UgRVNOOkQyMzYt
# MzdEQS05NzYxMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNl
# oiUKAQEwCQYFKw4DAhoFAAMVAMfBvTB7pRieZF5ndDb6u+OZvGj7oIHBMIG+pIG7
# MIG4MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
# UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMQwwCgYDVQQL
# EwNBT0MxJzAlBgNVBAsTHm5DaXBoZXIgTlRTIEVTTjoyNjY1LTRDM0YtQzVERTEr
# MCkGA1UEAxMiTWljcm9zb2Z0IFRpbWUgU291cmNlIE1hc3RlciBDbG9jazANBgkq
# hkiG9w0BAQUFAAIFAN2CWj0wIhgPMjAxNzEwMDYxOTM4MzdaGA8yMDE3MTAwNzE5
# MzgzN1owdzA9BgorBgEEAYRZCgQBMS8wLTAKAgUA3YJaPQIBADAKAgEAAgIIPwIB
# /zAHAgEAAgIaDTAKAgUA3YOrvQIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEE
# AYRZCgMBoAowCAIBAAIDFuNgoQowCAIBAAIDHoSAMA0GCSqGSIb3DQEBBQUAA4IB
# AQBHRpITRY7xaAzBHj/jSjCLyR2RgjBoMAVhNWfcG+AXPpM0G8FSdBMG4vMV4UEi
# aDhYuhY7AghcNnGkil17zqytpgHt7m1rjp9MwVih2ZmxS96DCxVjDQJkvwq4HCmd
# no1BmU9JsL2Fv5fsT/nYLHndUsOcZ9s99txh8o8b02FHvKe6KyVVSZDIvgRj53Ol
# 5UB6p1fknP9HuyJCvaFdoQ/ZOx3s6clUuRlGhbgK0FIx6R/TZo2QTGkzAqzvJBl5
# VYmMp8Bxp1zQJTevlWGHWKBmP3Em+EwVdB7Zm4FjiGC6xzFb2Nh7L8pCJT6wuuC/
# ueXTYl0rvIAedw3pLquhihFgMYIC9TCCAvECAQEwgZMwfDELMAkGA1UEBhMCVVMx
# EzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoT
# FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUt
# U3RhbXAgUENBIDIwMTACEzMAAACuDtZOlonbAPUAAAAAAK4wDQYJYIZIAWUDBAIB
# BQCgggEyMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRABBDAvBgkqhkiG9w0BCQQx
# IgQgvVeE35X2P/SUu0sE+rYwGm6y4R5N9bMlRupE2NR/I+kwgeIGCyqGSIb3DQEJ
# EAIMMYHSMIHPMIHMMIGxBBTHwb0we6UYnmReZ3Q2+rvjmbxo+zCBmDCBgKR+MHwx
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1p
# Y3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAAArg7WTpaJ2wD1AAAAAACu
# MBYEFNFbdXydwRkSXeTZRmXL9rNekRIPMA0GCSqGSIb3DQEBCwUABIIBADMSvy8e
# WL8MlGSRRnJMMczVtCXJmOyoLpwfJKUOlYrEsTHjsSOi2GCZqLSKQgeHBbI49Spj
# LfxMOEAVyqO/9LkivPMlpNrBiegjIyy+14YvnHq/Z10lq6hige529LcNzwpkQRFb
# C8ihH5RzsSWnJ5pHR5sccbl8RnQEpsfI8Ainxg2q1a+KU9wy17z1l0iJu/Xxkawt
# W0iQqevdGO6MXpQCQm4Q0VI0yLarMBGcaQPmfkHxqdBO9riCHyKXQgPwygie5Wbo
# ZiEINHFuar4oHNH/LbYmVtbG6vL2znwwcpjUSAD+UcBA5/rMWzWugNfLaQ4eLdBQ
# 4VYH3NO46aukB1s=
# SIG # End signature block
