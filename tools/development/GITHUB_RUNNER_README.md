# GitHub Actions Runner Management System

A comprehensive solution for managing multiple self-hosted GitHub Actions runners on a single Linux machine. Each runner is dedicated to one repository and runs as an isolated systemd service.

## Features

- ✅ **Multi-Repository Support**: Run multiple runners for different repositories on one machine
- ✅ **Automatic Service Management**: Each runner runs as a systemd service with auto-restart
- ✅ **Easy Installation**: One-command installation with dependency management
- ✅ **Interactive Helper**: User-friendly interface for common operations
- ✅ **Real-time Monitoring**: Live status monitoring and log viewing
- ✅ **Automatic Startup**: All runners start automatically on system boot
- ✅ **Secure Isolation**: Each runner runs in its own directory with dedicated user
- ✅ **Docker Support**: Automatic Docker installation and runner user configuration

## Quick Start

### 1. Installation

```bash
# Clone or download the scripts
cd /path/to/linux-toolbox/tools/development

# Make installation script executable
chmod +x install-runner-system.sh

# Run installation (requires root)
sudo ./install-runner-system.sh
```

The installation will:
- Install system dependencies (wget, curl, tar, systemd)
- Install Docker (optional but recommended)
- Set up the runner management system
- Create system user and directories
- Configure automatic startup
- Create helpful command aliases

### 2. Add Your First Runner

```bash
# Interactive method (recommended for beginners)
runner-helper add

# Or direct method
sudo github-runner-manager add <owner> <repo> <runner-name> <registration-token>
```

To get a registration token:
1. Go to your GitHub repository
2. Navigate to **Settings** → **Actions** → **Runners**
3. Click **"New self-hosted runner"**
4. Copy the token from the configuration command

### 3. Monitor Your Runners

```bash
# List all runners
runner-helper list

# Real-time monitoring
runner-helper monitor

# View logs for a specific runner
runner-helper logs <runner-id>
```

## Commands Reference

### Main Management Script

```bash
# Initialize system (run once after installation)
sudo github-runner-manager init

# Add a new runner
sudo github-runner-manager add <owner> <repo> <name> <token>

# Remove a runner
sudo github-runner-manager remove <runner-id> [removal-token]

# List all runners
github-runner-manager list

# Start/stop runners
sudo github-runner-manager start [runner-id]
sudo github-runner-manager stop [runner-id]
sudo github-runner-manager restart [runner-id]

# Show runner status
github-runner-manager status [runner-id]
```

### Interactive Helper

```bash
# Interactive commands
runner-helper add          # Add runner with prompts
runner-helper remove       # Remove runner with selection
runner-helper monitor      # Real-time monitoring
runner-helper logs [id]    # View runner logs
runner-helper status       # System overview

# Quick commands
runner-helper list         # List runners
runner-helper start        # Start all runners
runner-helper stop         # Stop all runners
runner-helper restart      # Restart all runners
```

### Quick Aliases (after shell restart)

```bash
gr                         # runner-helper shortcut
grl                        # List runners
grs                        # System status
grm                        # Monitor runners
gra <owner> <repo> <name> <token>  # Add runner quickly
grr <runner-id>            # Remove runner
grlogs <runner-id>         # View logs
```

## Examples

### Adding Runners for Multiple Repositories

```bash
# Add runner for user/repo1
sudo github-runner-manager add myuser repo1 server-01 ABCD1234567890

# Add runner for user/repo2
sudo github-runner-manager add myuser repo2 server-01 EFGH0987654321

# Add runner for different user's repo
sudo github-runner-manager add otheruser somerepo server-01 IJKL1122334455
```

### Managing Runners

```bash
# List all runners
github-runner-manager list

# Output example:
# RUNNER ID                    REPOSITORY           NAME       STATUS     CREATED
# ────────────────────────────────────────────────────────────────────────────────
# myuser-repo1-server-01       myuser/repo1         server-01  RUNNING    2024-01-15
# myuser-repo2-server-01       myuser/repo2         server-01  RUNNING    2024-01-15
# otheruser-somerepo-server-01 otheruser/somerepo   server-01  STOPPED    2024-01-15

# Start specific runner
sudo github-runner-manager start myuser-repo1-server-01

# Stop all runners
sudo github-runner-manager stop

# View logs for a specific runner
runner-helper logs myuser-repo1-server-01
```

## System Architecture

### Directory Structure

```
/opt/actions-runners/              # Base directory for all runners
├── myuser-repo1-server-01/        # Runner for myuser/repo1
│   ├── config.sh                  # GitHub runner configuration
│   ├── run.sh                     # Runner execution script
│   └── _work/                     # Workspace for builds
├── myuser-repo2-server-01/        # Runner for myuser/repo2
│   └── ...
└── otheruser-somerepo-server-01/  # Runner for otheruser/somerepo
    └── ...
```

### Configuration Files

```
/etc/github-runners.conf           # Runner registry
/etc/systemd/system/github-runner-*.service  # Service files
/etc/profile.d/github-runners.sh   # Command aliases
/opt/linux-toolbox/tools/development/  # Script location
```

### Services

Each runner runs as an independent systemd service:
- **Service name**: `github-runner-<runner-id>.service`
- **User**: `github-runner`
- **Auto-restart**: Enabled
- **Auto-start**: On system boot

## Security Considerations

1. **Dedicated User**: All runners run as the `github-runner` user, not root
2. **Directory Isolation**: Each runner has its own isolated directory
3. **Docker Access**: The runner user is added to the docker group (if Docker is installed)
4. **Token Security**: Registration tokens are only used during setup and not stored

## Troubleshooting

### Common Issues

1. **Runner not starting**:
   ```bash
   # Check service status
   sudo systemctl status github-runner-<runner-id>.service
   
   # View logs
   sudo journalctl -u github-runner-<runner-id>.service -f
   ```

2. **Permission issues**:
   ```bash
   # Fix ownership
   sudo chown -R github-runner:github-runner /opt/actions-runners/
   ```

3. **Network connectivity**:
   ```bash
   # Test GitHub connectivity
   curl -I https://github.com
   ```

4. **Docker issues**:
   ```bash
   # Check if runner user can access Docker
   sudo -u github-runner docker ps
   ```

### Logs and Monitoring

```bash
# System-wide runner logs
sudo journalctl -u "github-runner-*" -f

# Specific runner logs
sudo journalctl -u github-runner-<runner-id>.service -f

# Monitor system resources
runner-helper monitor
```

### Recovery Procedures

1. **Reinitialize system**:
   ```bash
   sudo github-runner-manager init
   ```

2. **Rebuild a runner**:
   ```bash
   # Remove the problematic runner
   sudo github-runner-manager remove <runner-id>
   
   # Add it back with a new token
   sudo github-runner-manager add <owner> <repo> <name> <new-token>
   ```

3. **Update runner version**:
   Edit the `RUNNER_VERSION` variable in `github-runner-manager.sh` and reinstall runners.

## Advanced Configuration

### Custom Runner Labels

Edit the runner configuration in `github-runner-manager.sh`:
```bash
--labels "self-hosted,linux,x64,custom-label"
```

### Resource Limits

Add resource limits to systemd services by editing `/etc/systemd/system/github-runner-*.service`:
```ini
[Service]
MemoryLimit=2G
CPUQuota=200%
```

### Backup and Restore

```bash
# Backup configuration
cp /etc/github-runners.conf /backup/github-runners.conf.backup

# Backup runner directories (optional, mainly for workspace data)
tar -czf /backup/runners-backup.tar.gz /opt/actions-runners/
```

## Uninstallation

```bash
# Stop all runners
sudo github-runner-manager stop

# Remove all runners (with GitHub unregistration)
# Note: You'll need removal tokens for proper cleanup
runner-helper remove  # for each runner

# Remove system files
sudo rm -rf /opt/actions-runners/
sudo rm -f /etc/github-runners.conf
sudo rm -f /etc/systemd/system/github-runner-*.service
sudo rm -f /etc/systemd/system/github-runners-startup.service
sudo rm -f /etc/profile.d/github-runners.sh
sudo rm -f /usr/local/bin/github-runner-manager
sudo rm -f /usr/local/bin/runner-helper

# Remove user (optional)
sudo userdel -r github-runner

# Reload systemd
sudo systemctl daemon-reload
```

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review system logs: `sudo journalctl -u "github-runner-*" -f`
3. Verify system status: `runner-helper status`

## Contributing

Feel free to submit issues and enhancement requests!