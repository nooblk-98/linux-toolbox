# SMB/CIFS Mount Manager

A comprehensive script for managing SMB/CIFS drive mounting on Linux systems with support for temporary and permanent mounts.

## Features

- **Temporary Mounts**: Mount SMB shares for current session only
- **Permanent Mounts**: Add SMB shares to `/etc/fstab` for automatic mounting on boot
- **Mount Management**: Easy add/remove functionality
- **Force Remove All**: Nuclear option to remove all SMB mounts at once
- **Security**: Secure credential storage in `/etc/samba/credentials/`
- **Interactive Menu**: User-friendly interface with colored output
- **Multiple Authentication**: Support for username/password and guest access
- **Domain Support**: Support for domain authentication
- **Dependency Management**: Automatic installation of required packages

## Requirements

- Linux system with root access
- `cifs-utils` package (auto-installed by script)
- SMB/CIFS server to connect to

## Installation

1. Make the script executable:
```bash
chmod +x smb-mount-manager.sh
```

2. Run as root (required for mounting operations):
```bash
sudo ./smb-mount-manager.sh
```

## Usage

### Interactive Mode (Recommended)
```bash
sudo ./smb-mount-manager.sh
```

### Command Line Options
```bash
# Mount temporarily
sudo ./smb-mount-manager.sh temp-mount

# Add permanent mount
sudo ./smb-mount-manager.sh perm-mount

# Remove mount
sudo ./smb-mount-manager.sh remove

# Force remove ALL SMB mounts (nuclear option)
sudo ./smb-mount-manager.sh force-remove-all

# List current mounts
./smb-mount-manager.sh list

# Install dependencies
sudo ./smb-mount-manager.sh install-deps

# Show help
./smb-mount-manager.sh help
```

## Mount Types

### Temporary Mount
- Mounts the SMB share for the current session only
- Share is unmounted when system reboots
- Quick access for one-time usage
- No changes to system configuration files

### Permanent Mount
- Adds mount configuration to `/etc/fstab`
- Automatically mounts on system boot
- Credentials stored securely in `/etc/samba/credentials/`
- Suitable for regularly accessed shares

### Force Remove All (Nuclear Option)
- Removes ALL SMB/CIFS mounts from the system
- Kills processes using the mounts with `fuser -km`
- Uses multiple unmount methods: normal → lazy → force
- Cleans up all fstab entries and credential files
- Removes empty mount directories
- Use when normal removal fails or for complete cleanup

## Security Features

1. **Credential Storage**: Passwords are stored in secure credential files with 600 permissions
2. **Root-only Access**: Credential files are owned by root:root
3. **Backup Creation**: Automatic backup of `/etc/fstab` before modifications
4. **Safe Removal**: Proper cleanup of credentials and fstab entries

## Default Mount Options

The script uses these default mount options for optimal compatibility:
- `uid=1000,gid=1000`: Mount with user ownership
- `iocharset=utf8`: UTF-8 character encoding
- `file_mode=0777,dir_mode=0777`: Full permissions for files and directories

## Directory Structure

```
/etc/samba/credentials/    # Secure credential storage
/mnt/smb/                 # Default mount base directory
/etc/fstab                # System mount configuration
```

## Examples

### Mounting a Windows Share
1. Server: `192.168.1.100`
2. Share: `shared_folder`
3. Username: `user`
4. Domain: `WORKGROUP`

The script will:
- Create mount point: `/mnt/smb/shared_folder`
- Store credentials securely
- Add appropriate fstab entry for permanent mounts

### Guest Access
For shares that allow guest access:
- Leave username field empty
- No credentials file will be created
- Mount uses `guest` option

## Troubleshooting

### Common Issues

1. **Permission Denied**
   - Ensure script is run with sudo/root privileges
   - Check SMB server allows the specified user

2. **Mount Failed**
   - Verify server IP/hostname is accessible
   - Check share name is correct
   - Ensure cifs-utils is installed

3. **Credentials Issues**
   - Verify username/password are correct
   - Check domain name if applicable
   - Ensure SMB server is running

### Verification Commands

```bash
# Check if mount is active
mount | grep cifs

# Test connectivity
ping <server-ip>

# Check SMB shares (if smbclient is available)
smbclient -L //<server-ip> -U <username>

# View mount options
cat /proc/mounts | grep cifs
```

## File Locations

- **Script**: `tools/network/smb-mount-manager.sh`
- **Credentials**: `/etc/samba/credentials/*.cred`
- **Mount Points**: `/mnt/smb/*`
- **Configuration**: `/etc/fstab`

## Compatibility

Tested on:
- Ubuntu/Debian (apt-get)
- CentOS/RHEL (yum)
- Fedora (dnf)
- Arch Linux (pacman)

## Notes

- Always test temporary mounts before making them permanent
- Keep backups of important data before mounting
- Monitor system logs for mount-related errors
- Regular cleanup of unused mount points recommended

## Support

For issues or feature requests, please check the main repository documentation or create an issue in the project repository.