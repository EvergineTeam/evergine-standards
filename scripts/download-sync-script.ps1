# scripts/download-sync-script.ps1
# Helper script to download the sync-standards.ps1 script to a local repository
# Useful for development, testing, or when you need a local override
#
# Examples:
#   .\scripts\download-sync-script.ps1
#   .\scripts\download-sync-script.ps1 -Destination "tools\sync-standards.ps1"
#   .\scripts\download-sync-script.ps1 -Ref "v1.2.0" -Force

param(
    # Remote source
    [string]$Org = "EvergineTeam",                    # Source GitHub organization
    [string]$Repo = "evergine-standards",            # Source repository name 
    [string]$Ref = "main",                           # Branch, tag, or commit to download from
    
    # Local destination
    [string]$Destination = "sync-standards.ps1",     # Local path where to save the script
    [switch]$Force                                   # Overwrite existing file without prompting
)

# Construct the download URL
$ScriptUrl = "https://raw.githubusercontent.com/$Org/$Repo/$Ref/scripts/sync-standards.ps1"

Write-Host "Download Sync Script Helper" -ForegroundColor Green
Write-Host "===========================" -ForegroundColor Green
Write-Host "Source: $ScriptUrl"
Write-Host "Destination: $Destination"
Write-Host

# Check if destination already exists
if (Test-Path $Destination) {
    if (-not $Force) {
        Write-Host "File already exists: $Destination" -ForegroundColor Yellow
        $response = Read-Host "Do you want to overwrite it? (y/N)"
        if ($response -notmatch '^[Yy]') {
            Write-Host "Download cancelled." -ForegroundColor Yellow
            exit 0
        }
    }
    Write-Host "Overwriting existing file..." -ForegroundColor Yellow
}

# Create destination directory if it doesn't exist
$DestinationDir = Split-Path $Destination -Parent
if ($DestinationDir -and -not (Test-Path $DestinationDir)) {
    Write-Host "Creating directory: $DestinationDir"
    New-Item -ItemType Directory -Path $DestinationDir -Force | Out-Null
}

# Download the script
try {
    Write-Host "Downloading script..." -ForegroundColor Cyan
    
    $response = Invoke-WebRequest -Uri $ScriptUrl -UseBasicParsing
    $response.Content | Out-File -FilePath $Destination -Encoding UTF8
    
    Write-Host "Successfully downloaded sync script to: $Destination" -ForegroundColor Green
}
catch {
    Write-Error "Failed to download script: $($_.Exception.Message)"
    exit 1
}