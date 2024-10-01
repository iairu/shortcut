<div align="center">

# Shortcut: Web App Creator for macOS

Create macOS "apps" that open websites in a Safari-like environment, mimicking Chrome's "Install app" feature for older macOS versions.

Made by iairu.com (Ondrej Špánik) in 2024.

</div>

## Features
- Generates MacOS app structure
- Creates a custom WebKit-based executable that:
  - Opens a specified URL in a native macOS window
  - Provides a Safari-like user experience
  - Includes zoom functionality, about me and feedback sending menu options
  - Handles navigation to maintain the app's context
  - Supports common authentication domains
- Downloads and converts website icons
- Offers to move app to Applications and add to Dock

## Requirements
- Website of your choosing
- Operating system: May work on macOS 10.15 (Catalina) or later and guaranteed working on macOS 13 (Ventura) or later
    - Zsh shell (pre-installed on macOS)
    - curl (pre-installed on macOS)
    - Swift (you may need Xcode for this)
- Internet connection

## Usage
1. Download `generateAppSwift.sh`
2. Make executable: `chmod +x generateAppSwift.sh`
3. Run: `./generateAppSwift.sh <URL> "<App Name>"`
4. Follow prompts to finalize installation
