<#
.SYNOPSIS
    Generic self-updating script for NSSM-managed services.
    
.DESCRIPTION
    Pulls latest code from git and restarts the specified NSSM service.
    Designed to be run via Task Scheduler for automatic updates.
    
.PARAMETER ServiceName
    Name of the NSSM service to restart after update.
    
.PARAMETER ProjectPath
    Path to the project directory containing the git repository.
    
.PARAMETER Branch
    Git branch to pull from (default: main).
    
.EXAMPLE
    .\update-and-restart.ps1 -ServiceName "ClineMCP" -ProjectPath "C:\Github\ClineMCP"
    
.EXAMPLE
    .\update-and-restart.ps1 -ServiceName "MyService" -ProjectPath "C:\Projects\MyApp" -Branch "develop"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ServiceName,
    
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath,
    
    [Parameter(Mandatory=$false)]
    [string]$Branch = "main"
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Logging function
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    Write-Host $logMessage
    
    # Also log to file if logs directory exists
    $logPath = Join-Path $ProjectPath "logs"
    if (Test-Path $logPath) {
        $logFile = Join-Path $logPath "update-and-restart.log"
        Add-Content -Path $logFile -Value $logMessage
    }
}

try {
    Write-Log "Starting update process for service: $ServiceName"
    Write-Log "Project path: $ProjectPath"
    Write-Log "Target branch: $Branch"
    
    # Check if project path exists
    if (-not (Test-Path $ProjectPath)) {
        Write-Log "Project path does not exist: $ProjectPath" "ERROR"
        exit 1
    }
    
    # Change to project directory
    Push-Location $ProjectPath
    
    # Check if it's a git repository
    if (-not (Test-Path ".git")) {
        Write-Log "Not a git repository: $ProjectPath" "ERROR"
        Pop-Location
        exit 1
    }
    
    # Get current commit before update
    $currentCommit = git rev-parse HEAD
    Write-Log "Current commit: $currentCommit"
    
    # Fetch latest changes
    Write-Log "Fetching latest changes from origin..."
    git fetch origin
    
    # Check if there are changes to pull
    $localCommit = git rev-parse HEAD
    $remoteCommit = git rev-parse origin/$Branch
    
    if ($localCommit -eq $remoteCommit) {
        Write-Log "Already up to date. No update needed."
        Pop-Location
        exit 0
    }
    
    Write-Log "New commits available. Pulling changes..."
    git pull origin $Branch
    
    # Get new commit after update
    $newCommit = git rev-parse HEAD
    Write-Log "Updated to commit: $newCommit"
    
    # Check if service exists
    $serviceExists = nssm status $ServiceName 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Service does not exist: $ServiceName" "ERROR"
        Pop-Location
        exit 1
    }
    
    # Stop the service
    Write-Log "Stopping service: $ServiceName"
    nssm stop $ServiceName
    
    # Wait for service to stop
    Start-Sleep -Seconds 5
    
    # Start the service
    Write-Log "Starting service: $ServiceName"
    nssm start $ServiceName
    
    # Verify service is running
    Start-Sleep -Seconds 3
    $serviceStatus = nssm status $ServiceName
    Write-Log "Service status: $serviceStatus"
    
    if ($serviceStatus -eq "SERVICE_RUNNING") {
        Write-Log "Service successfully restarted after update."
    } else {
        Write-Log "Service restart may have failed. Status: $serviceStatus" "WARNING"
    }
    
    Pop-Location
    Write-Log "Update process completed successfully."
    exit 0
    
} catch {
    Write-Log "Error during update process: $_" "ERROR"
    if (Test-Path $ProjectPath) {
        Pop-Location
    }
    exit 1
}
