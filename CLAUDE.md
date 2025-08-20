# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## About Omarchy

Omarchy is an Arch Linux distribution installer that transforms a fresh Arch installation into a fully-configured, beautiful, and modern web development system based on Hyprland. It provides an opinionated take on what Linux can be at its best.

## Installation and Setup

### Primary Installation
```bash
# Bootstrap installation from a fresh Arch system
bash <(curl -s https://omarchy.org/install)
```

### Development Installation
```bash
# Install the local development version
./install.sh

# Apply migrations after updates
omarchy-migrate

# Update system after changes
omarchy-update
```

## Architecture Overview

### Core Structure
- **`install.sh`**: Main installation orchestrator that calls component installers in sequence
- **`boot.sh`**: Bootstrap script that clones the repository and starts installation
- **`install/`**: Modular installation scripts organized by category:
  - `preflight/`: Pre-installation checks and setup (AUR, migrations, guards)
  - `config/`: System configuration (networking, timezones, login, GPU drivers)
  - `development/`: Development tools (terminal, languages, Docker, firewall)
  - `desktop/`: Desktop environment (Hyprland, themes, Bluetooth, fonts)
  - `apps/`: Application installation (web apps, extras, mime types)

### Configuration Management
- **`config/`**: User configuration files that get copied to `~/.config/`
- **`default/`**: Default configuration templates for various tools
- **`themes/`**: Complete theme packages with coordinated styling across all applications
- **`applications/`**: Desktop entry files and application configurations

### System Utilities
- **`bin/`**: Collection of Omarchy-specific command-line utilities:
  - `omarchy-*`: Core system management commands
  - Theme management (`omarchy-theme-*`)
  - System refresh commands (`omarchy-refresh-*`)
  - Package management (`omarchy-pkg-*`)
  - Hardware utilities (`omarchy-cmd-*`)

### Migration System
- **`migrations/`**: Timestamped migration scripts for system updates
- Each migration is a bash script that applies specific changes
- Migrations are tracked to prevent re-running

## Common Development Commands

### System Management
```bash
# Update Omarchy to latest version
omarchy-update

# Apply pending migrations
omarchy-migrate

# Refresh specific components
omarchy-refresh-hyprland
omarchy-refresh-waybar
omarchy-refresh-config
```

### Theme Management
```bash
# List available themes
omarchy-theme-list

# Set a theme
omarchy-theme-set <theme-name>

# Install new theme
omarchy-theme-install <theme-path>
```

### Package Management
```bash
# Install packages through Omarchy wrapper
omarchy-pkg-install <package-name>

# Remove packages
omarchy-pkg-remove <package-name>
```

## Key Configuration Files

### Hyprland (Wayland Compositor)
- `config/hypr/`: Hyprland configuration files
- `default/hypr/`: Default Hyprland configurations

### Terminal and Shell
- `default/bash/`: Bash configuration and customizations
- `config/alacritty/`: Terminal emulator configuration

### Desktop Applications
- `config/waybar/`: Status bar configuration
- `config/walker/`: Application launcher configuration
- `config/nvim/`: Neovim configuration

## Development Guidelines

### Adding New Features
1. Create installation scripts in appropriate `install/` subdirectory
2. Add configuration files to `config/` or `default/`
3. Create utility scripts in `bin/` if needed
4. Update themes if the feature affects appearance

### Adding Migrations
```bash
# Create a new migration
omarchy-dev-add-migration "Description of changes"
```

### Theme Development
- Each theme should provide coordinated styling for all supported applications
- Include background images in `backgrounds/` subdirectory
- Provide configurations for: alacritty, btop, hyprland, waybar, walker, etc.

## Package Dependencies

The system uses `yay` (AUR helper) for package management and installs packages through modular scripts. Key package categories:

- **Development**: cargo, clang, llvm, mise, github-cli, lazygit
- **Desktop**: hyprland, waybar, walker, alacritty, chromium
- **Media**: mpv, imv, evince, wl-screenrec/wf-recorder
- **System**: brightnessctl, playerctl, pamixer, fcitx5

## Environment Variables

- `OMARCHY_REPO`: Custom repository for installation (default: basecamp/omarchy)
- `OMARCHY_REF`: Custom branch/tag for installation
- `OMARCHY_BARE`: Minimal installation mode
- `OMARCHY_PATH`: Path to Omarchy installation (`~/.local/share/omarchy`)