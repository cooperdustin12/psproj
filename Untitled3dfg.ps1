$SQLServer = "sqlcms.sql.vb.cbn.local"
$SQLDBName = "CompassUtility"
$uid ="NTD1\nocmonitoring"
$pwd = '1u$er4NOC'
$SqlQuery = "Execute CompassUtility.SolarWinds.DBCC_ShrinkFile ‘VBMDESQL788’"
$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
$SqlConnection.ConnectionString = "Server = $SQLServer; Database = $SQLDBName; Integrated Security = False; User ID = $uid; Password = $pwd;"
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = $SqlQuery
$SqlCmd.Connection = $SqlConnection
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd


$DataSet.Tables[0] | out-file "C:\tmp\sqlconnect.csv"