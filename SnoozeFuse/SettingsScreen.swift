import SwiftUI
import UniformTypeIdentifiers
import UserNotifications
import MediaPlayer

// Simple flashy animation for the logo
struct PixelateEffect: ViewModifier {
    let isActive: Bool
    @State private var glowOpacity = 0.0
    @State private var glowScale = 1.0
    @State private var rotationAngle = 0.0
    @State private var bounceScale = 1.0
    @State private var hueRotation = 0.0
    
    func body(content: Content) -> some View {
        ZStack {
            // Base content with animated effects
            content
                .scaleEffect(bounceScale)
                .rotationEffect(.degrees(rotationAngle))
                .hueRotation(Angle(degrees: hueRotation))
                .animation(isActive ? 
                    .interpolatingSpring(mass: 0.2, stiffness: 5, damping: 0.5, initialVelocity: 5) : 
                    .easeInOut(duration: 0.5), 
                    value: bounceScale)
                .animation(isActive ? 
                    .interpolatingSpring(mass: 0.2, stiffness: 3, damping: 0.6, initialVelocity: 5) : 
                    .easeInOut(duration: 0.5), 
                    value: rotationAngle)
                .animation(.easeInOut(duration: 0.5), value: hueRotation)
                
            // Glow effect with smooth animation
            if isActive {
                content
                    .blur(radius: 8)
                    .opacity(glowOpacity)
                    .scaleEffect(glowScale)
                    .blendMode(.screen)
                    .animation(.easeInOut(duration: 0.7), value: glowOpacity)
                    .animation(.easeInOut(duration: 1.2), value: glowScale)
            }
        }
        .onChange(of: isActive) { newValue in
            if newValue {
                startAnimations()
            } else {
                resetAnimations()
            }
        }
    }
    
    private func startAnimations() {
        // Reset state before starting
        resetAnimations() 
        
        // Phase 1: Initial pop and glow
        withAnimation(.easeIn(duration: 0.3)) {
            glowOpacity = 0.7
            glowScale = 1.2
            bounceScale = 1.1 // Initial small bounce
        }
        
        // Phase 2: Hue shift and slight rotation start
        // Use a slightly delayed start for hue to make it less abrupt
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.linear(duration: 0.8).repeatCount(2, autoreverses: true)) {
                hueRotation = 30
            }
        }
        
        // Phase 3: Main bounce, rotation, and glow intensification
        // Delay this slightly to let phase 1 settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
             withAnimation(.easeInOut(duration: 0.8)) {
                 // Rotate smoothly over a longer duration
                 rotationAngle = 360 
             }
             withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                 // Bigger bounce effect
                 bounceScale = 1.3
                 glowOpacity = 0.9 // Max glow
                 glowScale = 1.4   // Max glow scale
             }
        }
        
        // Phase 4: Settle back and fade out glow
        // Start settling slightly after the main bounce peak
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { // Phase 3 animation duration (0.4) + delay (0.2)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                 // Settle back towards original size
                bounceScale = 0.9 // Slight overshoot
            }
             // Fade out glow while settling
             withAnimation(.easeOut(duration: 0.8)) {
                 glowOpacity = 0.0
                 glowScale = 2.0 // Glow expands as it fades
             }
        }
        
        // Phase 5: Final settle
        // Ensure this happens after the overshoot settles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { // Phase 4 settle duration (0.5) + start time (0.6) - slight overlap
             withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                 bounceScale = 1.0 // Return to normal size
             }
        }
        
         // Phase 6: Reset rotation silently after animation completes (avoids snapping)
         // Total rotation animation duration (0.8) + start delay (0.2)
         DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
             rotationAngle = 0 // Reset angle non-animated
         }
    }
    
    private func resetAnimations() {
        // Use animations for resetting too, to avoid teleporting
        withAnimation(.easeOut(duration: 0.5)) {
            glowOpacity = 0.0
            glowScale = 1.0
            hueRotation = 0.0
        }
        
        // For rotation, use a separate animation that doesn't rotate back
        if rotationAngle != 0 {
            // Find the closest multiple of 360 degrees
            let fullRotations = Int(rotationAngle / 360)
            let targetAngle = CGFloat(fullRotations + 1) * 360
            
            // First complete the rotation to the next full 360
            withAnimation(.easeInOut(duration: 0.3)) {
                rotationAngle = targetAngle
            }
            
            // Then silently reset to 0 after the animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                rotationAngle = 0
            }
        }
        
        withAnimation(.spring()) {
            bounceScale = 1.0
        }
    }
}

// HelpButton component for settings explanations
struct HelpButton: View {
    let helpText: String
    @State private var showingHelp = false
    
    var body: some View {
        Button(action: {
            showingHelp = true
        }) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.2))
        }
        .alert("Tip", isPresented: $showingHelp) {
            Button("OK!", role: .cancel) {}
        } message: {
            Text(helpText)
        }
    }
}

// Breaking up the UI into smaller components
struct CircleSizeControl: View {
    @Binding var circleSize: CGFloat
    @Binding var textInputValue: String
    @FocusState private var isTextFieldFocused: Bool
    var onValueChanged: () -> Void
    @EnvironmentObject var timerManager: TimerManager
    
    // Add binding for full-screen mode toggle
    @Binding var isFullScreenMode: Bool
    
    // Add debounce timer
    @State private var saveDebounceTimer: Timer? = nil
    @State private var isAdjusting: Bool = false
    
    var body: some View {
        VStack(alignment: .center, spacing: 3) {
            // Title with help button
            HStack {
                Text("CIRCLE SIZE")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Color.blue.opacity(0.7))
                    .tracking(3)
                
                HelpButton(helpText: "Directly tap the number on the left to manually input size and override the slider.\n\nEnable Full-Screen Touch Mode to make the entire screen a touchable area.")
            }
            .padding(.bottom, 5)
            .frame(maxWidth: .infinity, alignment: .center)
                
            // First add the slider spanning full width
            HStack(spacing: 0) {
                ResponsiveSlider(value: $circleSize, in: 100...500, step: 1) { newValue in
                    // When circleSize changes, update text and trigger callbacks
                    textInputValue = "\(Int(newValue))"
                    onValueChanged()
                    
                    // Mark as adjusting
                    isAdjusting = true
                    
                    // Cancel existing timer
                    saveDebounceTimer?.invalidate()
                    
                    // Create new debounced timer for saving
                    saveDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in    
                        DispatchQueue.global(qos: .userInitiated).async {
                            self.timerManager.saveSettings()
                            
                            // Reset adjusting state
                            DispatchQueue.main.async {
                                self.isAdjusting = false
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            // Add text field and toggle in a horizontal row
            HStack {
                // Manual size input field
                TextField("", text: $textInputValue)
                    .keyboardType(.numberPad)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.black.opacity(0.2), lineWidth: 1)
                    )
                    .frame(width: CGFloat(max(textInputValue.count, 1) * 20 + 28))
                    .focused($isTextFieldFocused)
                    .onChange(of: textInputValue) { newValue in
                        // Update the circleSize binding when the text changes.
                        // The Slider's onChange will handle the saving and callback.
                        if let newSize = Int(newValue) {
                            // Only update if the value is actually different
                            // to prevent potential update loops.
                            if circleSize != CGFloat(newSize) {
                                 circleSize = CGFloat(newSize)
                            }
                        } 
                        // If input is invalid/empty, we don't update circleSize.
                        // The UI will be out of sync until a valid number or slider interaction.
                    }
                
                Spacer()
                
                // Full-screen mode toggle
                HStack {
                    Text("Full-Screen Touch")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                    
                    Toggle("", isOn: $isFullScreenMode)
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: Color.blue))
                        .onChange(of: isFullScreenMode) { newValue in
                            // Save settings when toggle changes
                            timerManager.saveSettings()
                        }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.black.opacity(0.2))
                .cornerRadius(8)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(15)
        .padding(.horizontal, 8) // Reduced to prevent edge cutoff
        .onDisappear {
            // Clean up timer
            saveDebounceTimer?.invalidate()
            saveDebounceTimer = nil
        }
    }
}

// Time unit selection for each timer
enum TimeUnit: String, CaseIterable, Identifiable {
    case seconds = "sec"
    case minutes = "min"
    
    var id: String { self.rawValue }
    
    var multiplier: TimeInterval {
        switch self {
        case .seconds: return 1
        case .minutes: return 60
        }
    }
}

// Cute time picker with unit selection
struct CuteTimePicker: View {
    @Binding var duration: TimeInterval // Use TimeInterval binding directly
    var label: String
    var focus: FocusState<TimerSettingsControl.TimerField?>.Binding
    var timerField: TimerSettingsControl.TimerField

    // Internal state for the wheel picker and unit selection
    @State private var numericValue: Int = 0
    @State private var selectedUnit: TimeUnit = .seconds // Default to seconds initially
    
    // State to track active scrolling - helps improve performance
    @State private var isScrolling: Bool = false
    @State private var scrollDebounceTimer: Timer? = nil
    
    // Track if the binding warm-up has occurred
    @State private var hasWarmedUpBinding: Bool = false

    var body: some View {
        VStack(alignment: .center, spacing: 5) {
            // Timer label without emoji
            Text(label)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white.opacity(0.8))
                .padding(.bottom, 2)

            // Wheel Picker for numeric value
            Picker("", selection: $numericValue) {
                ForEach(0..<100) { number in // Assuming max 99 for simplicity
                    Text("\(number)").tag(number)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 100)
            .background(Color.black.opacity(0.3))
            .cornerRadius(12)
            .onChange(of: numericValue) { _ in
                // Mark that scrolling has started
                isScrolling = true
                
                // Cancel existing timer
                scrollDebounceTimer?.invalidate()
                
                // Set timer to update duration only after scrolling stops
                scrollDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
                    composeAndUpdateDuration()
                    
                    // Delay marking scrolling as finished to ensure UI remains responsive
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isScrolling = false
                    }
                }
            }

            // Unit selection picker with compact style
            Menu {
                ForEach(TimeUnit.allCases) { timeUnit in
                    Button(action: {
                        selectedUnit = timeUnit
                        composeAndUpdateDuration()
                    }) {
                        Text(timeUnit.rawValue.uppercased())
                    }
                }
            } label: {
                Text(selectedUnit.rawValue) // Use selectedUnit state
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(minWidth: 50)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue.opacity(0.6), lineWidth: 1.5)
                    )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.gray.opacity(0.15))
        )
        .onAppear {
            // Initialize picker state when view appears
            decomposeAndUpdateState()
            
            // Perform binding warm-up only once
            if !hasWarmedUpBinding {
                // Delay slightly to ensure view is ready
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    let originalDuration = duration
                    // Tiny change to trigger binding update
                    duration += 0.001 
                    
                    // Change back immediately
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        duration = originalDuration
                        hasWarmedUpBinding = true
                    }
                }
            }
        }
        .onChange(of: duration) { _ in
            // Only update picker state if we're not currently scrolling
            // This prevents feedback loops during active scrolling
            if !isScrolling {
                decomposeAndUpdateState()
            }
        }
        .onDisappear {
            // Clean up timer
            scrollDebounceTimer?.invalidate()
            scrollDebounceTimer = nil
            
            // Reset warm-up flag if needed (optional, depends on desired behavior)
            // hasWarmedUpBinding = false 
        }
    }
    
    // Helper to decompose TimeInterval into internal state (value and unit)
    private func decomposeAndUpdateState() {
        let value = Int(duration)
        if value >= 60 && value % 60 == 0 {
            numericValue = value / 60
            selectedUnit = .minutes
        } else {
            numericValue = value
            selectedUnit = .seconds
        }
    }

    // Helper to compose TimeInterval from internal state and update binding
    private func composeAndUpdateDuration() {
        let newDuration = TimeInterval(numericValue) * selectedUnit.multiplier
        // Only update if value actually changed to reduce redundant updates
        if duration != newDuration {
            duration = newDuration
        }
    }
}

// New component for timer settings
struct TimerSettingsControl: View {
    @Binding var holdDuration: TimeInterval
    @Binding var napDuration: TimeInterval
    @Binding var maxDuration: TimeInterval

    @FocusState private var focusedField: TimerField?
    @EnvironmentObject var timerManager: TimerManager
    
    // Text state for commitment message to prevent constant recalculation
    @State private var commitmentMessage: String = ""
    
    // Debounce timer for message updates
    @State private var messageUpdateTimer: Timer? = nil

    // Warning states (remain the same)
    private var isMaxLessThanNap: Bool {
        maxDuration < napDuration
    }

    private var isHoldTooLong: Bool {
        holdDuration > (maxDuration - napDuration)
    }

    enum TimerField {
        case hold, nap, max
    }
    
    // Helper to format time with appropriate unit
    private func formatTimeUnit(_ duration: TimeInterval) -> String {
        if duration >= 60 && duration.truncatingRemainder(dividingBy: 60) == 0 {
            let minutes = Int(duration / 60)
            return "\(minutes) \(minutes == 1 ? "minute" : "minutes")"
        } else {
            return "\(Int(duration)) \(Int(duration) == 1 ? "second" : "seconds")"
        }
    }
    
    // Update the commitment message text without triggering view updates
    private func updateCommitmentMessage() {
        let holdText = formatTimeUnit(holdDuration)
        let napText = formatTimeUnit(napDuration)
        let maxText = formatTimeUnit(maxDuration)
        
        commitmentMessage = "Release to start a \(holdText) prep countdown → \(napText) nap, with a backup limit at \(maxText)."
    }
    
    // Schedule a delayed update of the commitment message and settings save
    private func scheduleDelayedUpdate() {
        // Cancel any existing timer
        messageUpdateTimer?.invalidate()
        
        // Create a new timer with a reasonable delay
        messageUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            // Use a background queue for the settings save to avoid UI blocking
            DispatchQueue.global(qos: .userInitiated).async {
                self.timerManager.saveSettings()
                
                // Update UI elements back on the main thread
                DispatchQueue.main.async {
                    self.updateCommitmentMessage()
                }
            }
        }
    }

    var body: some View {
        VStack(alignment: .center, spacing: 1) {
            // Title with help button (remains the same)
             HStack {
                 Text("TIMER SETTINGS")
                     .font(.system(size: 14, weight: .bold, design: .rounded))
                     .foregroundColor(Color.blue.opacity(0.7))
                     .tracking(3)
                 
                 HelpButton(helpText: "There will be a lag when first using this because it's caching. This is normal.\n\nRELEASE: When the circle is not being held, this timer counts down. Starts <NAP> timer when done.\n\nNAP: How long your nap will last.\n\nMAX: A failsafe time limit for the entire session. Alarm will sound when this hits 0.")
             }
             .padding(.bottom, 5)
             .frame(maxWidth: .infinity, alignment: .center)

            // Timer grid layout - pass bindings directly
            HStack(alignment: .top, spacing: 8) {
                // Hold Timer (Timer A)
                CuteTimePicker(
                    duration: $holdDuration, // Pass binding
                    label: "RELEASE",
                    focus: $focusedField,
                    timerField: .hold
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(isHoldTooLong ? Color.orange.opacity(0.6) : Color.clear, lineWidth: 2)
                )
                 .onChange(of: holdDuration) { _ in 
                     scheduleDelayedUpdate()
                 } // Schedule delayed save on change

                // Nap Timer (Timer B)
                CuteTimePicker(
                    duration: $napDuration, // Pass binding
                    label: "NAP",
                    focus: $focusedField,
                    timerField: .nap
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(isMaxLessThanNap ? Color.orange.opacity(0.6) : Color.clear, lineWidth: 2)
                )
                .onChange(of: napDuration) { _ in 
                    scheduleDelayedUpdate()
                } // Schedule delayed save on change

                // Max Timer (Timer C)
                CuteTimePicker(
                    duration: $maxDuration, // Pass binding
                    label: "MAX",
                    focus: $focusedField,
                    timerField: .max
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(isMaxLessThanNap ? Color.orange.opacity(0.6) : Color.clear, lineWidth: 2)
                )
                .onChange(of: maxDuration) { _ in 
                    scheduleDelayedUpdate()
                } // Schedule delayed save on change
            }
            
            // Commitment message that explains the timer process - now using pre-computed string
            Text(commitmentMessage)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.top, 12)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle()) // Make sure it has the right hit test shape
                .allowsHitTesting(false) // Don't let it intercept touch events
                .drawingGroup() // Use Metal for better rendering performance

            // Subtle warning messages (remain the same)
             if isMaxLessThanNap || isHoldTooLong {
                 HStack(spacing: 4) {
                     Image(systemName: "exclamationmark.triangle.fill")
                         .font(.system(size: 12))
                     Text(isMaxLessThanNap ? "<MAX> should be greater than <NAP>" : "<Release> + <NAP> should be less than <MAX> ")
                         .font(.system(size: 12, weight: .medium))
                 }
                 .foregroundColor(Color.orange.opacity(0.8))
                 .padding(.top, 8)
             }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(15)
        .padding(.horizontal, 8)
        .onAppear {
            // Initialize the commitment message when the view appears
            updateCommitmentMessage()
        }
        .onDisappear {
            // Clean up timer when view disappears
            messageUpdateTimer?.invalidate()
            messageUpdateTimer = nil
        }
    }
}

// New component for alarm sound selection
struct AlarmSoundSelector: View {
    @Binding var selectedAlarm: AlarmSound
    var onPreview: () -> Void
    @State private var isPlaying: Bool = false
    @EnvironmentObject var timerManager: TimerManager
    @State private var showDocumentPicker = false
    @State private var showMusicPicker = false
    @State private var showingManageSoundsSheet = false
    @State private var musicAuthStatus: MPMediaLibraryAuthorizationStatus = .notDetermined
    @State private var showPermissionAlert = false
    
    var body: some View {
        VStack(alignment: .center, spacing: 3) {
            // Title with help button
            HStack {
                Text("ALARM SOUND")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Color.blue.opacity(0.7))
                    .tracking(3)
                
                HelpButton(helpText: "Choose the sound that will play as a looping alarm when your nap ends. You can select from built-in sounds or add your own custom sounds. \n\n It was not possible for me to add the Apple default alarm sounds.")
            }
            .padding(.bottom, 5)
            .frame(maxWidth: .infinity, alignment: .center)
            
            // Sound selection, import, preview, and manage
            HStack {
                // Dropdown menu for alarm selection
                Menu {
                    // Built-in sounds
                    ForEach(AlarmSound.allCases.filter { $0 != .custom }) { sound in
                        Button(action: {
                            selectedAlarm = sound
                            timerManager.selectedCustomSoundID = nil
                            timerManager.saveSettings()
                        }) {
                            HStack {
                                Text(sound.rawValue)
                                if sound == selectedAlarm && timerManager.selectedCustomSoundID == nil {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    
                    if !timerManager.customSounds.isEmpty {
                        Divider()
                        
                        // Custom sounds section
                        ForEach(timerManager.customSounds) { customSound in
                            Button(action: {
                                selectedAlarm = .custom
                                timerManager.selectedCustomSoundID = customSound.id
                                timerManager.saveSettings()
                            }) {
                                HStack {
                                    Text(customSound.name)
                                    if selectedAlarm == .custom && timerManager.selectedCustomSoundID == customSound.id {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                        
                        Divider()
                        Button(action: {
                            showingManageSoundsSheet = true
                        }) {
                            Label("Manage Sounds...", systemImage: "slider.horizontal.3")
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.8))
                        
                        // Show the name of the selected sound (custom or built-in)
                        if selectedAlarm == .custom, let id = timerManager.selectedCustomSoundID,
                           let customSound = timerManager.customSounds.first(where: { $0.id == id }) {
                            Text(customSound.name)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text(selectedAlarm.rawValue)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.3))
                    )
                }

                // Menu for importing sounds from Files or Apple Music
                Menu {
                    Button(action: importCustomSound) {
                        Label("Import from Files", systemImage: "folder")
                    }

                    Button(action: requestToShowMusicPicker) {
                        HStack {
                            if timerManager.isExportingMusic {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .padding(.trailing, 4)
                            }
                            Label("Import from Apple Music", systemImage: "music.note")
                        }
                    }
                } label: {
                    // Use the folder icon as the menu label with import state
                    HStack(spacing: 4) {
                        if timerManager.isExportingMusic {
                            Image(systemName: "arrow.down.circle")
                                .font(.system(size: 18))
                                .foregroundColor(.white.opacity(0.7))
                        } else {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 18))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        if timerManager.isExportingMusic {
                            Text("Importing...")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                }

                // Preview/Stop toggle button
                Button(action: {
                    isPlaying.toggle()
                    if isPlaying {
                        timerManager.playAlarmSound()
                    } else {
                        timerManager.stopAlarmSound()
                    }
                }) {
                    HStack(spacing: 7) {
                        Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                            .font(.system(size: 16))
                        Text(isPlaying ? "Stop" : "Test")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isPlaying ? Color.red.opacity(0.6) : Color.purple.opacity(0.6))
                    )
                    .foregroundColor(.white)
                }
            }
                
 
                

        }
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(15)
        .padding(.horizontal, 8)
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker(selectedFileURL: onFileSelected)
        }
        .sheet(isPresented: $showMusicPicker, onDismiss: checkMusicPermission) {
            switch musicAuthStatus {
            case .authorized:
                MusicPicker { mediaItem in
                    // TODO: Implement logic in TimerManager to handle selected mediaItem
                    print("Selected music item: \(mediaItem.title ?? "Unknown Title")")
                    // Example: timerManager.addMusicSound(item: mediaItem)
                    self.timerManager.addMusicSound(item: mediaItem)
                }
            case .denied, .restricted:
                Text("Music Library access is required. Please enable it in Settings.")
                    .padding()
                    .onAppear { 
                        showMusicPicker = false 
                        showPermissionAlert = true
                    }
            case .notDetermined:
                Text("Requesting Music Library access...")
                    .onAppear { 
                        showMusicPicker = false
                        checkMusicPermission()
                    }
            @unknown default:
                Text("Unknown music library authorization status.")
                    .onAppear { showMusicPicker = false }
            }
        }
        .alert("Permission Required", isPresented: $showPermissionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("SnoozeFuse needs access to your Music Library to select alarm sounds. Please enable access in Settings.")
        }
        .sheet(isPresented: $showingManageSoundsSheet) {
            // Present the new management view
            ManageSoundsView()
                .environmentObject(timerManager) // Pass TimerManager down
        }
        // Add onAppear handler to load custom sounds only when this view appears
        .onAppear {
            // Load custom sounds when the selector is shown
            timerManager.loadCustomSounds()
        }
    }

    private func checkMusicPermission() {
        let currentStatus = MPMediaLibrary.authorizationStatus()
        musicAuthStatus = currentStatus

        switch currentStatus {
        case .notDetermined:
            MPMediaLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    musicAuthStatus = status
                    if status == .authorized {
                        // If granted, now we *can* set showMusicPicker to true
                        // This logic might need refinement depending on user flow.
                        // For now, assume the user taps the menu item *after* this check.
                    } else {
                        // If denied, trigger the alert
                        showPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            // If already denied/restricted, prepare to show alert
            // The actual alert showing is triggered by the menu action attempt.
            break // State is already set
        case .authorized:
            // Already authorized, nothing more to do here
            break
        @unknown default:
            print("Unknown Music Library authorization status encountered.")
        }
    }
    
    private func requestToShowMusicPicker() {
        checkMusicPermission()
        
        DispatchQueue.main.async {
             switch musicAuthStatus {
             case .authorized:
                 showMusicPicker = true
             case .denied, .restricted:
                 showPermissionAlert = true
             case .notDetermined:
                 MPMediaLibrary.requestAuthorization { status in
                    DispatchQueue.main.async {
                        musicAuthStatus = status
                        if status == .authorized {
                            showMusicPicker = true
                        } else {
                            showPermissionAlert = true
                        }
                    }
                 }
             @unknown default:
                 print("Cannot show music picker due to unknown auth status.")
             }
        }
    }
    
    private func importCustomSound() {
        showDocumentPicker = true
    }
    
    private func onFileSelected(_ url: URL) {
        // Set up for new sound using selected file
        let filename = url.lastPathComponent
        timerManager.addCustomSound(name: filename, fileURL: url)
    }
}

// Document Picker for selecting audio files
struct DocumentPicker: UIViewControllerRepresentable {
    var selectedFileURL: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Define the types of audio files we want to allow
        let supportedTypes: [UTType] = [.audio, .mp3, .wav]
        
        // Create a document picker with these types
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            // Start accessing the security-scoped resource
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            
            // Call the callback with the selected URL
            parent.selectedFileURL(url)
            
            // Stop accessing the security-scoped resource
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
    }
}

// Music Picker for selecting songs from Apple Music library
struct MusicPicker: UIViewControllerRepresentable {
    // Callback to pass the selected media item
    var didPickMediaItem: (MPMediaItem) -> Void

    func makeUIViewController(context: Context) -> MPMediaPickerController {
        // Configure the picker for music
        let picker = MPMediaPickerController(mediaTypes: .music)
        picker.allowsPickingMultipleItems = false
        picker.showsCloudItems = false  // Or false, depending on desired behavior
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: MPMediaPickerController, context: Context) {
        // No update needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MPMediaPickerControllerDelegate {
        let parent: MusicPicker

        init(_ parent: MusicPicker) {
            self.parent = parent
        }

        // Delegate method called when item(s) are picked
        func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
            // Get the first item (since multiple selection is off)
            if let mediaItem = mediaItemCollection.items.first {
                parent.didPickMediaItem(mediaItem)
            }
            mediaPicker.dismiss(animated: true)
        }

        // Delegate method called when the picker is cancelled
        func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
            mediaPicker.dismiss(animated: true)
        }
    }
}

// View for managing (deleting) custom sounds
struct ManageSoundsView: View {
    @EnvironmentObject var timerManager: TimerManager
    @Environment(\.dismiss) var dismiss // To close the sheet

    var body: some View {
        NavigationView { // Use NavigationView for title and Done button
            List {
                // Section for sounds imported from files
                Section("Imported Sounds") {
                    // Check if the array exists and is not empty
                    if !timerManager.customSounds.isEmpty {
                        ForEach(timerManager.customSounds) { sound in
                            Text(sound.name)
                        }
                        .onDelete(perform: deleteItems)
                    } else {
                        Text("No imported sounds yet.")
                            .foregroundColor(.secondary)
                    }
                }
                
                // TODO: Add section for Apple Music sounds later?
            }
            .navigationTitle("Manage Sounds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .listStyle(InsetGroupedListStyle()) // Use a nice list style
        }
    }

    // Function to handle deletion from the list's swipe action
    private func deleteItems(at offsets: IndexSet) {
        // Get the IDs of the sounds to delete based on the offsets
        let idsToDelete = offsets.map { timerManager.customSounds[$0].id }
        
        // Call TimerManager to remove them
        for id in idsToDelete {
            timerManager.removeCustomSound(id: id)
        }
    }
}

struct SettingsScreen: View {
    @EnvironmentObject var timerManager: TimerManager
    @State private var showPreview = false
    @State private var previewTimer: Timer?
    @State private var textInputValue: String = ""
    @FocusState private var isAnyFieldFocused: Bool
    @State private var showNapScreen = false  // New state for showing nap screen
    @ObservedObject private var notificationManager = NotificationManager.shared
    
    var body: some View {
        ZStack {
            NavigationView {
                ZStack {
                    // Background
                    Color.black.opacity(0.9).ignoresSafeArea()
                    
                    // Dismiss keyboard when tapping background
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            isAnyFieldFocused = false
                            hideKeyboard()
                        }
                    
                    // ScrollView with better spacing
                    ScrollView {
                        VStack(spacing: 10) {
                            // App title at the top - now with pixel animation!
                            Image("logotransparent")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 132, height: 66)
                                .scaleEffect(0.8)
                                .drawingGroup() // Use Metal rendering for better performance
                                .modifier(PixelateEffect(isActive: timerManager.isLogoAnimating))
                                .onTapGesture {
                                    if !timerManager.isLogoAnimating {
                                        timerManager.isLogoAnimating = true
                                        // Play haptic feedback
                                        HapticManager.shared.trigger()
                                        // Reset animation flag after animation completes
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                            timerManager.isLogoAnimating = false
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, -8) // topleft corner
                                .padding(.top, -33) // make it go into the ui status boundary
                                .padding(.bottom, 0)
                            
                            // Notification permission warning - only show if not hidden from main settings
                            if !notificationManager.isHiddenFromMainSettings {
                                NotificationPermissionWarning()
                            }
                            
                            // Circle size control - now with fullscreen mode toggle
                            CircleSizeControl(
                                circleSize: $timerManager.circleSize,
                                textInputValue: $textInputValue,
                                onValueChanged: showPreviewBriefly,
                                isFullScreenMode: $timerManager.isFullScreenMode
                            )
                            
                            // Timer settings
                            TimerSettingsControl(
                                holdDuration: $timerManager.holdDuration,
                                napDuration: $timerManager.napDuration,
                                maxDuration: $timerManager.maxDuration
                            )
                            
                            // Alarm sound selection
                            AlarmSoundSelector(
                                selectedAlarm: $timerManager.selectedAlarmSound,
                                onPreview: timerManager.previewAlarmSound
                            )
                            
                            // Start button
                            bottomButtonBar
                                .padding(.top, 10)
                            
                            // Add extra padding at the bottom for better scrolling
                            Spacer()
                                .frame(height: 20)
                        }
                        .padding(.horizontal, 5)
                    }
                    .scrollIndicators(.hidden) // Hide scroll indicators for cleaner look
                    .simultaneousGesture(DragGesture().onChanged { _ in }) // Add empty gesture to ensure proper propagation
                    .focusable(false) // Prevent focus to ensure scrolling takes priority
                    .focused($isAnyFieldFocused)
                    .allowsHitTesting(true) // Explicitly allow hit testing
                    
                    // Global keyboard dismissal button and loading overlay
                    VStack {
                        Spacer()
                        if isAnyFieldFocused {
                            Button(action: {
                                isAnyFieldFocused = false
                                hideKeyboard()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 32))
                                    Text("CONFIRM")
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 20)
                                .frame(minWidth: 300)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "66BB6A"), Color(hex: "43A047")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(30)
                                .shadow(color: Color(hex: "43A047").opacity(0.7), radius: 12, x: 0, y: 6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 30)
                                        .stroke(Color.white.opacity(0.5), lineWidth: 2)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 30)
                                        .stroke(Color.green, lineWidth: 3)
                                        .blur(radius: 3)
                                        .opacity(0.7)
                                )
                            }
                            .padding(.bottom, 40)
                            .padding(.horizontal, 20)
                            .transition(.scale.combined(with: .opacity))
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isAnyFieldFocused)
                        }
                    }
                }
                .navigationBarHidden(true)
            }
            
            // Completely separate preview overlay that doesn't affect layout
            if showPreview {
                CirclePreviewOverlay(
                    circleSize: timerManager.circleSize,
                    isVisible: $showPreview
                )
            }
        }
        .onAppear {
            textInputValue = "\(Int(timerManager.circleSize))"
        }
    }
    
    private var bottomButtonBar: some View {
        VStack {
            
            // Circular Start button
            Button(action: {
                showNapScreen = true
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 160, height: 160)
                        .shadow(color: Color.blue.opacity(0.5), radius: 10, x: 0, y: 5)
                    
                    VStack(spacing: 5) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 50))
                        Text("Start")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white)
                }
            }
                        // More Settings button now links to Advanced Settings
            NavigationLink(destination: AdvancedSettingsScreen()) {
                VStack(spacing: 8) {
                    Image(systemName: "gearshape.2.fill")
                        .font(.system(size: 20))
                    Text("Advanced")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 100, height: 70)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.gray.opacity(0.2))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                )
            }
            
            Spacer()
        }
        .padding(.horizontal, 25)
        .padding(.bottom, 30)
        .fullScreenCover(isPresented: $showNapScreen) {
            NapScreen()
                .environmentObject(timerManager)
        }
    }
    
    private func showPreviewBriefly() {
        // Cancel existing timer if any
        previewTimer?.invalidate()
        
        // Show preview
        showPreview = true
        
        // Set timer to hide preview after 1 second for better visibility
        previewTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            withAnimation(.easeOut(duration: 0.5)) {
                showPreview = false
            }
        }
    }
    
    // Helper function to hide keyboard
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// Completely separate preview overlay structure
struct CirclePreviewOverlay: View {
    let circleSize: CGFloat
    @Binding var isVisible: Bool
    
    var body: some View {
        GeometryReader { fullScreen in
            ZStack {
                // Overlay background with tap to dismiss
                Color.black.opacity(0.8)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.3)) {
                            isVisible = false
                        }
                    }
                
                // Circle display
                ZStack {
                    // Real-sized circle
                    CircleView(size: circleSize)
                        // Don't constrain the size at all
                        .frame(width: circleSize, height: circleSize)
                        .position(
                            x: fullScreen.size.width / 2,
                            y: fullScreen.size.height / 2 - 50
                        )
                    
                    // Size indicator
                    Text("HOLD CIRCLE SIZE: \(Int(circleSize))")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(2)
                        .padding(.vertical, 18)
                        .padding(.horizontal, 30)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.blue.opacity(0.3))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.blue.opacity(0.5), lineWidth: 1.5)
                                )
                        )
                        .position(
                            x: fullScreen.size.width / 2,
                            y: min(fullScreen.size.height - 100, fullScreen.size.height / 2 + circleSize / 2 + 40)
                        )
                }
            }
        }
        .transition(.opacity)
        .allowsHitTesting(true) // Explicitly allow hit testing
    }
}

// Helper extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Custom Slider with immediate response
struct ResponsiveSlider: View {
    @Binding var value: CGFloat
    let range: ClosedRange<CGFloat>
    let step: CGFloat
    let onValueChange: (CGFloat) -> Void
    
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    
    init(value: Binding<CGFloat>, in range: ClosedRange<CGFloat>, step: CGFloat = 1, onValueChange: @escaping (CGFloat) -> Void = { _ in }) {
        self._value = value
        self.range = range
        self.step = step
        self.onValueChange = onValueChange
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track background
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.3))
                    .frame(height: 6)
                
                // Filled portion
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue)
                    .frame(width: position(for: value, in: geometry.size.width), height: 6)
                
                // Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
                    .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                    .offset(x: position(for: value, in: geometry.size.width) - 12)
            }
            .frame(height: 44) // Larger hit area
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        isDragging = true
                        let width = geometry.size.width
                        let dragX = min(max(0, gesture.location.x), width)
                        let percentage = dragX / width
                        let newValue = range.lowerBound + (range.upperBound - range.lowerBound) * percentage
                        
                        // Apply stepping if needed
                        if step > 0 {
                            let steppedValue = round(newValue / step) * step
                            value = steppedValue
                        } else {
                            value = newValue
                        }
                        
                        // Call the callback
                        onValueChange(value)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
        }
        .frame(height: 44) // Fixed height for the slider
    }
    
    // Calculate position for a given value
    private func position(for value: CGFloat, in width: CGFloat) -> CGFloat {
        let rangeDistance = range.upperBound - range.lowerBound
        let percentage = (value - range.lowerBound) / rangeDistance
        return width * percentage
    }
}

#Preview {
    SettingsScreen()
        .environmentObject(TimerManager())
        .preferredColorScheme(.dark)
}