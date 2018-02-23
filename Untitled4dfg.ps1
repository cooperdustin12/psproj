function execute-Sql{
    param($server, $db, $sql )
    $sqlConnection = new-object System.Data.SqlClient.SqlConnection
    $sqlConnection.ConnectionString = 'server=' + $server + ';integrated security=TRUE;database=' + $db 
    $sqlConnection.Open()
    $sqlCommand = new-object System.Data.SqlClient.SqlCommand
    $sqlCommand.CommandTimeout = 120
    $sqlCommand.Connection = $sqlConnection
    $sqlCommand.CommandText= $sql
    $text = $sql.Substring(0, 50)
    Write-Progress -Activity "Executing SQL" -Status "Executing SQL => $text..."
    Write-Host "Executing SQL => $text..."
    $result = $sqlCommand.ExecuteNonQuery()
    $sqlConnection.Close()
}