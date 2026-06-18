<#
.SYNOPSIS
    Setup Task Scheduler task for automatic service updates.
    
.DESCRIPTION
    Creates a Windows Task Scheduler task that runs the update-and-restart.ps1
    script on a schedule (e.g., daily or hourly).
    
.PARAMETER ServiceName
    Name of the NSSM service to update.
    
.PARAMETER ProjectPath
    Path to the project directory.
    
.PARAMETER Branch
    Git branch to pull from (default: main).
    
.PARAMETER Schedule
    Schedule frequency: "Hourly", "Daily", or "Weekly" (default: Daily).
    
.PARAMETER Time
    Time to run the task (for Daily/Weekly schedules, default: 02:00).
    
.EXAMPLE
    .\setup-scheduled-task.ps1 -ServiceName "ClineMCP" -ProjectPath "C:\Github\ClineMCP" -Schedule "Daily" -Time "02:00"
    
.EXAMPLE
    .\setup-scheduled-task.ps1 -ServiceName "MyService" -ProjectPath "C:\Projects\MyApp" -Schedule "Hourly"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ServiceName,
    
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath,
    
    [Parameter(Mandatory=$false)]
    [string]$Branch = "main",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Hourly", "Daily", "Weekly")]
    [string]$Schedule = "Daily",
    
    [Parameter(Mandatory=$false)]
    [string]$Time = "02:00"
)

$ErrorActionPreference = "Stop"

$scriptPath = Join-Path $ProjectPath "scripts\update-and-restart.ps1"
$taskName = "Update_$($ServiceName -replace '\s', '_')"

# Check if script exists
if (-not (Test-Path $scriptPath)) {
    Write-Error "Update script not found: $scriptPath"
    exit 1
}

# Build the task action
$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -ServiceName `"$ServiceName`" -ProjectPath `"$ProjectPath`" -Branch `"$Branch`"" `
    -WorkingDirectory $ProjectPath

# Build the trigger based on schedule
switch ($Schedule) {
    "Hourly" {
        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 1)
    }
    "Daily" {
        $trigger = New-ScheduledTaskTrigger -Daily -At $Time
    }
    "Weekly" {
        $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At $Time
    }
}

# Set principal (run as SYSTEM for service management)
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Create the task
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 5)

try {
    # Check if task already exists
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    
    if ($existingTask) {
        Write-Host "Updating existing task: $taskName"
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }
    
    Register-ScheduledTask `
        -TaskName $taskName `
        -Action $action `
        -Trigger $trigger `
        -Principal $principal `
        -Settings $settings `
        -Description "Auto-update and restart $ServiceName service from git" `
        | Out-Null
    
    Write-Host "Successfully created/updated scheduled task: $taskName"
    Write-Host "Schedule: $Schedule"
    if ($Schedule -ne "Hourly") {
        Write-Host "Time: $Time"
    }
    Write-Host ""
    Write-Host "To test the task immediately:"
    Write-Host "  Start-ScheduledTask -TaskName `"$taskName`""
    Write-Host ""
    Write-Host "To view task history:"
    Write-Host "  Get-ScheduledTaskInfo -TaskName `"$taskName`""
    
} catch {
    Write-Error "Failed to create scheduled task: $_"
    exit 1
}
