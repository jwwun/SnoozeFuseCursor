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
- **Adaptive Implementation**: CircleView component adapts to the setting without requiring restart

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
  - **Direct Circle Timer Display**: Added Max Timer readout directly on the circle for at-a-glance information
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
  - **Optimized Arc Thickness**: Thinner outer Max Timer arc (5px) with thicker inner Release Timer arc (8px) for better visual hierarchy
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

### Implementation Details
- Implemented `MultiSwipeConfirmation`