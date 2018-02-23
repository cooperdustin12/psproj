
 $url = 'http://google.com'

 # track execution time:
 $timeTaken = Measure-Command -Expression {
 $site = Invoke-WebRequest -Uri $url -UseBasicParsing
 }

 $milliseconds = $timeTaken.TotalMilliseconds

 $milliseconds = [Math]::Round($milliseconds, 0)

 $Context.SetValue($milliseconds);
 write-host $milliseconds