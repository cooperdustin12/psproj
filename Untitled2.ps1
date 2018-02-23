Function Plists([string]$a)
{
$FormatEnumerationLimit = 100
Gwmi win32_service |? {$_.PathName -Match 'svchost' -And $_.ProcessId -ne 0} | Group ProcessId | FT
   } # End of Function
Plists