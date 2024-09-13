# Website to MacOS Dock Shortcut Generator

Create MacOS "apps" that open websites in Safari, mimicking Chrome's "Install app" feature for older MacOS versions.

## Features
- Generates MacOS app structure
- Creates Safari-based executable
- Downloads and converts website icons
- Offers to move app to Applications and add to Dock

## Requirements
- MacOS
- Zsh shell
- curl
- Internet connection

## Usage
1. Download `generateApp.sh`
2. Make executable: `chmod +x generateApp.sh`
3. Run: `./generateApp.sh <URL> "<App Name>"`
4. Follow prompts to finalize installation
