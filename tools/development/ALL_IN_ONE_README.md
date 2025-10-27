# GitHub Actions Multi-Runner Management System (All-in-One)

A single comprehensive script to manage multiple self-hosted GitHub Actions runners on one Linux machine.

## Quick Setup

1. **Download and make executable:**
   ```bash
   chmod +x github-runner-manager-all-in-one.sh
   ```

2. **Install the complete system:**
   ```bash
   sudo ./github-runner-manager-all-in-one.sh install
   ```

3. **Add your first runner:**
   ```bash
   sudo ./github-runner-manager-all-in-one.sh add
   ```

## Commands

### System Setup
```bash
sudo ./github-runner-manager-all-in-one.sh install    # Complete installation
sudo ./github-runner-manager-all-in-one.sh init       # Initialize system only
```

### Runner Management
```bash
# Interactive mode (recommended)
sudo ./github-runner-manager-all-in-one.sh add        # Add runner with prompts
sudo ./github-runner-manager-all-in-one.sh remove     # Remove runner with selection

# Direct mode
sudo ./github-runner-manager-all-in-one.sh add owner repo name token
sudo ./github-runner-manager-all-in-one.sh remove runner-id [removal-token]
```

### Operations
```bash
./github-runner-manager-all-in-one.sh list            # List all runners
./github-runner-manager-all-in-one.sh status          # System status
./github-runner-manager-all-in-one.sh monitor         # Real-time monitoring
./github-runner-manager-all-in-one.sh logs [runner-id] # View logs

# Start/Stop runners
sudo ./github-runner-manager-all-in-one.sh start [runner-id]
sudo ./github-runner-manager-all-in-one.sh stop [runner-id]
sudo ./github-runner-manager-all-in-one.sh restart [runner-id]
```

## Features

✅ **Complete Installation** - One command installs everything  
✅ **Interactive Mode** - User-friendly prompts for adding/removing runners  
✅ **Multi-Repository** - Multiple runners for different repositories  
✅ **Auto-Start** - Runners start automatically on system boot  
✅ **Real-time Monitoring** - Live status updates  
✅ **Systemd Integration** - Each runner runs as a service  
✅ **Docker Support** - Automatic Docker installation and configuration  
✅ **Detailed Logging** - Comprehensive logging and status information  

## Getting Registration Tokens

1. Go to your GitHub repository
2. Navigate to **Settings** → **Actions** → **Runners**
3. Click **"New self-hosted runner"**
4. Copy the token from the configuration command

## File Locations

- **Runners**: `/opt/actions-runners/`
- **Config**: `/etc/github-runners.conf`
- **Services**: `/etc/systemd/system/github-runner-*.service`

## Examples

```bash
# Install system
sudo ./github-runner-manager-all-in-one.sh install

# Add runner for myuser/myrepo
sudo ./github-runner-manager-all-in-one.sh add myuser myrepo server-01 ABCD1234567890

# Monitor all runners
./github-runner-manager-all-in-one.sh monitor

# View logs for specific runner
./github-runner-manager-all-in-one.sh logs myuser-myrepo-server-01

# Remove runner
sudo ./github-runner-manager-all-in-one.sh remove myuser-myrepo-server-01
```

## Troubleshooting

```bash
# Check system status
./github-runner-manager-all-in-one.sh status

# View runner logs
./github-runner-manager-all-in-one.sh logs runner-id

# Restart problematic runner
sudo ./github-runner-manager-all-in-one.sh restart runner-id

# Reinitialize system
sudo ./github-runner-manager-all-in-one.sh init
```

This single script replaces all the individual scripts and provides the complete functionality for managing multiple GitHub Actions runners.