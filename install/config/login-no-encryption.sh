#!/bin/bash

# Modified login.sh script with disk encryption dependencies removed and robust error handling
# This script configures graphical login without requiring disk encryption (LUKS)

# Function for logging errors and continuing execution
log_error() {
    echo "ERROR: $1" >&2
    echo "Continuing with script execution..."
}

# Function to safely run commands with error handling
safe_run() {
    local cmd="$1"
    local description="$2"
    
    echo "Running: $description"
    if ! eval "$cmd"; then
        log_error "Failed to execute: $description"
        return 1
    fi
    return 0
}

# Install required packages with error handling
echo "Installing required packages..."
if ! command -v uwsm &>/dev/null; then
    safe_run "sudo pacman -U --noconfirm https://archive.archlinux.org/packages/u/uwsm/uwsm-0.23.0-1-any.pkg.tar.zst" "Installing UWSM"
fi

# Note: Plymouth installation removed as it's primarily useful for disk encryption boot screens
# Users without encryption typically don't need boot splash screens

# ==============================================================================
# KERNEL PARAMETERS SETUP (OPTIONAL)
# ==============================================================================
# Adding quiet parameter for cleaner boot (splash removed as plymouth is not installed)

echo "Configuring kernel parameters for cleaner boot..."

if [ -d "/boot/loader/entries" ]; then # systemd-boot
    echo "Detected systemd-boot"
    
    for entry in /boot/loader/entries/*.conf; do
        if [ -f "$entry" ]; then
            # Skip fallback entries
            if [[ "$(basename "$entry")" == *"fallback"* ]]; then
                echo "Skipped: $(basename "$entry") (fallback entry)"
                continue
            fi
            
            # Add quiet parameter only (no splash since no plymouth)
            if ! grep -q "quiet" "$entry"; then
                safe_run "sudo sed -i '/^options/ s/$/ quiet/' \"$entry\"" "Adding quiet parameter to $(basename "$entry")"
            else
                echo "Skipped: $(basename "$entry") (quiet already present)"
            fi
        fi
    done
elif [ -f "/etc/default/grub" ]; then # Grub
    echo "Detected grub"
    
    # Backup GRUB config before modifying
    backup_timestamp=$(date +"%Y%m%d%H%M%S")
    safe_run "sudo cp /etc/default/grub \"/etc/default/grub.bak.${backup_timestamp}\"" "Backing up GRUB config"
    
    # Check if quiet is already in GRUB_CMDLINE_LINUX_DEFAULT
    if ! grep -q "GRUB_CMDLINE_LINUX_DEFAULT.*quiet" /etc/default/grub; then
        # Get current GRUB_CMDLINE_LINUX_DEFAULT value
        current_cmdline=$(grep "^GRUB_CMDLINE_LINUX_DEFAULT=" /etc/default/grub | cut -d'"' -f2)
        
        # Add quiet if not present (no splash since no plymouth)
        new_cmdline="$current_cmdline"
        if [[ ! "$current_cmdline" =~ quiet ]]; then
            new_cmdline="$new_cmdline quiet"
        fi
        
        # Trim any leading/trailing spaces
        new_cmdline=$(echo "$new_cmdline" | xargs)
        
        safe_run "sudo sed -i \"s/^GRUB_CMDLINE_LINUX_DEFAULT=\\\".*\\\"/GRUB_CMDLINE_LINUX_DEFAULT=\\\"$new_cmdline\\\"/\" /etc/default/grub" "Updating GRUB config"
        
        # Regenerate grub config
        safe_run "sudo grub-mkconfig -o /boot/grub/grub.cfg" "Regenerating GRUB config"
    else
        echo "GRUB already configured with quiet kernel parameters"
    fi
elif [ -d "/etc/cmdline.d" ]; then # UKI
    echo "Detected a UKI setup"
    # Only add quiet parameter (no splash since no plymouth)
    if ! grep -q quiet /etc/cmdline.d/*.conf 2>/dev/null; then
        safe_run "echo 'quiet' | sudo tee -a /etc/cmdline.d/omarchy.conf" "Adding quiet parameter to UKI config"
    fi
elif [ -f "/etc/kernel/cmdline" ]; then # UKI Alternate
    echo "Detected a UKI setup"
    
    # Backup kernel cmdline config before modifying
    backup_timestamp=$(date +"%Y%m%d%H%M%S")
    safe_run "sudo cp /etc/kernel/cmdline \"/etc/kernel/cmdline.bak.${backup_timestamp}\"" "Backing up kernel cmdline"
    
    current_cmdline=$(cat /etc/kernel/cmdline)
    
    # Add quiet if not present (no splash since no plymouth)
    new_cmdline="$current_cmdline"
    if [[ ! "$current_cmdline" =~ quiet ]]; then
        new_cmdline="$new_cmdline quiet"
    fi
    
    # Trim any leading/trailing spaces
    new_cmdline=$(echo "$new_cmdline" | xargs)
    
    # Write new file
    safe_run "echo $new_cmdline | sudo tee /etc/kernel/cmdline" "Updating kernel cmdline"
else
    echo ""
    echo " None of systemd-boot, GRUB, or UKI detected. For cleaner boot, manually add:"
    echo "  - quiet (for silent boot)"
    echo ""
fi

# ==============================================================================
# SEAMLESS LOGIN SETUP
# ==============================================================================

echo "Setting up seamless login..."

if [ ! -x /usr/local/bin/seamless-login ]; then
    echo "Compiling seamless login helper..."
    # Compile the seamless login helper -- needed to prevent seeing terminal between loader and desktop
    cat <<'CCODE' >/tmp/seamless-login.c
/*
* Seamless Login - Minimal SDDM-style transition (no plymouth dependency)
* Replicates SDDM's VT management for seamless auto-login
*/
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/kd.h>
#include <linux/vt.h>
#include <sys/wait.h>
#include <string.h>

int main(int argc, char *argv[]) {
    int vt_fd;
    int vt_num = 1; // TTY1
    char vt_path[32];
    
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <session_command>\n", argv[0]);
        return 1;
    }
    
    // Open the VT (simple approach like SDDM)
    snprintf(vt_path, sizeof(vt_path), "/dev/tty%d", vt_num);
    vt_fd = open(vt_path, O_RDWR);
    if (vt_fd < 0) {
        perror("Failed to open VT");
        return 1;
    }
    
    // Activate the VT
    if (ioctl(vt_fd, VT_ACTIVATE, vt_num) < 0) {
        perror("VT_ACTIVATE failed");
        close(vt_fd);
        return 1;
    }
    
    // Wait for VT to be active
    if (ioctl(vt_fd, VT_WAITACTIVE, vt_num) < 0) {
        perror("VT_WAITACTIVE failed");
        close(vt_fd);
        return 1;
    }
    
    // Critical: Set graphics mode to prevent console text
    if (ioctl(vt_fd, KDSETMODE, KD_GRAPHICS) < 0) {
        perror("KDSETMODE KD_GRAPHICS failed");
        close(vt_fd);
        return 1;
    }
    
    // Clear VT and close (like SDDM does)
    const char *clear_seq = "\33[H\33[2J";
    if (write(vt_fd, clear_seq, strlen(clear_seq)) < 0) {
        perror("Failed to clear VT");
    }
    
    close(vt_fd);
    
    // Set working directory to user's home
    const char *home = getenv("HOME");
    if (home) chdir(home);
    
    // Now execute the session command
    execvp(argv[1], &argv[1]);
    perror("Failed to exec session");
    return 1;
}
CCODE

    if safe_run "gcc -o /tmp/seamless-login /tmp/seamless-login.c" "Compiling seamless login helper"; then
        safe_run "sudo mv /tmp/seamless-login /usr/local/bin/seamless-login" "Installing seamless login helper"
        safe_run "sudo chmod +x /usr/local/bin/seamless-login" "Setting executable permissions"
        safe_run "rm -f /tmp/seamless-login.c" "Cleaning up source file"
    fi
fi

if [ ! -f /etc/systemd/system/omarchy-seamless-login.service ]; then
    echo "Creating seamless login service..."
    cat <<EOF | sudo tee /etc/systemd/system/omarchy-seamless-login.service >/dev/null
[Unit]
Description=Omarchy Seamless Auto-Login (No Encryption)
Documentation=https://github.com/basecamp/omarchy
Conflicts=getty@tty1.service
After=systemd-user-sessions.service getty@tty1.service systemd-logind.service
PartOf=graphical.target

[Service]
Type=simple
ExecStart=/usr/local/bin/seamless-login uwsm start -- hyprland.desktop
Restart=always
RestartSec=2
User=$USER
TTYPath=/dev/tty1
TTYReset=yes
TTYVHangup=yes
TTYVTDisallocate=yes
StandardInput=tty
StandardOutput=journal
StandardError=journal+console
PAMName=login

[Install]
WantedBy=graphical.target
EOF
    
    if [ $? -eq 0 ]; then
        echo "Seamless login service created successfully"
    else
        log_error "Failed to create seamless login service"
    fi
fi

# Enable omarchy-seamless-login.service only if not already enabled
echo "Configuring seamless login service..."
if ! systemctl is-enabled omarchy-seamless-login.service 2>/dev/null | grep -q enabled; then
    safe_run "sudo systemctl enable omarchy-seamless-login.service" "Enabling seamless login service"
fi

# Disable getty@tty1.service only if not already disabled
if ! systemctl is-enabled getty@tty1.service 2>/dev/null | grep -q disabled; then
    safe_run "sudo systemctl disable getty@tty1.service" "Disabling getty@tty1 service"
fi

# Reload systemd daemon
safe_run "sudo systemctl daemon-reload" "Reloading systemd daemon"

echo ""
echo "===================================================================="
echo "Login configuration completed (without disk encryption dependencies)"
echo "===================================================================="
echo ""
echo "Changes made:"
echo "  ✓ Installed UWSM for session management"
echo "  ✓ Configured kernel parameters for quieter boot"
echo "  ✓ Set up seamless auto-login to Hyprland"
echo "  ✓ Disabled getty@tty1 service"
echo ""
echo "Omitted (disk encryption related):"
echo "  ✗ Plymouth boot splash screen installation"
echo "  ✗ Plymouth theme configuration"  
echo "  ✗ Plymouth-related kernel parameters"
echo "  ✗ Plymouth service modifications"
echo ""
echo "The system will auto-login to Hyprland on next boot."
echo "Note: Without disk encryption, this provides less security."
echo ""