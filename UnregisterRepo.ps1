Write-Host "Unregistering PSRepository..."

# Define repository
$name = 'EN30Repo'

# Unregister repository
Get-PSRepository -Name $name -ErrorAction SilentlyContinue | Unregister-PSRepository
Write-Host "    $name unregistered`n"