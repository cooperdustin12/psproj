# Read in the input file and then loop through each entry
Get-Content C:\Users\dscoop\Desktop\pingsweep.txt | ForEach {

    # Use the Test-Connection cmdlet to determine if the machine is responding
    $pinged = Test-Connection -ComputerName $_ -Count 1 -Quiet
    # Use an If statement to determine if the machine responded or not and output accordingly
    If ($pinged) { Write-Host "$_ - OK" }
    Else { Write-Host "$_ - No Reply" }

}