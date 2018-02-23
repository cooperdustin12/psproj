@echo off
cls
REM #PARAMETERS#
REM ===================
REM PSScript: 
REM     The filename of the script. Leave set to %~dpn0.ps1 to run a
REM     script with the same name as the batch file (with a .ps1
REM     extension instead).
REM
REM PSParams:
REM     The parameters of the script. Leave set to %1 to pass the first
REM     command line parameter specified launching the batch file to
REM     the script that is being called.
REM
REM     **Important**: If you need quotes use single quotes only!
REM
REM RunAsAdmin:
REM     1 for Yes; 0 for No. This should only need to be set if you are
REM     planning to run the script interactively on the local system.
REM
REM Interactive:
REM     Set to 1 if you wish to pause the script on exit.
REM
REM #USAGE#
REM =======
REM RunPowerShellScript.cmd "<scriptParams>"
REM
REM #EXAMPLE#
REM =========
REM RestartService.cmd "-ComputerName 'VBMDEAPP512' -ServiceName 'snmp', 'wsearch'"
REM

set PSScript=\\scripthost\ScriptLibrary-NOC\NocOperations\NocOperations.Export.ps1
set PSParams=-Run DailyOpReport
set RunAsAdmin=0
set Interactive=0

REM Launch Script
if %RunAsAdmin% EQU 1 (
    powershell.exe -Command "& {$process = Start-Process powershell.exe -ArgumentList ""-NoProfile -ExecutionPolicy Bypass -Command & ""'%PSScript%' %PSParams%"""" -PassThru -Wait -Verb RunAs; exit $process.ExitCode}"
) else (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& '%PSScript%' %PSParams%"
)

REM Exit
if %Interactive% EQU 1 (
	pause
)
