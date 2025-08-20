# Omarchy

Turn a fresh Arch installation into a fully-configured, beautiful, and modern web development system based on Hyprland by running a single command. That's the one-line pitch for Omarchy (like it was for Omakub). No need to write bespoke configs for every essential tool just to get started or to be up on all the latest command-line tools. Omarchy is an opinionated take on what Linux can be at its best.

Read more at [omarchy.org](https://omarchy.org).

## Installation Options

### Standard Installation (with disk encryption)
```bash
bash <(curl -s https://omarchy.org/install)
```

### Installation without disk encryption
For users who prefer not to use disk encryption, use the alternative login script:
```bash
# After cloning the repository
./install.sh
# Then manually run the no-encryption login script
bash install/config/login-no-encryption.sh
```

The `login-no-encryption.sh` script provides:
- Seamless auto-login without Plymouth boot splash dependencies
- Robust error handling that continues execution on failures
- Clean boot experience with quiet kernel parameters
- No disk encryption or LUKS requirements

## Development

### Claude Code Integration
This repository includes `CLAUDE.md` with comprehensive documentation for Claude Code instances, including:
- Architecture overview and component structure
- Common development commands and workflows
- Theme management and system utilities
- Migration system for updates

### Key Commands
```bash
# Update system
omarchy-update

# Apply migrations
omarchy-migrate

# Theme management
omarchy-theme-list
omarchy-theme-set <theme-name>

# Component refresh
omarchy-refresh-hyprland
omarchy-refresh-waybar
```

## License

Omarchy is released under the [MIT License](https://opensource.org/licenses/MIT).

