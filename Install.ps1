# Create Program Files directories
$HayabusaDir = "C:\Program Files\HayabusaToWinEventLog"
If(!(test-path $HayabusaDir)) {
  New-Item -ItemType Directory -Force -Path $HayabusaDir
}

# Download Hayabusa if it doesn't exist
$hayabusaExe = Get-ChildItem -Path $HayabusaDir -Recurse -Filter "*.exe" |
    Where-Object { $_.Name -match "hayabusa" }
	
if (!$hayabusaExe) {

# Define variables
$repo = "Yamato-Security/hayabusa"
$apiUrl = "https://api.github.com/repos/$repo/releases/latest"
$outputDir = "$env:TEMP\HayabusaDownload"

# Create output directory
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

# Get latest release info
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls
$response = Invoke-RestMethod -Uri $apiUrl

# Find Windows release asset (usually ends with .zip and contains 'windows')
$asset = $response.assets | Where-Object { $_.name -match 'win-x64.zip$' } | Select-Object -First 1

if ($null -eq $asset) {
    Write-Error "No suitable Windows release asset found."
    exit 1
}

# Download URL and output path
$downloadUrl = $asset.browser_download_url
$downloadPath = Join-Path $outputDir $asset.name

# Download the asset
Write-Host "Downloading $($asset.name)..."
Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPath

Write-Host "Downloaded to: $downloadPath"

Write-Host "Extracting $downloadPath to $HayabusaDir..."
Expand-Archive -Path $downloadPath -DestinationPath $HayabusaDir -Force

}

# Put a copy of the HayabusaToWinEventLog script in the Autoruns directory
copy "$PSScriptRoot\HayabusaToWinEventLog.ps1" "$HayabusaDir\HayabusaToWinEventLog.ps1"

$ST_A = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle hidden c:\PROGRA~1\HayabusaToWinEventLog\HayabusaToWinEventLog.ps1"
$ST_T = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 15)
$ST_P = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -RunLevel Highest -LogonType ServiceAccount
Register-ScheduledTask -TaskName "HayabusaToWinEventLog" -Action $ST_A -Trigger $ST_T -Principal $ST_P

$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -Hidden -ExecutionTimeLimit (New-TimeSpan -Minutes 60) -RestartCount 1 -StartWhenAvailable
Set-ScheduledTask -TaskName "HayabusaToWinEventLog" -Settings $settings

# Configure ACLs on Hayabusa installation folder, content may be regarded as sensitive (rules, hayabusa temporary output file...) and not suitable to be read by non privileged users. 
$acl = Get-Acl $HayabusaDir
$acl.SetAccessRuleProtection($true, $false) 
$acl.Access | ForEach-Object { $acl.RemoveAccessRule($_) }
$adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "BUILTIN\Administrators",
    "FullControl",
    "ContainerInherit,ObjectInherit",
    "None",
    "Allow"
)
$acl.AddAccessRule($adminRule)
Set-Acl -Path $HayabusaDir -AclObject $acl