strFilename = "C:\tmp\dhcp\dhcpsrvlog-mon.log" 
strString = "ASSIGN" 
 
Call ReadUserIniFile(strFilename, strString) 
 
Sub ReadUserIniFile(strFilename,strLocation) 
     
    Dim objFSO, objTextFile, arrRecords, strSpan, strRow, objOption, AvailableComputers 
 
    Const ForReading = 1 
     
    Set objFSO = CreateObject("Scripting.FileSystemObject") 
    Set objTextFile = objFSO.OpenTextFile(strFilename, ForReading) 
     
    Do While objTextFile.AtEndOfStream <> True 
         
        strRow = objtextFile.Readline 
         
        If inStr(1,strRow, strLocation,1) > 0 Then 
 
            arrRecords = split(strRow, ",") 
             
            strDate = arrRecords(1) 
            strTime = arrRecords(2) 
            strMethod = arrRecords(3) 
            strIPAddress = arrRecords(4) 
            strComputername = arrRecords(5) 
            strMacaddress = arrRecords(6) 
             
            Wscript.echo "Found: " & strDate & " " & strTime & " " & _ 
            strMethod & " " & strComputername & " " & strMacaddress 
        End If 
 
    Loop 
 
End Sub 