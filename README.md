# MiniMate Client

SwiftUI desktop companion app for macOS.

## Requirements

- macOS 14+
- Xcode 15+ or Swift 5.9+

## Quick Start

```bash
# Build
swift build

# Run (opens GUI window)
swift run MiniMate1Client

# Test
swift test
```

## Features

- **Floating Companion Window** - Always-on-top animated character
- **Activity Tracking** - Monitors active app and window titles
- **Struggle Detection** - Identifies when you're stuck (error keywords, app switching)
- **Speech Bubbles** - Displays contextual hints from the API
- **Idle Detection** - Knows when you're typing vs idle
- **Scheduled Events** - Break reminders and custom events

## Project Structure

```
Sources/
├── Activity/           # App tracking, idle detection
├── Animation/          # Character states and sprites
├── Companion/          # Floating window and speech bubble
├── Events/             # Scheduled reminders
├── Models/             # Hint, Activity, ScheduledEvent
├── Networking/         # APIClient, HintService
├── Preferences/        # User settings storage
└── Utilities/          # Screen, window, system observers
```

## Configuration

The app connects to the API at `http://localhost:8000` by default. Make sure the API service is running.

## Permissions

The app requires:
- **Accessibility** - For tracking active window titles
- **Screen Recording** - For detecting Electron app windows (VS Code, Cursor)

Grant permissions in System Settings > Privacy & Security.

## Notes

- Uses `NSWindow` with `NSHostingView` for the floating companion (not SwiftUI WindowGroup)
- Electron apps don't expose window titles via Accessibility API - uses `CGWindowListCopyWindowInfo` instead
- The companion respects your flow state and only shows hints when appropriate
