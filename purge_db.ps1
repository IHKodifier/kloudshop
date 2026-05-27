# This script helps purge the local SQLite database for development.
$ErrorActionPreference = "Stop"

# Get the directory where the script is located
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Safety Check: Verify that the backend/.env exists and contains TESTING=1
$EnvFilePath = "$ScriptDir\backend\.env"
if (Test-Path $EnvFilePath) {
    $EnvContent = Get-Content $EnvFilePath
    $IsTesting = $false
    foreach ($Line in $EnvContent) {
        if ($Line -match "^\s*TESTING\s*=\s*(1|true)\s*$") {
            $IsTesting = $true
        }
    }
    if (-not $IsTesting) {
        Write-Error "Safety Error: This script can only be run in a local development environment. 'TESTING=1' must be enabled in backend/.env to target the local SQLite DB."
        exit 1
    }
} else {
    Write-Error "Safety Error: backend/.env file not found. Cannot verify development environment safety."
    exit 1
}

# Run the python purge script
python "$ScriptDir\backend\scripts\purge_db.py"
