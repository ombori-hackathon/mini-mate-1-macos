# MiniMate1Client - SwiftUI App

macOS desktop app that communicates with the FastAPI backend.

## Commands
- Build: `swift build`
- Run: `swift run MiniMate1Client` (opens GUI window)
- Test: `swift test`

## Architecture
- SwiftUI app with native macOS window
- Entry point: Sources/MiniMate1App.swift
- Main view: Sources/ContentView.swift
- Data models: Sources/Models.swift
- Uses async/await with URLSession
- Targets macOS 14+

## API Integration
- Backend runs at http://localhost:8000
- Health check: GET /health
- Sample data: GET /items (returns list of items)

## Adding Features
1. Create new SwiftUI views in Sources/
2. Add new async functions for API calls in views or a dedicated APIClient
3. Use `URLSession.shared.data(from:)` for GET requests
4. Use `URLSession.shared.data(for:)` for POST/PUT with URLRequest

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

## Learnings & Gotchas

### Floating Window (NSWindow)
- Use `NSWindow` with `NSHostingView` for always-on-top floating windows
- SwiftUI `WindowGroup` doesn't support `level = .floating`
- Set `styleMask` to `.borderless` for clean look
- Use `isMovableByWindowBackground = true` for dragging

### Accessibility API
- Requires non-sandboxed app (disable in entitlements)
- Check permission with `AXIsProcessTrusted()`
- Use `AXUIElementCreateApplication(pid)` to get app element
- Window titles via `kAXFocusedWindowAttribute` then `kAXTitleAttribute`

### Electron Apps (Cursor, VS Code)
- **Don't expose window titles via Accessibility API!**
- Use `CGWindowListCopyWindowInfo` instead:
```swift
if let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] {
    // Find window by PID and get kCGWindowName
}
```

### Idle Time Detection
- Use `CGEventSource.secondsSinceLastEventType(.hidSystemState, eventType:)`
- Typing detection: idle resets frequently when user types
- Compare current vs previous idle time to detect input

### @Observable vs @ObservableObject
- Use `@Observable` (iOS 17+/macOS 14+) for simpler state
- No need for `@Published` - all properties auto-observed
- Use `@MainActor` for UI-bound state classes

### Multi-Monitor
- Track active screen with `NSScreen.main`
- Constrain window to `visibleFrame` to avoid menu bar/dock
