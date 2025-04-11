# SnoozeFuse Code Structure Documentation

## Architecture Overview

SnoozeFuse uses a modular architecture divided into:

1. **Models** - Data structures and enums
2. **Managers** - Controllers that handle specific functionality
3. **UI Components** - SwiftUI views and screens

## Directory Structure

```
SnoozeFuse/
├── Models/           # Data models and enums
│   ├── CustomSound.swift       # Custom sound data model
│   ├── AlarmSound.swift        # Built-in alarm sounds enum
│   └── TimerType.swift         # Timer types and notifications
│
├── Managers/         # Core functionality controllers
│   ├── AudioPlayerManager.swift     # Audio playback
│   ├── CustomSoundManager.swift     # Custom sound handling
│   ├── SettingsManager.swift        # App settings and persistence
│   └── TimerController.swift        # Timer logic and control
│
├── TimerManager.swift    # Main facade that coordinates all managers
└── [UI and other files]
```

## Core Classes

### TimerManager

The main facade class that provides a unified API for the rest of the app. It:
- Forwards properties from specialized managers
- Maintains backward compatibility with existing code
- Coordinates between managers

### Models

- **CustomSound**: Represents a user-added sound file
- **AlarmSound**: Enum of available alarm sounds
- **TimerType**: Enum for different timer types (hold, nap, max)

### Managers

- **AudioPlayerManager**: Handles all audio playback, audio sessions, and speaker routing
- **CustomSoundManager**: Manages importing, storing, and retrieving custom sounds
- **SettingsManager**: Handles app settings and persistence
- **TimerController**: Controls timer logic, starting/stopping timers

## Workflow

1. UI components interact with `TimerManager`
2. `TimerManager` delegates to appropriate specialized managers
3. Specialized managers handle their specific responsibilities
4. State changes propagate back through `TimerManager` to the UI

## Extending the App

When adding new features:

1. Determine which manager should own the functionality
2. Implement the core logic in that manager
3. Expose the functionality through `TimerManager` if needed by UI components

## Notes on Refactoring

The original `TimerManager.swift` was refactored to improve:
1. **Maintainability**: Smaller, focused files are easier to understand
2. **Testability**: Decoupled managers can be tested independently
3. **Scalability**: New features can be added to the appropriate manager
4. **Readability**: Clean separation of concerns makes code more readable 

## Notification Permission Handling

SnoozeFuse uses a just-in-time approach for requesting notification permissions:

1. Notification permissions are not requested at app launch
2. Instead, permissions are requested only when the user starts a sleep timer
3. The app checks if permission is already granted before showing the prompt
4. This approach improves user experience by showing the permission dialog in context

Implementation details:
- The AppDelegate has a `requestNotificationsPermissionWhenNeeded()` method
- SleepScreen calls this method when a sleep timer is started
- This ensures notifications are only requested when they're actually needed 