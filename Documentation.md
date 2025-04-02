# SnoozeFuse Documentation

## Project Overview
SnoozeFuse is an iOS app built with SwiftUI that provides timer functionality with multiple customizable timers, haptic feedback, and sound alarms.

## App Architecture

### Core Components

#### `SnoozeFuseApp.swift`
- Main app entry point
- Manages app orientation settings
- Initializes and provides key managers as environment objects

#### `TimerManager.swift`
- Manages all timer functionality (hold, nap, max timers)
- Handles alarm sounds and custom sounds
- Persists settings using UserDefaults

#### `HapticManager.swift`
- Provides haptic feedback functionality
- Singleton pattern for global access
- Persists haptic settings preferences

#### `OrientationManager.swift`
- Controls device orientation settings
- Handles orientation locks

#### `MultiTouchHandler.swift`
- Provides multi-touch detection within circular areas
- Bridges UIKit touch handling to SwiftUI
- Enables complex touch interactions for timer controls

#### Screens
- `SettingsScreen.swift` - Main settings interface
- `NapScreen.swift` - Interface for nap timer
- `SleepScreen.swift` - Interface for sleep timer
- `AdvancedSettingsScreen.swift` - Additional settings

### UI Components
- `CircleView.swift` - Custom circular view for timers with customizable appearance and states

## Refactoring Improvements

### 1. TimerManager Refactoring
- **Added TimerType Enum**: Created a `TimerType` enum to reduce code duplication for timer operations
- **Centralized Timer Operations**: Implemented generic `startTimer` and `stopTimer` methods
- **UserDefaults Constants**: Added a `UserDefaultsKeys` enum to centralize string constants
- **Improved Code Organization**: Moved enums to appropriate scope level
- **Enhanced Method Documentation**: Added comments to clarify functionality
- **Moved AlarmSound Enum**: Relocated the `AlarmSound` enum from nested inside `TimerManager` to a top-level type, and updated references throughout the codebase

### 2. HapticManager Refactoring
- **Added Settings Persistence**: Implemented `saveSettings` and `loadSettings` methods
- **Added MARK Comments**: Improved code organization with MARK comments
- **Added Documentation Comments**: Enhanced method documentation
- **Automatic Settings Saving**: Added onChange handlers to automatically save settings
- **UserDefaults Constants**: Added a `UserDefaultsKeys` enum to centralize string constants

### 3. CircleView Refactoring
- **Enhanced Customization**: Added properties for colors and text customization
- **Improved Structure**: Separated UI elements into private computed properties
- **Added Documentation**: Added comprehensive documentation comments
- **Extended Preview**: Created richer preview examples for design time
- **Added MARK Comments**: Improved code organization with MARK comments

### 4. MultiTouchHandler Refactoring
- **Improved Architecture**: Reorganized component relationships and responsibilities
- **Enhanced Documentation**: Added detailed comments explaining functionality
- **Extracted Helper Methods**: Created reusable `isTouchInsideCircle` method
- **Added MARK Comments**: Improved code organization with section markers
- **Simplified Conditionals**: Improved guard clauses and return early patterns
- **Clarified Class Hierarchy**: Reordered class declarations for better readability

## Key Design Patterns

### Singleton Pattern
Used for managers that need global access:
- `HapticManager.shared`
- `OrientationManager.shared`

### Observer Pattern (via SwiftUI)
- `@Published` properties for reactive updates
- `@EnvironmentObject` for dependency injection
- Combine framework for timer event processing

### Dependency Injection
- Environment objects passed down the view hierarchy

### View Composition
- Breaking down complex views into smaller, reusable components 
- Using computed properties to organize view code

### Bridge Pattern
- `MultiTouchHandler` bridges between UIKit touch handling and SwiftUI views

## Future Improvements

### Potential Refactoring Opportunities
- Consider extracting UI components from `SettingsScreen.swift` into separate files
- Implement a more robust error handling system
- Add unit tests for core functionality
- Consider using a dedicated persistence layer instead of direct UserDefaults access
- Implement a logging system for debugging and analytics

### Performance Considerations
- Profile app for potential memory leaks, especially with timers
- Optimize sound loading and playback
- Ensure proper cancellation of publishers

## Bug Fixes

### Fixed Type Reference Issue
- Fixed error `'AlarmSound' is not a member type of class 'SnoozeFuze.TimerManager'` by updating all references in SettingsScreen.swift to use the top-level `AlarmSound` type instead of `TimerManager.AlarmSound`.

## Build and Run Instructions

1. Open the project in Xcode
2. Ensure you have iOS 18.0+ as deployment target
3. Build and run on simulator or physical device 

## Notification System

### Implementation Details
- Uses `UNUserNotificationCenter` API for permission management and scheduling
- Notification permission state is checked on app launch
- Notifications are scheduled with critical sound (`UNNotificationSound.defaultCritical`)
- Notification UI components adapt based on current permission state
- Advanced notification settings available in the Advanced Settings screen
- Notification warning UI can be moved between main Settings and Advanced Settings screens
- User preference for notification warning location is persisted across app launches

### User Interaction Flow
1. By default, if notifications are not enabled, a warning appears in the main Settings screen
2. User can tap "Hide This" to move the warning to the Advanced Settings screen
3. In Advanced Settings, user can tap "Show in Main Settings" to move it back
4. Setting is persisted in UserDefaults so it remembers user preference across app launches
5. When notifications are enabled, the warning UI disappears from both screens automatically

## UI Improvements

### Status Bar Management
- **Status Bar**: Always visible on all screens to maintain system context

### Home Indicator
- **Home Indicator**: Removed attempts to hide the Home Indicator since iOS restricts fully hiding it
- **Edge-to-edge Layout**: Maintained edge-to-edge content layout using `.edgesIgnoringSafeArea(.all)` for immersive experience

### Multi-Swipe Exit Protection
- **MultiSwipeConfirmation Component**: Requires multiple consecutive swipes to exit NapScreen or SleepScreen
- **Configurable Settings**: Swipe count, direction, and labels can be customized
- **Visual Feedback**: Color changes provide visual indication of progression
- **Haptic Feedback**: Triggers haptic feedback on each successful swipe
- **Timeout Protection**: Swipe count resets after 3 seconds of inactivity
- **Improved Safety**: Prevents accidental exits from sleep screens
- **Conditional Swipe Requirement**: Only requires two swipes when timer is active; single swipe when timer is inactive
- **Redesigned SleepScreen Buttons**: Added separate buttons for returning to NapScreen (left) and SettingsScreen (right)
- **Tap-Only Mode**: When timer ends, both buttons change to tap-only versions instead of requiring swipes
- **Consistent Design**: Swipe buttons and tap buttons maintain consistent visual design

### SleepScreen UI Enhancements
- **Clear Navigation Path**: 'Back to Nap' button on left, 'Back to Settings' button on right
- **Proper Destination Paths**: Back to Nap button returns to NapScreen while keeping settings, Back to Settings button returns to SettingsScreen and resets timers
- **Visual Aesthetics**: Enhanced button design with gradients, shadows, and visual depth
- **Proper Spacing**: Improved layout and spacing for buttons and UI elements
- **Clearer Labels**: Updated button labels to clearly indicate their function ('Back to Nap' and 'Back to Settings')
- **Color Differentiation**: Used different colors to distinguish button functions (purple for Nap, indigo for Settings)
- **Consistent Visuals**: Swipe buttons use same visual design as tap buttons for consistent UX

### Implementation Details
- Implemented `MultiSwipeConfirmation` component to replace confirmation buttons
- Updated NapScreen and SleepScreen to require multiple swipes before exit
- Maintained edge-to-edge layout while keeping status bar visible
- Updated `MultiSwipeConfirmation` to conditionally require swipes based on timer status
- Redesigned SleepScreen buttons to provide clear navigation options
- Fixed button logic to properly navigate to intended destinations
- Enhanced button design with layered gradients, shadows, and visual polish
- Unified design language between swipe controls and tap buttons
- Properly positioned buttons with Back to Nap on left and Back to Settings on right