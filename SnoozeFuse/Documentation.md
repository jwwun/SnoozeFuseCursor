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

## System-Level Error Prevention

SnoozeFuse includes several mitigation strategies for common iOS system-level warnings and errors:

1. **Orientation API Warning**: 
   - Modern approach using `UIWindowScene.requestGeometryUpdate(.iOS(interfaceOrientations:))` for iOS 16+
   - Fallback to legacy method for older iOS versions
   - Implementation in `OrientationManager.swift` and `SnoozeFuseApp.swift`

2. **Audio Output Errors**: 
   - Optimized volume control in `AudioVolumeManager.swift`
   - Conditional system volume updates only when significant changes are needed (>10% difference)
   - Direct slider access without notification triggering to avoid errors
   - Avoids using private APIs that can throw errors

3. **Metal Rendering Errors**:
   - Created `ConditionalMetalRenderer` modifier to safely handle Metal rendering
   - Provides graceful fallbacks for devices with Metal library issues
   - Version-specific implementations for different iOS versions
   - Implemented with the convenient `.safeMetalRendering()` extension

4. **Background Thread Publishing**:
   - Ensuring all ObservableObject updates happen on the main thread
   - Fixed `DispatchQueue.global().async` calls in UI components
   - Using `DispatchQueue.main.async` for any state updates
   - Prevents "Publishing changes from background threads is not allowed" warnings

These approaches help prevent common system-level warnings while maintaining functionality:
- `BUG IN CLIENT OF UIKIT: Setting UIDevice.orientation isn't supported`
- `Failed to set audio output: NSOSStatusErrorDomain Code=-50 (null)`
- `Unable to open mach-O at path...RenderBox.framework/default.metallib Error:2`
- `Publishing changes from background threads is not allowed`

## Audio Settings Organization

SnoozeFuse's audio settings are organized in a single unified cubby with the following components:

1. **Alarm Volume**:
   - Displayed in the main settings screen by default
   - Controls the system volume when the alarm plays
   - Implementation in `AudioVolumeManager.swift` and `AudioVolumeUI.swift`

2. **Alarm Sound**:
   - Integrated into the audio settings cubby with the other audio controls
   - Has its own hide/show button for toggling visibility
   - No separate background when inside the audio settings cubby, avoiding nested boxes
   - When moved to advanced settings, it appears in the same audio settings cubby
   - Allows selection from built-in and custom sounds
   - Implementation in `Components/SoundSelectionComponents.swift` and `Managers/AlarmSoundManager.swift`

3. **Audio Output**:
   - Hidden from main settings by default (appears in advanced settings)
   - Controls whether alarm plays through device speaker or connected audio devices
   - Implementation in `AudioOutputManager.swift` and `AudioOutputUI.swift`

This organization keeps all audio-related settings in a single cubby while still allowing users to customize which settings appear where based on their preferences. Each component can be independently moved between main and advanced settings.

## About Screen Tutorial

The About screen serves as both an introduction to SnoozeFuse and a tutorial on how to use the app. It consists of five pages:

1. **Welcome Page**:
   - Introduces the app's purpose: to help users take refreshing naps without feeling groggy
   - Contains the app logo and a brief welcome message

2. **Tap & Hold Mechanism**:
   - Explains the core interaction method: tap and hold the circle to start
   - Describes how the nap countdown begins after releasing your finger
   - Emphasizes the natural transition to sleep

3. **Smart Timer System**:
   - Provides accurate explanation of the app's unique timer system:
     - RELEASE TIMER: Counts down when you release your finger, starting your nap when it reaches zero
     - NAP TIMER: Controls how long your nap lasts before the alarm sounds
     - MAX TIMER: A failsafe that limits your total session time in case you fall into deep sleep
   - Helps users understand the purpose of each timer for effective napping

4. **Comfortable Positioning**:
   - Provides guidance on different ways to hold or position the phone while napping
   - Includes suggestions for using on beds and other soft surfaces
   - Offers tip about holding sideways to prevent accidentally exiting the app
   - Emphasizes finding a relaxed position for optimal sleep transition

5. **Support Page**:
   - Information about supporting the app's development
   - Contains a donation link for users who wish to contribute

The About screen is designed to be accessible at any time, providing both new users and returning users with a clear explanation of the app's functionality.

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