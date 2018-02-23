  function Get-DirectoryStats { 
    param( $directory, $recurse, $format ) 
 
    Write-Progress -Activity "Get-DirStats.ps1" -Status "Reading '$($directory.FullName)'" 
    $files = $directory | Get-ChildItem -Force -Recurse:$recurse | Where-Object { -not $_.PSIsContainer } 
    if ( $files ) { 
      Write-Progress -Activity "Get-DirStats.ps1" -Status "Calculating '$($directory.FullName)'" 
      $output = $files | Measure-Object -Sum -Property Length | Select-Object ` 
        @{Name="Path"; Expression={$directory.FullName}}, 
        @{Name="Files"; Expression={$_.Count; $script:totalcount += $_.Count}}, 
        @{Name="Size"; Expression={$_.Sum; $script:totalbytes += $_.Sum}} 
    } 
    else { 
      $output = "" | Select-Object ` 
        @{Name="Path"; Expression={$directory.FullName}}, 
        @{Name="Files"; Expression={0}}, 
        @{Name="Size"; Expression={0}} 
    } 
    if ( -not $format ) { $output } else { $output | Format-Output } 
  } 
} 