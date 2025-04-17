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

### Custom CAF Sound Notifications Feature
- **Custom Notification Sounds**: Users can import and use custom .caf format sound files for notifications outside the app
- **iOS Format Requirement**: Clear warnings and guidance explaining that iOS requires .caf format for notification sounds
- **File Import**: UI for importing custom .caf files from the Files app
- **Sound Management**: 
  - List view for managing imported CAF sounds
  - Swipe-to-delete functionality for removing sounds
  - Selection indication for currently active sound
- **Sound Preview**: Test button to preview selected CAF sound before using it in notifications
- **Default Sound Option**: Option to use the default system notification sound
- **Dedicated Test UI**: 
  - Separate test component for sending immediate test notifications with selected sound
  - Can test sounds with the app in foreground or background
  - Clear feedback on whether the test was successful
- **Format Validation**: Checks and alerts if attempting to import non-CAF files
- **Helpful Documentation**: Built-in information about CAF files and conversion options
- **Integration with Existing Notifications**: 
  - Seamless integration with existing alarm notifications
  - Custom sounds are used for both scheduled and immediate notifications
- **Location**: Located in Advanced Settings under the Notifications section
- **Persistence**: All custom sounds and selection preferences are saved and persist between app launches
- **Built-in CAF Sounds**:
  - Includes built-in .caf sound options (beep.caf and vtuber.caf)
  - Built-in sounds are protected from deletion
  - Proper file handling for notification system compatibility

## Developer Notes

### Adding CAF Files to the Project
To add .caf files to the Xcode project:

1. **Create a group for sound resources** (if not already present)
2. **Drag the .caf files** into this group in the Xcode navigator
3. In the dialog that appears:
   - Ensure "Copy items if needed" is checked
   - Select the appropriate target
   - Choose "Create groups" for the added folders
   - Click "Finish"
4. Verify the files are included in the "Copy Bundle Resources" build phase

### Implementation Details

#### iOS Notification Sound Requirements
- iOS only supports .caf (Core Audio Format) files for custom notification sounds
- The sounds must be accessible from a specific location within the app's bundle
- For custom imported sounds, they must be copied to the Library/Sounds directory
- Sound file references in notifications must use UNNotificationSoundName

#### Playing CAF Files in Notifications
1. The app stores CAF files in both:
   - The Documents directory (for app use and persistence)
   - The Library/Sounds directory (for iOS notification system use)
2. When scheduling a notification, the sound is referenced by name:
   ```swift
   if let cafSoundName = CustomCAFManager.shared.getSelectedCAFSoundName() {
       content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: cafSoundName))
   }
   ```
3. iOS notification system finds the sound file in Library/Sounds and plays it when the notification is triggered 

## Recent Updates

### Sound System Improvements

**Changes to AlarmSound.swift:**
- Updated the `filename` method to return the actual base filename of the sound file instead of the display name
- Modified the `fileExtension` method to correctly identify .caf files for vtuber and beep sounds

**Changes to CustomCAFManager.swift:**
- Implemented mapping from internal filenames to user-friendly display names
- Fixed sound file handling to properly utilize the mapped names for built-in sounds
- Improved file copying logic for notification sounds
- Enhanced the lookup of built-in sounds to use the new mapping dictionary

### Haptic and Timer Display Fixes

**Haptic Manager Improvements:**
- Reorganized the `HapticManager` class for better code clarity and readability
- Added proper private/public access control for properties
- Improved code organization with MARK comments
- Created a dedicated method to play heartbeat sequences
- Simplified timer management and cleanup

**Heartbeat Haptic Feedback Fix:**
- Fixed issue where heartbeat haptic feedback would automatically start when opening the NapScreen
- Modified the haptic feedback to only trigger after the first user interaction with the circle
- Removed automatic haptic feedback from the NapScreen's onAppear method
- Improved the toggle behavior in settings to prevent auto-starting the pulse test when enabling

**Timer Display Format Consistency:**
- Fixed issue where max timer would flicker between different time units (minutes/seconds)
- Added consistent unit formatting to prevent the display from switching between formats
- Implemented smart unit selection based on the original timer duration
- Used floor() to round down to the nearest second to prevent display jitter
- This ensures that 1 min 5 sec doesn't change to 1 sec 5 sec as the timer counts down

**NapScreen Timer Initialization Fix:**
- Fixed issue where timer values were locked at 5 seconds (release) and 2 minutes (max) in NapScreen
- Replaced manual timer value assignments with proper call to timerManager.resetTimers()
- Removed redundant code that was overriding the timer values from settings
- Timers now consistently use the values set in the SettingsScreen instead of being reset to defaults

**Heartbeat Animation Desynchronization Fix:**
- Fixed issue where rapidly pressing the heartbeat animation button caused multiple overlapping animations
- Implemented proper cancellation of in-progress animations before starting new ones:
  - Added tracking system for animation work items in CircleView
  - Added method to cancel all pending animation tasks
  - Implemented timestamp-based debouncing to prevent rapid re-triggering
- Applied similar fixes to the haptic feedback in HapticManager:
  - Added work item tracking for haptic sequences
  - Implemented debounce protection for the startBPMPulse method
  - Ensured clean cancellation of all pending haptic events
- Result is much smoother heartbeat animations without visual glitches or desynchronization

These improvements enhance the user experience by making haptic feedback behavior more intuitive and timer displays more consistent and readable. 