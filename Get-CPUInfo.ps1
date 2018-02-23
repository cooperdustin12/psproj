function Get-CPUInfo {
  <#
    .NOTES
        Author: greg zakharov
  #>
  
  $bf = {param([Int32]$i) [Reflection.BindingFlags]$i}
  
  $SYSTEM_INFO = ($Win32Native = [Object].Assembly.GetType(
    'Microsoft.Win32.Win32Native'
  )).GetNestedType(
    'SYSTEM_INFO', $bf.Invoke(32)
  ).InvokeMember(
    $null, $bf.Invoke(512), $null, $null, $null
  )
  
  $Win32Native.GetMethod(
    'GetSystemInfo', (&$bf 44)
  ).Invoke(
    $null, ($par = [Object[]]@($SYSTEM_INFO))
  )
  
  $SYSTEM_INFO.GetType().GetFields($bf.Invoke(36)) | % {
    '{0,-28}: {1}' -f $_.Name, $_.GetValue($par[0])
  }
}