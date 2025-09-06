# macOS Updater - GUI Application

This is a macOS SwiftUI application that provides a graphical interface for the macOS All-In-One Update Script. It allows users to selectively run updates for various package managers and tools through an intuitive checkbox interface.

## Features

### 🎯 **Selective Updates**
- ✅ **Homebrew** - Update formulas, casks, and run diagnostics
- ✅ **VSCode Extensions** - Update all installed VS Code extensions
- ✅ **npm Packages** - Update global npm packages
- ✅ **Yarn Packages** - Update yarn packages to latest versions
- ✅ **RubyGems** - Update user-installed gems
- ✅ **Cargo Crates** - Reinstall all Rust cargo crates
- ✅ **App Store Apps** - Update Mac App Store applications (via `mas`)
- ✅ **macOS System** - Install system updates and patches

### 🖥️ **Modern GUI**
- **Split-pane interface** with controls on the left and live output on the right
- **Real-time output streaming** - see command output as it happens
- **Command availability checking** - only enable updates for installed tools
- **Internet connectivity validation** - verify connection before starting updates
- **Progress indicators** - visual feedback during update operations

### 🔒 **Security & Permissions**
- **No sandboxing** - necessary for system-level operations
- **Network access** - for downloading updates and checking connectivity
- **Full disk access** - required for package manager operations

## Requirements

- **macOS 13.0+** (Ventura or later)
- **Xcode 15.0+** for building
- **Various package managers** (optional, will be detected automatically):
  - Homebrew (`brew`)
  - Visual Studio Code (`code`)
  - Node.js and npm (`npm`)
  - Yarn (`yarn`)
  - Ruby and RubyGems (`gem` - non-system version)
  - Rust and Cargo (`cargo`)
  - Mac App Store CLI (`mas`)

## Building the Project

1. **Open in Xcode:**
   ```bash
   open MacOSUpdater.xcodeproj
   ```

2. **Build and Run:**
   - Select your target device (Mac)
   - Press `Cmd+R` to build and run
   - Or use `Product > Run` from the menu

3. **Build for Distribution:**
   - Use `Product > Archive` to create a distributable build
   - Export as a macOS App for distribution outside the App Store

## Project Structure

```
MacOSUpdater/
├── MacOSUpdaterApp.swift      # Main app entry point
├── ContentView.swift          # Main UI with split pane layout
├── UpdateManager.swift        # Core logic and update orchestration
├── ShellExecutor.swift        # Shell command execution utilities
├── Assets.xcassets/           # App icons and colors
├── MacOSUpdater.entitlements  # App permissions and entitlements
└── Preview Content/           # SwiftUI preview assets
```

## Key Components

### UpdateManager
- **Observable object** that manages the app state
- **Command availability detection** for each update type
- **Internet connectivity checking**
- **Update orchestration** with real-time output streaming
- **Error handling and logging**

### ShellExecutor
- **Async shell command execution** with proper error handling
- **Real-time output streaming** for live feedback
- **Command availability checking**
- **Internet connectivity validation**

### ContentView
- **Split-pane interface** with checkboxes and output display
- **Responsive design** with proper spacing and layout
- **Real-time output scrolling** with auto-scroll to bottom
- **Progress indicators** and status feedback

## Usage

1. **Launch the application**
2. **Select desired updates** using the checkboxes
3. **Verify internet connection** (button available if needed)
4. **Click "Run Updates"** to start the process
5. **Monitor progress** in the output panel
6. **Wait for completion** - all selected updates will run sequentially

## Development Notes

### Permissions
The app requires **full system access** and **network permissions** to function properly. The entitlements file disables sandboxing to allow:
- Executing system commands
- Accessing package manager directories
- Network operations for updates

### Error Handling
- **Command not found** - Updates are automatically disabled if tools aren't installed
- **Network issues** - Internet connectivity is checked before starting
- **Command failures** - Errors are displayed in red in the output panel
- **Partial failures** - Updates continue even if individual commands fail

### Customization
You can modify the update commands by editing the `UpdateType` enum in `UpdateManager.swift`. Each update type defines:
- Display name and description
- Associated commands to execute
- Icon and color for the UI
- Special handling requirements

## Original Script Integration

This GUI application is based on the original shell script (`update-all.sh`) and maintains the same update logic while providing a modern, user-friendly interface. The core functionality has been translated to Swift while preserving all the error checking and command sequences from the original script.

## Troubleshooting

### Common Issues

1. **"Command not found" errors**
   - Ensure the required package managers are installed
   - Check that commands are in your PATH

2. **Permission denied**
   - The app may need additional permissions
   - Try running from Terminal with elevated privileges for testing

3. **Network connectivity issues**
   - Use the "Check Internet" button to verify connectivity
   - Ensure firewall settings allow the app to access the network

4. **Build errors in Xcode**
   - Ensure you're using Xcode 15.0 or later
   - Check that macOS deployment target is set to 13.0+

### Debug Mode

For development and debugging, you can:
- Use Xcode's debugging tools and breakpoints
- Monitor console output for detailed error messages
- Test individual update functions in isolation
