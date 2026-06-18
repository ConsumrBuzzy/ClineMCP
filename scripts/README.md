# NSSM Service Management Scripts

Generic PowerShell scripts for managing self-updating NSSM services on Windows.

## Scripts

### update-and-restart.ps1

Pulls latest code from git and restarts a specified NSSM service.

**Usage:**
```powershell
.\update-and-restart.ps1 -ServiceName "ClineMCP" -ProjectPath "C:\Github\ClineMCP"
```

**Parameters:**
- `-ServiceName` (required): Name of the NSSM service to restart
- `-ProjectPath` (required): Path to the project directory containing the git repository
- `-Branch` (optional): Git branch to pull from (default: main)

**Features:**
- Checks for updates before pulling
- Only restarts service if changes were made
- Logs to console and `logs/update-and-restart.log` if logs directory exists
- Graceful service stop/start with NSSM
- Error handling with proper exit codes

### setup-scheduled-task.ps1

Creates a Windows Task Scheduler task for automatic service updates.

**Usage:**
```powershell
.\setup-scheduled-task.ps1 -ServiceName "ClineMCP" -ProjectPath "C:\Github\ClineMCP" -Schedule "Daily" -Time "02:00"
```

**Parameters:**
- `-ServiceName` (required): Name of the NSSM service
- `-ProjectPath` (required): Path to the project directory
- `-Branch` (optional): Git branch to pull from (default: main)
- `-Schedule` (optional): Frequency - "Hourly", "Daily", or "Weekly" (default: Daily)
- `-Time` (optional): Time to run task for Daily/Weekly schedules (default: 02:00)

**Features:**
- Creates task that runs as SYSTEM (required for service management)
- Configurable schedule (hourly, daily, weekly)
- Auto-restart on failure with retry logic
- Updates existing task if already present

## Setup Instructions

### 1. Install as NSSM Service (Run as Administrator)

```powershell
# Install the service
nssm install ClineMCP "C:\Github\ClineMCP\.venv\Scripts\python.exe" "-m clinemcp.main"

# Set working directory
nssm set ClineMCP AppDirectory "C:\Github\ClineMCP"

# Configure auto-restart on failure
nssm set ClineMCP AppRestartDelay 60000
nssm set ClineMCP AppThrottle 1500
nssm set ClineMCP AppExit Default Restart

# Set service to auto-start
nssm set ClineMCP Start SERVICE_AUTO_START

# Start the service
nssm start ClineMCP
```

### 2. Setup Scheduled Task for Auto-Updates

```powershell
# Daily updates at 2 AM
.\setup-scheduled-task.ps1 -ServiceName "ClineMCP" -ProjectPath "C:\Github\ClineMCP" -Schedule "Daily" -Time "02:00"

# Hourly updates (for development)
.\setup-scheduled-task.ps1 -ServiceName "ClineMCP" -ProjectPath "C:\Github\ClineMCP" -Schedule "Hourly"
```

### 3. Test the Update Process

```powershell
# Manually run the update script
.\update-and-restart.ps1 -ServiceName "ClineMCP" -ProjectPath "C:\Github\ClineMCP"

# Or trigger the scheduled task
Start-ScheduledTask -TaskName "Update_ClineMCP"
```

## Managing the Scheduled Task

```powershell
# View task status
Get-ScheduledTask -TaskName "Update_ClineMCP"

# View task history
Get-ScheduledTaskInfo -TaskName "Update_ClineMCP"

# Disable the task
Disable-ScheduledTask -TaskName "Update_ClineMCP"

# Enable the task
Enable-ScheduledTask -TaskName "Update_ClineMCP"

# Remove the task
Unregister-ScheduledTask -TaskName "Update_ClineMCP" -Confirm:$false
```

## Logging

Update logs are written to:
- Console output
- `logs/update-and-restart.log` (if logs directory exists)

## Security Notes

- The scheduled task runs as SYSTEM account (required for service management)
- Ensure the project directory and git repository have appropriate permissions
- Consider using git hooks or branch protection for production environments

## Troubleshooting

**Service won't start:**
```powershell
# Check service status
nssm status ClineMCP

# View service logs
nssm dump ClineMCP
```

**Update script fails:**
- Check git repository is accessible
- Verify service name is correct
- Check logs directory permissions
- Run script manually to see detailed errors

**Task Scheduler issues:**
- Verify Task Scheduler service is running
- Check task history in Task Scheduler GUI
- Ensure PowerShell execution policy allows script execution
