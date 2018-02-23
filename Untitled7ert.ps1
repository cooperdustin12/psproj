 function Run-MailingStoredProc {
    param($sdt, $edt)
    $conn = New-Object System.Data.SqlClient.SqlConnection("Server=sqlcms.sql.vb.cbn.local; Database='CompassUtilityr'; Integrated Security=TRUE")
    $conn.Open()
    $cmd = $conn.CreateCommand()
    $cmd.CommandTimeout = 0
    $cmd.CommandText = "
                         Execute CompassUtility.SolarWinds.DBCC_ShrinkFile ‘VBMDESQL788’"
    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter($cmd)
    $dataset = New-Object System.Data.DataSet
    [void]$adapter.Fill($dataset)
    $dataset.tables[0]
    $conn.Close()
}  
