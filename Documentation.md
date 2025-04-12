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
- `SettingsScreen.swift` - Main settings interface. Contains several nested SwiftUI Views for different setting groups:
    - `PixelateEffect`: ViewModifier for logo animation.
    - `HelpButton`: Reusable button for showing help tooltips.
    - `CircleSizeControl`: UI for adjusting the circle size via slider and text input.
    - `TimeUnit`: Enum for time units (seconds, minutes).
    - `CuteTimePicker`: Reusable wheel picker for time values with unit selection.
    - `TimerSettingsControl`: UI for setting Release, Nap, and Max timers.
    - `AlarmSoundSelector`: UI for selecting built-in or custom alarm sounds, including preview and import functionality.
    - `DocumentPicker`: `UIViewControllerRepresentable` for picking custom sound files.
    - `CirclePreviewOverlay`: An overlay view to preview the circle size.
    - Contains a `Color(hex:)` extension, which could potentially be moved to a dedicated utilities file.
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
- **Removed Unused Code**: Deleted unused `Data` conversion extensions for `UInt32` and `UInt16`.
- **Simplified Sound Playback**: Refactored `playAlarmSound` by extracting sound URL retrieval logic into a dedicated helper function (`getAlarmSoundURL`), improving clarity and separation of concerns.

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
- **Encapsulated Animation State**: Grouped related `@State` variables for particle animations (sparks, burnt effects) into private helper structs (`SparkState`, `BurntEmitParticleState`, etc.) to improve code organization and readability within `CircleView`.

### 4. MultiTouchHandler Refactoring
- **Improved Architecture**: Reorganized component relationships and responsibilities
- **Enhanced Documentation**: Added detailed comments explaining functionality
- **Extracted Helper Methods**: Created reusable `isTouchInsideCircle` method
- **Added MARK Comments**: Improved code organization with section markers
- **Simplified Conditionals**: Improved guard clauses and return early patterns
- **Clarified Class Hierarchy**: Reordered class declarations for better readability

### 5. SettingsScreen Refactoring
- **Optimized Circle Size Control**: Refactored `CircleSizeControl`'s `onChange` handlers to eliminate redundant calls to `onValueChanged()` and `timerManager.saveSettings()`, ensuring settings are saved only once per effective change.
- **Reduced Timer Settings Redundancy**: Extracted repeated time unit conversion logic in `TimerSettingsControl` into private helper functions (`decompose` and `compose`) for better code reuse and readability.
- **Streamlined Sound Deletion**: Removed the redundant secondary 'Remove Custom Sounds' menu from `AlarmSoundSelector`, relying solely on the more intuitive swipe-to-delete action for managing custom sounds.

### 6. SleepScreen Refactoring
- **Button Logic Consolidation**: Refactored the bottom button row (`Back to Nap`/`Swipe to Nap` and `Back to Settings`/`Swipe to skip`) by extracting the conditional logic (based on `napFinished` state) into private computed properties (`leftButton`, `rightButton`).
- **Reduced Button UI Repetition**: Created a private helper view (`buttonContent`) to define the common visual structure for the bottom buttons, reducing code duplication.

### 7. Notification Handling Fixes
- **Prevented Foreground Alert/Sound**: Modified the `UNUserNotificationCenterDelegate`'s `userNotificationCenter(_:willPresent:withCompletionHandler:)` method in `AppDelegate` to pass `[]` to the completion handler for alarm notifications. This prevents the system banner and sound from appearing when the app is already in the foreground.
- **Eliminated Double Alarm Sound**: Removed the redundant call to `TimerManager.shared.playAlarmSound()` from the foreground notification delegate, ensuring the alarm sound is only triggered once by the `SleepScreen`'s internal logic.

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

## UI Improvements

### Timer Display Format
- **Adaptive Time Format**: Updated all timer displays to use a human-readable format that changes based on duration:
  - For durations > 1 hour: "[hours]hr [minutes]min [seconds]sec"
  - For durations < 1 hour: "[minutes]min [seconds]sec"
  - For durations < 1 minute: "[seconds]sec"
- **Simplified Time Display**: Removed milliseconds from all timer displays for cleaner interface
- **Consistent Formatting**: Applied the same formatting across the app for visual consistency
- **User-friendly Units**: Used abbreviated time units (hr, min, sec) instead of colons for better readability
- **Enhanced Visual Hierarchy**:
  - Numbers are displayed in a larger, bold font
  - Units are displayed in a smaller font with reduced opacity
  - Creates clear visual distinction between numerical values and their units
  - Applied consistent formatting across all timer displays in the app
- **Optimized Proportions**: Carefully calibrated font size relationships (approximately 2:1 ratio between numbers and units)
- **Improved Legibility**: Base alignment adjustments ensure proper vertical alignment between numbers and units
- **Compact Design**: Eliminated excess spacing between numbers and units for a more cohesive look
- **Fixed Format Flickering**: Implemented threshold-based formatting to prevent flickering between display formats:
  - Uses hours format for any duration ≥ 60 minutes (3600 seconds)
  - Uses minutes format for any duration ≥ 60 seconds but < 3600 seconds
  - Uses seconds format for any duration < 60 seconds
  - Ensures consistent unit format for stable UI even during timer transitions

### Timer Presets Feature
- **Customizable Presets**: Users can save multiple timer configurations as presets for quick reuse
- **Intuitive Interface**: Horizontal scrollable list of preset cards in a compact format
- **Quick Access**: Tap any preset to instantly apply its timer settings
- **Flexible Management**:
  - Create new presets by saving current timer settings
  - Rename presets through context menu (long press)
  - Delete presets with a single tap (no confirmation required for quick workflow)
- **Visual Feedback**: 
  - Clear visual indication when a preset is applied
  - Haptic feedback enhances the interaction
- **Movable UI Component**: 
  - Can be moved between main Settings and Advanced Settings
  - "Hide" button moves presets UI to Advanced Settings instantly
  - "To Settings" button moves presets UI back to main Settings
  - Location preference persists between app launches
  - Located in Advanced Settings by default to keep main UI clean for newcomers
- **Default Nap Presets**:
  - App now includes two built-in presets for common use cases:
    - "Basic nap": 30s → 20m → 30m (hold → nap → max) for standard napping
    - "Quick test": 5s → 20s → 1m for quickly testing app functionality
  - Default presets are created automatically on first app launch
  - Users can still modify or delete these defaults if desired
- **Help System**: 
  - "?" button explains preset functionality
  - Clear instructions for creating and managing presets
- **Compact Formatting**:
  - Timer values display in efficient format (e.g., "5s→1m→2m")
  - Space-efficient design with auto-sizing based on content
- **Persistent Storage**: 
  - All presets saved to UserDefaults
  - Presets persist across app launches
  - State restoration preserves user customizations

### Audio Output Selection Feature
- **Speaker/Bluetooth Control**: Users can select whether alarm audio plays from the device speaker or Bluetooth
- **Default Speaker Mode**: App uses the device speaker by default, even when Bluetooth devices are connected
- **Bluetooth Mode Option**: Option to use connected headphones or Bluetooth devices for alarm sounds
- **Standalone UI Section**: Implemented as a dedicated UI card on the main settings screen, similar to Circle Size and Alarm Sound
- **Connected Device Detection**: Shows what Bluetooth/external audio device is currently connected
- **Enhanced Speaker Enforcement**: 
  - When "Device Speaker" is selected, the app forcibly routes alarm audio to the device's internal speaker
  - This works even when AirPods or other Bluetooth devices are connected and active
  - Users can listen to other audio via Bluetooth, but alarms will always play through the phone speaker
  - Prevents missing alarms when using Bluetooth headphones with limited battery life
- **Visual Feedback**: 
  - Clear visual indication of selected output mode
  - Haptic feedback when changing selection 
- **Movable UI Component**: 
  - Can be moved between main Settings and Advanced Settings
  - "Hide" button moves Audio Output UI to Advanced Settings instantly
  - "To Settings" button moves Audio Output UI back to main Settings
  - Location preference persists between app launches
  - Located in Advanced Settings by default to keep main UI clean

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

### UI Flexibility Improvements
- **Movable UI Sections**: All UI sections can now be moved between Advanced Settings and Main Settings
  - Implemented a reusable `MovableSettingSection` component for consistent behavior
  - Each section has a "Hide" button to move it to Advanced Settings
  - Each section has a "To Main" button in Advanced Settings to move it back
  - Smooth animation transition when moving sections
  - Settings locations are persisted between app launches
  - Provides complete UI customization for different user preferences
  - Can be used to simplify the main interface by moving rarely used controls

### Marquee Text for Long Labels
- **Sliding Text Effect**: Added marquee effect for handling long text in fixed-width containers
  - Automatically detects when text is too long for its container
  - Only activates scrolling when necessary (static display for shorter text)
  - Smooth, continuous horizontal scrolling animation
  - Fade effect on both ends for a polished look
  - Used for alarm sound titles in dropdown menus
  - Improves readability of long custom sound names
  - Provides visual indication that text extends beyond visible area

### Notification Testing UI
- **Out-of-App Notification Tester**: Added dedicated UI for testing notifications
  - Located in Advanced Settings
  - Allows testing notifications without interfering with alarm functionality
  - User can specify test delay (3-30 seconds)
  - Provides clear feedback when test is scheduled
  - Shows notification permission status
  - Uses different notification category from alarms
  - Ideal for verifying system notification settings

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

### Performance Optimizations

#### Commitment Message Performance Fixes
- **Enhanced Debounce Mechanism**: Extended debounce timing from 0.5s to 0.8s to better handle rapid UI changes
- **Background Thread Processing**: Moved settings persistence operations to background threads using `DispatchQueue.global(qos: .userInitiated)`
- **Dedicated Serial Queue**: Created a serial queue for settings operations to prevent concurrent UserDefaults access
- **Metal Rendering**: Added `drawingGroup()` modifier to Text views containing dynamically updated content for GPU-accelerated rendering
- **Scroll Input Optimizations**: Improved CuteTimePicker wheel picker performance by adding more efficient debouncing and threading
- **Delayed Observers Setup**: Added a small delay to TimerManager initialization to prevent feedback loops during app startup
- **Forced Synchronization**: Added `UserDefaults.synchronize()` call to ensure settings are committed to disk efficiently
- **Explicit Thread Management**: Added explicit thread transitions between background processing and UI updates
- **Staggered UI Updates**: Implemented non-blocking UI updates with small delays to prevent UI freezing
- **ThreadSafe Value Updates**: Added thread safety in CuteTimePicker by ensuring binding updates happen on the main thread
- **Fixed Reference Type Patterns**: Removed improper use of reference type memory management (`weak self`) in struct closures, as this is only applicable to classes

#### SwiftUI Initial Scroll Behavior
Note: There is a small lag when first using a SwiftUI wheel picker after app launch. This is expected behavior with the SwiftUI framework and happens only on the first scroll after app initialization. This behavior is consistent across many SwiftUI applications and does not indicate a performance issue with the app itself.

## Bug Fixes

### Fixed Type Reference Issue
- Fixed error `'AlarmSound' is not a member type of class 'SnoozeFuze.TimerManager'` by updating all references in SettingsScreen.swift to use the top-level `AlarmSound` type instead of `TimerManager.AlarmSound`.

### Fixed Navigation Flow
- Fixed the "Back to Settings" button in SleepScreen to properly dismiss both SleepScreen and NapScreen, returning to SettingsScreen
- Implemented a closure-based dismiss action that's passed from NapScreen to SleepScreen to enable proper navigation
- Ensured timers are properly reset when returning to SettingsScreen

### Fixed Timer Transitions
- **Max Timer Completion Transition**: Added notification observer for maxTimerFinished to ensure immediate transition to SleepScreen when Max Timer reaches zero
- **Automatic Alarm Activation**: Added automatic alarm sound playback when Max Timer reaches zero
- **Intelligent Nap Timer Initialization**: Modified SleepScreen to use the remaining Max Timer value when it's lower than the full Nap Duration
- **Preserved Timer States**: Prevented timer reset on SleepScreen appearance to maintain correct timer values between screens
- **Circle Placement Reset**: Fixed NapScreen to properly reset to "tap anywhere to place circle" state when returning from SleepScreen, providing a consistent user experience
- **Paused Hold Timer During Circle Placement**: Fixed bug where hold timer would continue to count down during the "tap anywhere to place circle" state, ensuring timers only run when appropriate
- **Fixed Timer Management When Returning to NapScreen**: Removed automatic holdTimer restart when returning from SleepScreen to NapScreen, preventing the release timer from running during circle placement
- **Delayed Max Timer Start**: Fixed Max Timer to only start when the user first presses the circle after placement, not immediately after placing the circle, ensuring user control over timer initiation
- **Comprehensive Timer Reset**: Added proper Max Timer stopping when returning to circle placement state, ensuring all timers are fully stopped during the placement phase
- **Proper Alarm Stopping**: Fixed issue where alarm would continue playing when navigating back to Nap or Settings screens by fully stopping audio playback and deactivating audio session
- **Fixed Timer Value Display**: Corrected issue where Release Timer would temporarily show 0 when returning from Sleep Screen, now immediately shows the correct time value upon screen transition

### Fixed Notification Sounds
- **Critical Alert System**: Used system-provided critical alert notifications that play at higher volume even in silent mode
- **Simplified Audio Handling**: Streamlined audio playback code to prevent interruptions and ensure continuous alarm playback
- **Reliable Sound System**: Implemented robust audio session handling with proper interruption management
- **Foreground/Background Switch**: Added different notification handling for foreground and background states
- **Notification Action Handling**: Enhanced notification action handling for snooze functionality
- **Audio Interruption Recovery**: Added proper handling of audio interruptions to resume alarm sounds after phone calls
- **Cross-Device Compatibility**: Ensured alarm sounds work reliably across different iOS devices and versions

### Race Condition Fixes
- **Timer/Navigation Race Condition**: Fixed a race condition where sliding back from NapScreen at exactly the moment when the timer expires would cause unexpected behavior (transition to Settings while alarm plays)
- **Improved State Handling**: Added guard conditions to check timer state before triggering transitions
- **Timing Threshold Detection**: Added code that detects when timer is about to expire (< 0.5 seconds) and handles the transition appropriately
- **Comprehensive Cleanup**: Enhanced the resource cleanup when screens are dismissed:
  - All notification observers are properly removed
  - Timers are always stopped when screens are dismissed
  - Alarms are properly canceled to prevent lingering sounds
  - Pending notifications are canceled to prevent unwanted alerts
- **User Experience Improvement**: The app now consistently shows the correct screen based on timer state

### Vibration Bug Fix
- **Persistent Vibration Issue**: Fixed bug where alarm vibration would continue after stopping the alarm
  - Added property to store vibration timer reference in HapticManager
  - Updated StopAlarmSound method to properly cancel vibration timers
  - Added dedicated stopAlarmVibration method to NotificationManager
  - Ensures vibration stops when alarm is dismissed from any screen
  - Provides more consistent behavior with audio stopping

### SleepScreen Skip Bug Fix
- **Missing Alarm on Skip**: Fixed bug where skipping on SleepScreen didn't play the alarm
  - Updated skip action to explicitly play alarm sound when skipping
  - Ensures consistent behavior between natural timer end and manual skip
  - Maintains expected user experience when skipping ahead

### Volume Slider Persistence Fix
- **Volume Setting Not Saved**: Fixed issue where alarm volume slider didn't save its value
  - Added explicit saveSettings() calls after slider value changes
  - Ensures volume setting is saved both during dragging and on release
  - Maintains consistent volume setting between app launches
  - Prevents unexpected volume changes when alarm triggers

## Build and Run Instructions

1. Open the project in Xcode
2. Ensure you have iOS 18.0+ as deployment target
3. **Important**: You must add the "Audio, AirPlay, and Picture in Picture" background mode capability:
   - In Xcode, select the project file
   - Go to the "Signing & Capabilities" tab
   - Click "+ Capability" button
   - Add "Background Modes"
   - Check "Audio, AirPlay, and Picture in Picture"
   - This allows the app to continue playing alarm sounds even when in background
4. Build and run on simulator or physical device

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

### Flashy Logo Animation
- **Smooth Sequenced Animation**: Carefully choreographed animation phases that flow naturally without jarring transitions
- **Staggered Particle Emission**: Particles emerge gradually with subtle delays for more natural movement
- **Physics-Based Movement**: Particles follow fluid physics with gentle gravity and turbulence for organic motion
- **Color Harmony**: Particles use a cohesive blue-purple color theme that complements the app's aesthetic
- **Graduated Transitions**: Every animation element uses proper easing and spring effects for smooth transitions
- **Hue Cycling Effect**: Subtle color shifts add visual interest without overwhelming the animation
- **Multi-Phase Rotation**: Rotation begins gently and accelerates naturally for a more fluid spin
- **Responsive Scaling**: Logo scaling uses spring physics for natural bouncing without abrupt changes
- **Fade Transitions**: All elements fade in and out gradually to avoid sudden appearances or disappearances
- **Haptic Feedback**: Subtle vibration provides tactile confirmation when animation is triggered
- **Performance Optimized**: Uses Metal rendering via drawingGroup() and efficient animation techniques
- **Extended Duration**: Longer animation (2.0 seconds) allows for proper pacing of all animation phases

### Help Button Tooltips
- **Contextual Help**: Added subtle question mark icons next to each setting in the Settings screen
- **On-demand Information**: Users can tap the help icons to see explanations about specific features
- **Clear Descriptions**: Each tooltip provides concise yet informative explanations about:
  - **Circle Size**: Controls the size of the hold circle with information about visibility vs. screen space
  - **Timer Settings**: Explains the purpose of each timer (Release, Nap, Max) 
  - **Alarm Sound**: Describes sound selection options including custom sounds
- **Unobtrusive Design**: Help buttons are subtle and don't interfere with the main UI
- **Consistent Placement**: All help buttons follow the same design pattern and positioning

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

### Advanced Settings Enhancements
- **Visual Settings Section**: Added a new category in Advanced Settings for visual customizations
- **Timer Arcs Toggle**: Added option to enable/disable the circular timer arcs around the hold circle
- **User Preference Persistence**: Visual settings preferences are saved across app launches
- **Configurable UI**: Allows users to choose between minimal and informative visual styles
- **Enabled by Default**: Timer arcs are enabled by default for the best visual experience out of the box
- **Battery Usage Information**: Added informative text noting the estimated 2-3% battery impact of enabling timer arcs

### Timer Settings Enhancements
- **Commitment Message**: Added a clear, dynamically-updating message under timer settings that explains the timer sequence
- **Plain Language Explanation**: Message clearly states "When you lift your finger, the countdown will start from X seconds/minutes. After that, your nap will last X seconds/minutes. If something goes wrong, the max limit is X seconds/minutes as a backup."
- **Dynamic Value Display**: Times automatically update when the user changes any timer setting
- **Smart Unit Formatting**: Displays values with appropriate units (seconds/minutes) and proper singular/plural forms
- **Visual Integration**: Styled to match the app's overall design while maintaining readability
- **Improved User Understanding**: Helps users better understand the relationship between the three timers
- **Enhanced Unit Selection UI**:
  - **Visible Interactivity Cues**: Added chevron up/down icon to clearly indicate unit values are tappable
  - **Subtle Pulsing Animation**: Implemented a gentle pulsing effect around the unit button to draw attention
  - **Improved Visual Contrast**: Added slightly colored background to make the tap target more distinctive
  - **Clear Affordance**: Applied proper UI design principles to provide strong visual affordance for the interactive element
  - **Consistent Styling**: Maintained the existing color scheme and visual language of the app
  - **Increased Touch Target**: Expanded the tappable area with additional padding for easier interaction

### Button Style Enhancements
- **Simplified Styling**: Updated buttons with flat colors for improved readability
- **Clean Aesthetic**: Removed gradients and shadows for a more minimalist appearance
- **Clear Visual States**: Used distinct colors to indicate button states (blue for normal, orange for intermediate, red for confirming)
- **Consistent Design**: Maintained consistent styling across all button types
- **Visual Boundaries**: Added subtle border strokes to define button edges
- **Optimized Contrast**: Ensured sufficient color contrast for better readability
- **Improved Typography**: Used system rounded fonts for a friendly, legible appearance
- **Balanced Proportions**: Optimized icon and text sizes for visual clarity
- **Generous Padding**: Added comfortable padding around button content for better touch targets
- **Readable Text**: Used appropriate font sizes and weights to ensure text legibility
- **Clear Action Indicators**: Used double chevron icons for swipe actions
- **Explicit Interaction Labels**: Added explicit "Swipe to..." prefixes to clarify required interactions

### SleepScreen UI Enhancements
- **Clear Navigation Path**: 'Back to Nap' button on left, 'Skip' button on right
- **Proper Destination Paths**: Back to Nap button returns to NapScreen while keeping settings, Skip button completes nap immediately
- **Visual Clarity**: Simplified button design with flat colors for better readability
- **Proper Spacing**: Improved layout and spacing for buttons and UI elements
- **Clearer Labels**: Updated button labels to clearly indicate their function and required actions (e.g., 'Swipe to Nap', 'Swipe to skip')
- **Color Differentiation**: Used different colors to distinguish button functions (blue for Back to Nap, purple for Skip)
- **Consistent Visuals**: All buttons use same visual design for consistent UX
- **Intuitive Icons**: Used double chevron icons to indicate swipe direction
- **Consistent Interaction Mode**: All interactive buttons use swipe gestures with MultiSwipeConfirmation for better safety

### NapScreen UI Enhancements
- **Improved Timer Display**: Modified timer to show only seconds when there are no minutes left (e.g. "08.3" instead of "00:08.3") for cleaner presentation
- **Immediate Timer Value Display**: Modified NapScreen to show MAX TIMER and NAP DURATION values immediately upon entry, rather than waiting for circle placement
- **Optimized Message Positioning**: Improved the positioning of the "Tap anywhere" message to coexist with timer displays using GeometryReader for proper centering
- **Enhanced Position Text**: Redesigned the "Tap anywhere to position your circle" message with:
  - **Glass Morphism Effect**: Added subtle glass reflection gradient overlay for a modern look
  - **Enhanced Shadow**: Improved shadow depth and spread for better visual prominence
  - **Subtle Blur Effect**: Added slight blur to the background rectangle for a frosted glass appearance
  - **Improved Contrast**: Enhanced the text and background contrast for better readability
  - **Refined Animations**: Animated decorative elements for visual interest
  - **Polished Typography**: Maintained the existing font styles for consistency with app design
  - **Responsive Layout**: Preserved the responsive positioning to work across different device sizes
- **Timer Visual Hierarchy Improvements**:
  - **Larger Release Timer**: Increased size and added subtle shadow for the most important timer
  - **Enhanced Max Timer**: Made more prominent with purple accent color and larger text
  - **Distinct Nap Duration Display**: Clearly separated with its own style but less emphasis
  - **Visual Container Separation**: Added distinct containers with subtle borders for timers
  - **Prioritized Release Timer**: Display release timer in the circle instead of max timer for better at-a-glance information about the immediate countdown
  - **De-emphasized Nap Duration**: Moved nap duration to a subtle "Up Next" display in the top right corner
  - **Improved Information Priority**: UI now emphasizes the most immediately relevant timer (release timer) both in the main display and circle
  - **More Intuitive Layout**: Created a logical hierarchy of information based on immediate relevance
  - **Cleaner Design**: Reduced visual clutter by moving less critical information (nap duration) to the periphery
  - **Responsive Placement**: Maintained proper spacing and layout across different device sizes
- **Dual-Arc Progress System**: 
  - **Concentric Timer Arcs**: Implemented two concentric arcs that show both the Max Timer and Release Timer progress
  - **Outer Arc**: Represents Max Timer progress with a consistent purple color that matches the MAX TIMER UI element
  - **Inner Arc**: Shows Release Timer progress with elegant white color that shifts to pink when pressed
  - **Visual Separation**: Arcs positioned at different distances for clear visual hierarchy
  - **Clear Visual Hierarchy**: Immediate visual understanding of both timer states without looking away from circle
  - **Intuitive Design**: The concentric circle design naturally communicates the nested timer relationship
  - **Compact Layout**: Both arcs positioned within or just at the edge of the circle for a cohesive design
  - **Minimalist Styling**: Clean, distraction-free arcs without glow effects or animations
  - **Color-Coded Timers**: Distinct colors for each timer type (blue/purple for Max Timer, white/pink for Release Timer)
  - **Consistent Color Theme**: Release Timer arc color (white/pink) matches the timer text for perfect color coordination
  - **Optimized Arc Thickness**: Thinner Release Timer arc (5px vs 8px) with subtle black background arc for improved visibility and elegance
  - **Burning Fuse Effect**: Added sparking particle animation to the Release Timer arc when the circle is not pressed
  - **Thematic Visual Design**: Sparking effect visually represents the app's "SnoozeFuse" name, showing a burning fuse that extinguishes when pressed
  - **Star-Shaped Sparkles**: Used custom star shapes that resemble the sparkle emoji ✨ instead of simple circles
  - **Varied Sparkle Sizes**: Multiple sparkle sizes create visual depth and realism in the effect
  - **Dynamic Rotations**: Sparkles rotate as they animate for enhanced visual interest
  - **Random Timing**: Randomized fade timing makes the sparkling appear more organic and realistic
  - **Increased Particle Count**: More particles (12 instead of 5) for a richer visual effect
  - **Position-Aware Particles**: Sparks always appear at the exact position of the current Release Timer progress point
  - **Intuitive Interaction Model**: Pressing the circle "extinguishes" the burning fuse, releasing lets it burn with visible sparks
  - **Realistic Burning Ember**: Added orange-red glowing ember behind the blackened burnt tip for authentic burning effect
  - **Enhanced Color Palette**: Used a vibrant orange-red-yellow palette to simulate real fire and ember effects
  - **Rapid Animation**: Faster, more intense animations give the impression of a vigorously burning fuse
  - **Directional Burnt Particles**: Black particles emit opposite to the burning direction, flying away from the fuse as it burns
  - **Long-Distance Emission**: Particles travel 30-60 pixels away from the tip, creating a dramatic trailing effect
  - **Angle-Based Trajectory**: Particles move in relation to the actual burning angle, creating realistic physics
  - **Subtle Angular Variation**: Small random angle adjustments create a natural spread pattern rather than a perfectly straight line
  - **Size Variation**: Tiny particles of different sizes (1.5-3px) create a more natural, organic burnt effect
  - **Increased Flight Time**: Longer animation durations (1-2 seconds) allow particles to travel their greater distances
  - **High-Intensity Visual**: The combination of ember glow, emitting burnt particles, and intense sparkles creates a striking visual metaphor

### Full-Screen Touch Mode

When enabled, this mode allows the user to touch anywhere on the screen to trigger the hold action, not just on the circle. This is especially useful for:

- Users who want to hold their device in a more comfortable position
- Preventing accidental touch releases on the circle
- Easier one-handed operation
- People with motor control difficulties

### Sci-Fi Connecting Line Effect

When the app is in full-screen mode, a visual line connects the circle to the user's finger:

- **Techy Visual Design**: The line has a sci-fi appearance with glowing red/orange effects and animated segments.
- **Interactive Feedback**: The app tracks your finger position and connects it to the circle.
- **Touch Position Awareness**: The line dynamically updates with your finger movement.
- **Animated Flow Effect**: Dashed line segments are animated to flow for a futuristic look.
- **Particle Energy Flow**: Small energy particles travel along the line.
- **Glowing Connection**: A subtle blur effect gives the line a holographic appearance.
- **Mode Indicator**: The line clearly indicates you're in active full-screen touch mode.
- **Cohesive Color Scheme**: Uses red and orange gradients for a warning/energy aesthetic.
- **Finger Touch Point Effect**: Shows a small energy burst effect at the touch point.
- **Clean Implementation**: Implemented using SwiftUI Path and GeometryReader for performance.

The connecting line can be disabled in Advanced Settings > Visual Settings if preferred while still keeping full-screen touch mode enabled.

## Haptic Feedback

### Implementation Details
- Uses `UNUserNotificationCenter` API for permission management and scheduling
- Notification permission state is checked on app launch
- Notifications are scheduled with critical sound (`UNNotificationSound.defaultCritical`)
- Notification UI components adapt based on current permission state
- Advanced notification settings available in the Advanced Settings screen
- Notification warning UI can be moved between main Settings and Advanced Settings screens
- User preference for notification warning location is persisted across app launches

### Haptic and Vibration Features
- **Regular Haptic Feedback**: Provides tactile feedback when touching the circle
- **Customizable Intensity**: Users can choose between Light, Medium, and Heavy haptic feedback
- **Toggle Control**: Users can enable/disable all haptic feedback from Advanced Settings
- **System Alarm Vibration**: Uses a multi-layered approach for maximum wake-up effectiveness:
  - Uses AudioServicesPlaySystemSound API to trigger hardware-level vibration
  - Implements continuous pattern of alternating vibrations (1.0s and 0.5s intervals)
  - Simultaneously schedules critical notifications for additional vibration signals
  - Vibration continues until explicitly stopped by user action
- **Silent Mode Override**: Requests critical alert permissions to break through Do Not Disturb and silent modes
- **Hardware-Level Vibration**: Utilizes low-level AudioToolbox functions for direct vibration motor access
- **Redundant Systems**: Combines notification and direct hardware approaches for maximum reliability
- **Permission Handling**: Properly requests and manages critical alert permissions (requires Apple approval)
- **Persistent Pattern**: Creates an ongoing vibration pattern similar to the native Clock app
- **Coordinated Sound and Vibration**: Sound and vibration are synchronized for maximum sensory effect
- **Graceful Permission Fallback**: Still provides best-possible experience if critical alert permission is not granted

### Critical Alerts Implementation
- **Entitlement Requirement**: The app requires the `com.apple.developer.usernotifications.critical-alerts` entitlement from Apple
- **Privacy Justification**: Required to provide effective alarm functionality for users who may be sleeping
- **Permission Request**: Explicitly requests critical alert permission during app initialization
- **Visual Indication**: Checks and displays critical alert permission status to users
- **Alternative Mechanisms**: Falls back to combining multiple non-critical approaches if permission is denied
- **User Control**: Always allows users to dismiss alarms and stop vibrations when needed

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

### Flashy Logo Animation
- **Smooth Sequenced Animation**: Carefully choreographed animation phases that flow naturally without jarring transitions
- **Staggered Particle Emission**: Particles emerge gradually with subtle delays for more natural movement
- **Physics-Based Movement**: Particles follow fluid physics with gentle gravity and turbulence for organic motion
- **Color Harmony**: Particles use a cohesive blue-purple color theme that complements the app's aesthetic
- **Graduated Transitions**: Every animation element uses proper easing and spring effects for smooth transitions
- **Hue Cycling Effect**: Subtle color shifts add visual interest without overwhelming the animation
- **Multi-Phase Rotation**: Rotation begins gently and accelerates naturally for a more fluid spin
- **Responsive Scaling**: Logo scaling uses spring physics for natural bouncing without abrupt changes
- **Fade Transitions**: All elements fade in and out gradually to avoid sudden appearances or disappearances
- **Haptic Feedback**: Subtle vibration provides tactile confirmation when animation is triggered
- **Performance Optimized**: Uses Metal rendering via drawingGroup() and efficient animation techniques
- **Extended Duration**: Longer animation (2.0 seconds) allows for proper pacing of all animation phases

### Help Button Tooltips
- **Contextual Help**: Added subtle question mark icons next to each setting in the Settings screen
- **On-demand Information**: Users can tap the help icons to see explanations about specific features
- **Clear Descriptions**: Each tooltip provides concise yet informative explanations about:
  - **Circle Size**: Controls the size of the hold circle with information about visibility vs. screen space
  - **Timer Settings**: Explains the purpose of each timer (Release, Nap, Max) 
  - **Alarm Sound**: Describes sound selection options including custom sounds
- **Unobtrusive Design**: Help buttons are subtle and don't interfere with the main UI
- **Consistent Placement**: All help buttons follow the same design pattern and positioning

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

### Advanced Settings Enhancements
- **Visual Settings Section**: Added a new category in Advanced Settings for visual customizations
- **Timer Arcs Toggle**: Added option to enable/disable the circular timer arcs around the hold circle
- **User Preference Persistence**: Visual settings preferences are saved across app launches
- **Configurable UI**: Allows users to choose between minimal and informative visual styles
- **Enabled by Default**: Timer arcs are enabled by default for the best visual experience out of the box
- **Battery Usage Information**: Added informative text noting the estimated 2-3% battery impact of enabling timer arcs

### Timer Settings Enhancements
- **Commitment Message**: Added a clear, dynamically-updating message under timer settings that explains the timer sequence
- **Plain Language Explanation**: Message clearly states "When you lift your finger, the countdown will start from X seconds/minutes. After that, your nap will last X seconds/minutes. If something goes wrong, the max limit is X seconds/minutes as a backup."
- **Dynamic Value Display**: Times automatically update when the user changes any timer setting
- **Smart Unit Formatting**: Displays values with appropriate units (seconds/minutes) and proper singular/plural forms
- **Visual Integration**: Styled to match the app's overall design while maintaining readability
- **Improved User Understanding**: Helps users better understand the relationship between the three timers
- **Enhanced Unit Selection UI**:
  - **Visible Interactivity Cues**: Added chevron up/down icon to clearly indicate unit values are tappable
  - **Subtle Pulsing Animation**: Implemented a gentle pulsing effect around the unit button to draw attention
  - **Improved Visual Contrast**: Added slightly colored background to make the tap target more distinctive
  - **Clear Affordance**: Applied proper UI design principles to provide strong visual affordance for the interactive element
  - **Consistent Styling**: Maintained the existing color scheme and visual language of the app
  - **Increased Touch Target**: Expanded the tappable area with additional padding for easier interaction

### Button Style Enhancements
- **Simplified Styling**: Updated buttons with flat colors for improved readability
- **Clean Aesthetic**: Removed gradients and shadows for a more minimalist appearance
- **Clear Visual States**: Used distinct colors to indicate button states (blue for normal, orange for intermediate, red for confirming)
- **Consistent Design**: Maintained consistent styling across all button types
- **Visual Boundaries**: Added subtle border strokes to define button edges
- **Optimized Contrast**: Ensured sufficient color contrast for better readability
- **Improved Typography**: Used system rounded fonts for a friendly, legible appearance
- **Balanced Proportions**: Optimized icon and text sizes for visual clarity
- **Generous Padding**: Added comfortable padding around button content for better touch targets
- **Readable Text**: Used appropriate font sizes and weights to ensure text legibility
- **Clear Action Indicators**: Used double chevron icons for swipe actions
- **Explicit Interaction Labels**: Added explicit "Swipe to..." prefixes to clarify required interactions

### SleepScreen UI Enhancements
- **Clear Navigation Path**: 'Back to Nap' button on left, 'Skip' button on right
- **Proper Destination Paths**: Back to Nap button returns to NapScreen while keeping settings, Skip button completes nap immediately
- **Visual Clarity**: Simplified button design with flat colors for better readability
- **Proper Spacing**: Improved layout and spacing for buttons and UI elements
- **Clearer Labels**: Updated button labels to clearly indicate their function and required actions (e.g., 'Swipe to Nap', 'Swipe to skip')
- **Color Differentiation**: Used different colors to distinguish button functions (blue for Back to Nap, purple for Skip)
- **Consistent Visuals**: All buttons use same visual design for consistent UX
- **Intuitive Icons**: Used double chevron icons to indicate swipe direction
- **Consistent Interaction Mode**: All interactive buttons use swipe gestures with MultiSwipeConfirmation for better safety

### NapScreen UI Enhancements
- **Improved Timer Display**: Modified timer to show only seconds when there are no minutes left (e.g. "08.3" instead of "00:08.3") for cleaner presentation
- **Immediate Timer Value Display**: Modified NapScreen to show MAX TIMER and NAP DURATION values immediately upon entry, rather than waiting for circle placement
- **Optimized Message Positioning**: Improved the positioning of the "Tap anywhere" message to coexist with timer displays using GeometryReader for proper centering
- **Enhanced Position Text**: Redesigned the "Tap anywhere to position your circle" message with:
  - **Glass Morphism Effect**: Added subtle glass reflection gradient overlay for a modern look
  - **Enhanced Shadow**: Improved shadow depth and spread for better visual prominence
  - **Subtle Blur Effect**: Added slight blur to the background rectangle for a frosted glass appearance
  - **Improved Contrast**: Enhanced the text and background contrast for better readability
  - **Refined Animations**: Animated decorative elements for visual interest
  - **Polished Typography**: Maintained the existing font styles for consistency with app design
  - **Responsive Layout**: Preserved the responsive positioning to work across different device sizes
- **Timer Visual Hierarchy Improvements**:
  - **Larger Release Timer**: Increased size and added subtle shadow for the most important timer
  - **Enhanced Max Timer**: Made more prominent with purple accent color and larger text
  - **Distinct Nap Duration Display**: Clearly separated with its own style but less emphasis
  - **Visual Container Separation**: Added distinct containers with subtle borders for timers
  - **Prioritized Release Timer**: Display release timer in the circle instead of max timer for better at-a-glance information about the immediate countdown
  - **De-emphasized Nap Duration**: Moved nap duration to a subtle "Up Next" display in the top right corner
  - **Improved Information Priority**: UI now emphasizes the most immediately relevant timer (release timer) both in the main display and circle
  - **More Intuitive Layout**: Created a logical hierarchy of information based on immediate relevance
  - **Cleaner Design**: Reduced visual clutter by moving less critical information (nap duration) to the periphery
  - **Responsive Placement**: Maintained proper spacing and layout across different device sizes
- **Dual-Arc Progress System**: 
  - **Concentric Timer Arcs**: Implemented two concentric arcs that show both the Max Timer and Release Timer progress
  - **Outer Arc**: Represents Max Timer progress with a consistent purple color that matches the MAX TIMER UI element
  - **Inner Arc**: Shows Release Timer progress with elegant white color that shifts to pink when pressed
  - **Visual Separation**: Arcs positioned at different distances for clear visual hierarchy
  - **Clear Visual Hierarchy**: Immediate visual understanding of both timer states without looking away from circle
  - **Intuitive Design**: The concentric circle design naturally communicates the nested timer relationship
  - **Compact Layout**: Both arcs positioned within or just at the edge of the circle for a cohesive design
  - **Minimalist Styling**: Clean, distraction-free arcs without glow effects or animations
  - **Color-Coded Timers**: Distinct colors for each timer type (blue/purple for Max Timer, white/pink for Release Timer)
  - **Consistent Color Theme**: Release Timer arc color (white/pink) matches the timer text for perfect color coordination
  - **Optimized Arc Thickness**: Thinner Release Timer arc (5px vs 8px) with subtle black background arc for improved visibility and elegance
  - **Burning Fuse Effect**: Added sparking particle animation to the Release Timer arc when the circle is not pressed
  - **Thematic Visual Design**: Sparking effect visually represents the app's "SnoozeFuse" name, showing a burning fuse that extinguishes when pressed
  - **Star-Shaped Sparkles**: Used custom star shapes that resemble the sparkle emoji ✨ instead of simple circles
  - **Varied Sparkle Sizes**: Multiple sparkle sizes create visual depth and realism in the effect
  - **Dynamic Rotations**: Sparkles rotate as they animate for enhanced visual interest
  - **Random Timing**: Randomized fade timing makes the sparkling appear more organic and realistic
  - **Increased Particle Count**: More particles (12 instead of 5) for a richer visual effect
  - **Position-Aware Particles**: Sparks always appear at the exact position of the current Release Timer progress point
  - **Intuitive Interaction Model**: Pressing the circle "extinguishes" the burning fuse, releasing lets it burn with visible sparks
  - **Realistic Burning Ember**: Added orange-red glowing ember behind the blackened burnt tip for authentic burning effect
  - **Enhanced Color Palette**: Used a vibrant orange-red-yellow palette to simulate real fire and ember effects
  - **Rapid Animation**: Faster, more intense animations give the impression of a vigorously burning fuse
  - **Directional Burnt Particles**: Black particles emit opposite to the burning direction, flying away from the fuse as it burns
  - **Long-Distance Emission**: Particles travel 30-60 pixels away from the tip, creating a dramatic trailing effect
  - **Angle-Based Trajectory**: Particles move in relation to the actual burning angle, creating realistic physics
  - **Subtle Angular Variation**: Small random angle adjustments create a natural spread pattern rather than a perfectly straight line
  - **Size Variation**: Tiny particles of different sizes (1.5-3px) create a more natural, organic burnt effect
  - **Increased Flight Time**: Longer animation durations (1-2 seconds) allow particles to travel their greater distances
  - **High-Intensity Visual**: The combination of ember glow, emitting burnt particles, and intense sparkles creates a striking visual metaphor

### Full-Screen Touch Mode
- **Enhanced Accessibility Feature**: Added a toggle in Settings to enable Full-Screen Touch Mode
- **Effortless Interaction**: When enabled, the entire screen becomes touch-sensitive instead of just the circle
- **Compact UI Control**: Toggle is positioned next to the Circle Size control for logical grouping of related settings
- **Visual Feedback**: Animated dashed border around the circle indicates when Full-Screen Mode is active
- **Informative Tooltip**: Help tooltip provides clear explanation of the feature's purpose and functionality
- **Persistent Setting**: User preference for Full-Screen Mode is saved in UserDefaults and persists across app launches
- **Clear Status Indication**: Initial "Tap Anywhere" screen displays a notice when Full-Screen Mode is enabled
- **Robust Multi-Touch Handling**: Properly maintains touch state even when multiple fingers are used simultaneously
- **App Switching Protection**: Gracefully handles app backgrounding and foregrounding to maintain proper timer states
- **Consistent Experience**: Provides the same reliable experience as the original circle touch mechanism
- **Implementation Details**:
  - **Smart Touch Handling**: Maintains the original circle visuals while expanding the touch detection area
  - **Optimized Gesture Recognition**: Uses efficient gesture detection that responds to the lightest touch
  - **Consistent Visual Feedback**: Circle still animates identically whether touched directly or activated via full-screen mode
  - **Unchanged Visual Elements**: All visual elements (timer arcs, spark effects, etc.) remain identical regardless of touch mode
  - **Simplified Accessibility**: Makes the app much easier to use for users with fine motor control challenges
  - **Visual Mode Indicator**: Animated rotating gradient dashed circle provides subtle but clear indication of mode status
  - **Visual Integration**: Gradient colors match the app's overall color scheme for a cohesive appearance
  - **Manual Size Control**: Users can still adjust the visual circle size independently from the touch area
  - **Native Touch Tracking**: Uses UIKit's native touch handling for maximum reliability and performance
  - **Active Touch Set Management**: Maintains a set of active touches to ensure proper state in multi-touch scenarios
  - **App Lifecycle Awareness**: Listens for app state notifications to properly handle backgrounding and foregrounding
  - **Top-Level Touch Detection**: Positioned at the highest level of the view hierarchy to capture all touches regardless of what UI elements are underneath
  - **Sci-Fi Connecting Line Effect**: Visual line that connects the circle to the user's finger in full-screen mode:
    - **Techy Visual Design**: Line has a sci-fi appearance with glowing effect and animated segments
    - **Interactive Feedback**: Shows users that the app is tracking their finger position across the screen
    - **Touch Position Awareness**: Dynamically updates as the user's finger moves across the screen
    - **Animated Flow Effect**: Dashed line segments animate along the connection for a futuristic energy flow effect
    - **Particle Energy Flow**: Small energy particles travel along the line toward the finger for enhanced visual interest
    - **Glowing Connection**: Line has a subtle blur effect creating a holographic appearance
    - **Mode Indicator**: Serves as a clear visual indicator that full-screen touch mode is active
    - **Cohesive Color Scheme**: Uses blue and cyan gradients that match the app's color palette
    - **Finger Touch Point Effect**: Small energy burst effect where the finger touches for enhanced visual feedback
    - **Clean Implementation**: Uses efficient SwiftUI Path and GeometryReader for smooth performance

### Implementation Details
- Implemented `MultiSwipeConfirmation`

### Audio Controls Features
- **Speaker/Bluetooth Control**: 
  - Users can select whether alarm audio plays from the device speaker or Bluetooth
  - Default Speaker Mode: App uses the device speaker by default, even when Bluetooth devices are connected
  - Connected Device Detection: Shows what Bluetooth/external audio device is currently connected
- **Volume Controls**:
  - Customizable alarm volume slider (default: 100%)
  - Option to enforce minimum volume level (default: on)
  - Adjustable minimum volume threshold (default: 10%)
  - When minimum volume is enforced, alarms will sound at least at the set minimum regardless of device volume
  - Collapsible UI - can be hidden to reduce visual clutter
- **Enhanced Speaker Routing**: 
  - When "Device Speaker" is selected, the app routes alarm audio to the device's internal speaker
  - Uses a graceful, reliable approach to route audio correctly without lag
  - Intelligently checks current output state before making changes
  - Maintains speaker preference even when Bluetooth devices are connected
  - Prevents missed alarms from Bluetooth headphones with limited battery
- **Visual Feedback**: 
  - Clear visual indication of selected output mode and volume levels
  - Haptic feedback when changing settings
- **Movable UI Component**: 
  - Each control can be moved independently between main Settings and Advanced Settings
  - "Hide" button moves UI to Advanced Settings instantly
  - "To Settings" button moves UI back to main Settings
  - Location preference persists between app launches
- **Help System**: 
  - "?" button explains audio output and volume functionality
  - Clear instructions for choosing options
- **Technical Implementation**:
  - Uses AVAudioSession routing with graceful handling of route changes
  - Handles interruptions (phone calls, etc.) correctly to maintain selected output and volume
  - Updates dynamically when devices connect/disconnect

## Code Structure Improvements

### SettingsScreen Refactoring
The SettingsScreen.swift file was refactored to improve maintainability and reduce its size. The large file was broken down into smaller component files:

1. `Components/PixelateEffect.swift` - Animation effect for the logo
2. `Components/HelpButton.swift` - Reusable help button component
3. `Components/CircleSizeControl.swift` - Circle size control UI
4. `Components/TimePickerComponents.swift` - Time unit picker components
5. `Components/TimerSettingsControl.swift` - Timer settings UI
6. `Components/SoundSelectionComponents.swift` - Sound selection related components
7. `Components/CirclePreviewOverlay.swift` - Circle preview overlay
8. `Components/ResponsiveSlider.swift` - Custom slider component
9. `Components/ColorHelpers.swift` - Color utility functions

Note: Some UI components like NotificationPermissionWarning are already defined in other files like NotificationManager.swift and should not be duplicated in the Components directory.

This refactoring makes the codebase more modular, easier to maintain, and reduces the AI context size needed to process each file.

## AudioPlayerManager Threading

- **Main Thread Safety:** Interactions with `AVAudioSession` (like `setActive`, `setCategory`, `overrideOutputAudioPort`) can block the main thread, causing UI hangs.
- **Solution:** All `AVAudioSession` calls within `AudioPlayerManager` (`cleanupAudio`, `setupBackgroundAudio`, `handleRouteChange`) have been moved to a dedicated serial background queue (`audioSessionQueue`) to prevent main thread blocking.
- **Synchronization:** Care must be taken if shared state (e.g., `isPlayingAlarm`, properties from other managers like `AudioOutputManager`) is accessed or modified from this background queue. Currently, reads are assumed safe, but writes would require proper synchronization (e.g., using `DispatchQueue.main.async` or locks). UI updates triggered by background queue operations should be dispatched back to the main thread.

## Code Optimization Notes

### Swift UI Component Refactoring
- **Issue**: Large complex views can cause the compiler to be unable to type-check expressions in reasonable time
- **Solution**: Break large views into smaller components:
  - Extract each page in a TabView into its own view struct
  - Break down complex UI elements into their own components
  - Use MARK comments to organize the code structure

### TimerElement Enum Improvements
- **Issue**: Complex enum properties with large string literals can cause compiler type-checking issues
- **Solution**: 
  - Extract long string literals into separate helper methods
  - Instead of inline string literals, use function calls in the switch statement
  - Example: `return getReleaseExplanation()` instead of returning the string directly

### AboutScreen Structure
The AboutScreen has been refactored into these components:
- `PageIndicator`: Shows the current page dots
- `NavigationButtons`: Previous/Next/Get Started buttons
- `WelcomePage`: The first page with app introduction
- `HowItWorksPage`: The demonstration with tap & hold mechanism
  - `DemoCircleView`: The interactive circle component
  - `DemoCircleText`: Text display based on circle state
- `SmartTimerSystemPage`: The interactive timer explanation screen
  - `TimerControlsView`: Container for all timer controls
  - `TimerControlView`: Individual timer component (RELEASE, NAP, MAX)
  - `UnitsIndicator`: Seconds/minutes selector
  - `TimerExplanationView`: Explanatory text for selected elements
- `PositioningPage`: Phone positioning information
- `SupportPage`: Donation and support information
  - `DonationTiersView`: Donation goals information

This modular approach improves maintainability and resolves compiler type-checking limitations.