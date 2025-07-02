# AliasMatrixBinder

A Windower addon for Final Fantasy XI that provides dynamic alias management for multiple gaming devices and configurations.

## Overview

AliasMatrixBinder allows you to create and manage multiple sets of aliases for different gaming devices (keyboards, mouses, etc.) and automatically switch between them based on various conditions like login or job changes.

## Features

- **Multi-Device Support**: Manage aliases for different gaming devices
- **Dynamic Configuration**: Switch between different alias sets using config keys
- **Automatic Loading**: Apply specific alias configurations on login or job change
- **History Tracking**: Keep track of previously used configurations
- **Template Replacements**: Use placeholders in your aliases that get replaced with dynamic values
- **Flexible Config Keys**: Combine multiple configurations using `+` syntax
- **Visual Display Boxes**: Real-time status display for active devices
- **Customizable Keyboard Shortcuts**: Configure hotkeys for quick access

## Installation

1. Extract the addon to your Windower addons folder: `Windower/addons/AliasMatrixBinder/`
2. Load the addon using: `//lua load AliasMatrixBinder`
3. Or add it to your auto-load profile

## Commands

The addon responds to both `//AliasMatrixBinder` and `//ambinder` commands:

### Basic Commands
- `//ambinder help` - Show help message
- `//ambinder list` - List available devices
- `//ambinder repl` - Show available template replacements

### Device Management
- `//ambinder use <device_code> [config_keys]` - Apply configuration to a device
- `//ambinder reset [device_code]` - Reset device to defaults (or all devices if no code specified)
- `//ambinder clean <device_code> [config_keys]` - Apply configuration with cleared history

### History and Status
- `//ambinder history <device_code>` - Show configuration history for a device
- `//ambinder current <device_code>` - Show current configuration for a device
- `//ambinder prev <device_code>` - Switch to previous configuration

### Automatic Triggers
- `//ambinder setonlogin <device_code> [config_keys]` - Set configuration to apply on login
- `//ambinder setonjobchange <device_code> [config_keys]` - Set configuration to apply on job change

### Settings
- `//ambinder setkeyshortcut <key_code_or_name>` - Set keyboard shortcut for show/hide toggle
  - Accepts numeric key codes (8-254)

## Keyboard Shortcuts

- **Default**: END key (207) - Hold to show device displays, release to hide
- **Customizable**: Use `setkeyshortcut` command to change

## Usage Examples

````bash
# Apply default configuration to device 'sdxl'
//ambinder use sdxl default

# Apply multiple configurations combined (example keys) and using placeholders
//ambinder use sdxl default+switches+buffers+cust_{player_name}

# Set automatic configuration for login
//ambinder setonlogin sdxl default+switches

# Set automatic configuration for job changes
//ambinder setonjobchange sdxl default

# View current aliases
//ambinder current sdxl

# Go back to previous configuration
//ambinder prev sdxl

# Display management
//ambinder show     # Show all device displays
//ambinder hide     # Hide all device displays
//ambinder toggle   # Toggle display visibility

# Keyboard shortcut configuration
//ambinder setkeyshortcut 207       # Use END key
````

## File Structure

````
AliasMatrixBinder/
├── AliasMatrixBinder.lua     # Main addon file
├── Commands.lua              # Command handlers
├── Helpers.lua               # Utility functions
├── DevicesMapping.lua        # Device definitions
├── data/
│   ├── settings.xml            # Settings and display configurations
│   └── custom_replacements.lua # Custom template replacements
└── devices/
    └── <device_code>/
        ├── default_aliases.lua  # Base aliases for the device
        ├── general.lua          # General aliases (auto-loaded)
        ├── <JOB>.lua            # Job-specific aliases (e.g., WAR.lua)
        ├── <JOB>_<SUBJOB>.lua   # Job combo aliases (e.g., WAR_NIN.lua)
        ├── <player_name>.lua    # Player-specific aliases
        ├── <player_name>_<JOB>.lua          # Player+job aliases
        └── <player_name>_<JOB>_<SUBJOB>.lua # Player+job combo aliases
````

## Configuration Structure

The addon uses a modular configuration system with automatic file loading:

### Display Box Settings

Each device can have its own display box with customizable:
- Position (x, y coordinates)
- Font (family, size, color)
- Background (alpha transparency)
- Text stroke (width, alpha)
- Padding and flags
- Enable/disable state

### Template Replacements

You can use placeholders in your configurations that get automatically replaced:
- `{player_name}` - Your character name
- `{main_job}` - Your current main job (e.g., WAR)
- `{sub_job}` - Your current sub job (e.g., NIN)
- `{full_job}` - Combined job format (e.g., WAR_NIN)
- Custom replacements can be defined in `data/custom_replacements.lua`

### Config Key Syntax

Config keys can be combined using the `+` operator. The `default` key is special - all other mentioned keys are examples:
- `default` - Base configuration key
- `switches` - Example: Additional switch mappings
- `spec_PLD` - Example: Job-specific configuration
- `pvp` - Example: PvP-specific settings
- `default+switches+spec_PLD` - Combined configuration

### File Loading Priority

The addon automatically loads aliases from multiple files in this order (if they exist):

1. **general.lua** - Always loaded for general aliases
2. **{JOB}.lua** - Current main job (e.g., WAR.lua)
3. **{JOB}_{SUBJOB}.lua** - Job combination (e.g., WAR_NIN.lua)
4. **{player_name}.lua** - Player-specific aliases
5. **{player_name}_{JOB}.lua** - Player + main job specific
6. **{player_name}_{JOB}_{SUBJOB}.lua** - Player + job combination

Each file can contain multiple config key sections that can override previous definitions.

## Example Configuration

### Setting up general.lua

Create a file at `devices/{device_code}/general.lua`:

````lua
return {
    ["default"] = {
        -- General commands for the SDXL device
        ["sdxl_1"] = _addon.shortname .. " clean sdxl default",
        ["sdxl_9"] = _addon.shortname .. " use sdxl default+switches+helpers",
        ["sdxl_17"] = _addon.shortname .. " use sdxl default+config+switches",
    },
    ["switches"] = {
        -- Switch to different Characters
        ["sdxl_2"] = "exof switch to MyChar1",
        ["sdxl_3"] = "exof switch to MyChar2",
        ["sdxl_4"] = "exof switch to MyChar3",
    },
    ["helpers"] = {
        ["sdxl_15"] = "exof send @brd exec macro_brd_set_haste",
        ["sdxl_16"] = "exof send @cor exec macro_cor_set_chaos_sam",
    },
    ["config"] = {
        ["sdxl_1"] = _addon.shortname .. " prev sdxl",
        ["sdxl_18"] = _addon.shortname .. " use sdxl default+switches+wincontrol",
    },
    ["wincontrol"] = {
        ["sdxl5"] = "exof wincontrol move 1500 150",
        ["sdxl6"] = "exof wincontrol move 0 150"
    }
}
````

### Custom Replacements

Create `data/custom_replacements.lua`:

````lua
return {
    ["{my_macro}"] = 'input /ma "Cure IV" <me>',
    ["{my_linkshell}"] = "MyLinkshell",
    ["{myJob}"] = windower.ffxi.get_player().main_job and windower.ffxi.get_player().main_job:upper() or ""
}
````

## Events

The addon automatically responds to:
- **Login**: Applies configured `use_on_login` settings
- **Job Change**: Applies configured `use_on_job_change` settings (with 6-second delay)
- **Addon Load**: Applies login settings if already logged in
- **Keyboard Events**: Shows/hides display boxes based on configured shortcut key

## Settings

Settings are automatically saved and include:
- Device-specific display box configurations (position, font, colors, etc.)
- `use_on_login`: Configurations to apply on login for each device
- `use_on_job_change`: Configurations to apply on job change for each device
- `keyboard_shortcut`: Custom keyboard shortcut key code (default: 207/END key)
- `box_disabled`: Per-device setting to enable/disable display boxes

## Dependencies

- Windower 4
- `config` library
- `files` library
- `texts` library
- `logger` library

## Changelog

### Version 1.0.1 (July 2, 2025)

#### Bug Fixes
- Fixed issue where loading the addon prior to being logged in resulted in settings not being applied to the displayed boxes
- Fixed command alias for keyboard shortcut setting - changed `setkeyboardshortcut` to `setkeyshortcut` for consistency with documentation

#### New Features
- Added reload functionality (`//ambinder reload` or `//ambinder r`) for quick addon reloading

#### Code Improvements
- Updated version number to 1.0.1
- Minor code cleanup and organization

## Recommended Companion Addon

For enhanced functionality, consider using **[execOnFocus](https://github.com/xenodeus/execOnFocus)** alongside AliasMatrixBinder:

**execOnFocus** (exof) is a Windower addon that only executes commands when the FFXI window has focus.

## Author

**Xenodeus** - Version 1.0.1

## License

BSD 3-Clause License - See file header for full license text.