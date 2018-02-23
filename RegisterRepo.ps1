Write-Host "Registering PSRepository..."

# Define repository
$name = 'EN30Repo'
$path = '\\cbn.local\nas\shares\EN30\PowerShellModules\Packages'

# Verify repository
if (-not (Test-Path $path)) { throw "Repository $path is offline" }

# Get current configuration
$repo = Get-PSRepository -Name $name -ErrorAction SilentlyContinue

# Register repository
if ($repo.SourceLocation -ne $path -or $repo.ScriptSourceLocation -ne $path) {
    $repo | Unregister-PSRepository
    Register-PSRepository -Name $name -SourceLocation $path -ScriptSourceLocation $path -InstallationPolicy Trusted
    Write-Host "    $name registration updated to $path`n"
}
elseif (-not $repo) {
    Register-PSRepository -Name $name -SourceLocation $path -ScriptSourceLocation $path -InstallationPolicy Trusted
    Write-Host "    $name registered at $path`n"
}
else {
    Write-Host "    $name already registered`n"
}
