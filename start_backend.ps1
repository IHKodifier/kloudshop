# This script navigates to the backend directory, activates the virtual environment, and starts the FastAPI server.
# It also launches the Flutter frontend in a separate terminal window.

$ErrorActionPreference = "Stop"

# Get the directory where the script is located
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Navigate to the backend directory
Set-Location -Path "$ScriptDir\backend"

Write-Host "Activating virtual environment..." -ForegroundColor Cyan
if (Test-Path "venv\Scripts\Activate.ps1") {
    . ".\venv\Scripts\Activate.ps1"
} else {
    Write-Host "Warning: Virtual environment not found at venv\Scripts\Activate.ps1" -ForegroundColor Yellow
}

Write-Host "Starting FastAPI Uvicorn Server on port 8000 (Verbose Logging Enabled)..." -ForegroundColor Green
uvicorn main:app --reload --port 8000 --log-level debug
