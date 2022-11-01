# Install NuGet in order that we can install PSWindowsUpdate
Write-Host "Installing NuGet"
Install-PackageProvider -Name NuGet -Confirm:$False -Force -ErrorAction SilentlyContinue

# Install Test Module if not already
if (Get-Module -ListAvailable -Name Test) {
    Write-Host "Test Module exists" -ForegroundColor Green
    Update-Module -Name Test
    Import-Module Test
} 
else {
    Write-Host "Test Module does not exist" -ForegroundColor Red
    Install-Module -Name Test
    Import-Module Test
}