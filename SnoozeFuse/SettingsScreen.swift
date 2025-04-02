import SwiftUI
import UniformTypeIdentifiers
import UserNotifications

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
        // Sequence the animations for a smoother flow
        
        // Start with glow and subtle scale
        withAnimation(.easeIn(duration: 0.3)) {
            glowOpacity = 0.7
            glowScale = 1.2
            bounceScale = 1.1
        }
        
        // Start hue rotation
        withAnimation(.linear(duration: 0.8).repeatCount(2, autoreverses: true)) {
            hueRotation = 30
        }
        
        // Then continue with more dramatic effects
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // Continue rotation smoothly
            withAnimation(.easeInOut(duration: 0.8)) {
                rotationAngle = 360
            }
            
            // Larger bounce
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                bounceScale = 1.3
                glowOpacity = 0.9
                glowScale = 1.4
            }
            
            // Smooth return to normal size
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    bounceScale = 0.9
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        bounceScale = 1.0
                    }
                    
                    // Fade out effects gradually
                    withAnimation(.easeOut(duration: 0.8)) {
                        glowOpacity = 0.0
                        glowScale = 2.0
                    }
                }
            }
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
                .foregroundColor(.white.opacity(0.6))
        }
        .alert("Tips", isPresented: $showingHelp) {
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
    
    var body: some View {
        VStack(alignment: .center, spacing: 3) {
            // Title with help button
            HStack {
                Text("CIRCLE SIZE")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Color.blue.opacity(0.7))
                    .tracking(3)
                
                HelpButton(helpText: "Directly tap the number on the left to manually input size and override the slider.")
            }
            .padding(.bottom, 5)
            .frame(maxWidth: .infinity, alignment: .center)
                
            HStack(spacing: 0) {
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
                        if let newSize = Int(newValue) {
                            circleSize = CGFloat(newSize)
                            onValueChanged()
                            timerManager.saveSettings()
                        }
                    }
                HStack(spacing: 0) {
                    Slider(value: $circleSize, in: 100...500, step: 1)
                        .accentColor(.blue)
                        .onChange(of: circleSize) { _ in
                            textInputValue = "\(Int(circleSize))"
                            onValueChanged()
                            timerManager.saveSettings()
                        }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(15)
        .padding(.horizontal, 8) // Reduced to prevent edge cutoff
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
    @Binding var value: String
    @Binding var unit: TimeUnit
    var label: String
    var focus: FocusState<TimerSettingsControl.TimerField?>.Binding
    var timerField: TimerSettingsControl.TimerField
    var updateAction: () -> Void
    
    // Internal state for the wheel picker
    @State private var numericValue: Int = 0
    
    var body: some View {
        VStack(alignment: .center, spacing: 5) {
            // Timer label without emoji
            Text(label)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white.opacity(0.8))
                .padding(.bottom, 2)
            
            // Replace TextField with wheel Picker
            Picker("", selection: $numericValue) {
                ForEach(0..<100) { number in
                    Text("\(number)").tag(number)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 100)
            .background(Color.black.opacity(0.3))
            .cornerRadius(12)
            .onChange(of: numericValue) { newValue in
                value = "\(newValue)"
                updateAction()
            }
            .onAppear {
                // Initialize picker with current value
                numericValue = Int(value) ?? 0
            }
            
            // Unit selection picker with compact style
            Menu {
                ForEach(TimeUnit.allCases) { timeUnit in
                    Button(action: {
                        unit = timeUnit
                        updateAction()
                    }) {
                        Text(timeUnit.rawValue.uppercased())
                    }
                }
            } label: {
                Text(unit.rawValue)
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
    }
}

// New component for timer settings
struct TimerSettingsControl: View {
    @Binding var holdDuration: TimeInterval
    @Binding var napDuration: TimeInterval
    @Binding var maxDuration: TimeInterval
    
    @State private var holdTime: String = "5"
    @State private var napTime: String = "1"
    @State private var maxTime: String = "2"
    
    @State private var holdUnit: TimeUnit = .seconds // Default seconds
    @State private var napUnit: TimeUnit = .minutes  // Default minutes
    @State private var maxUnit: TimeUnit = .minutes  // Default minutes
    
    @FocusState private var focusedField: TimerField?
    @EnvironmentObject var timerManager: TimerManager
    
    // Warning states
    private var isMaxLessThanNap: Bool {
        maxDuration < napDuration
    }
    
    private var isHoldTooLong: Bool {
        holdDuration > (maxDuration - napDuration)
    }
    
    enum TimerField {
        case hold, nap, max
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 1) {
            // Title with help button
            HStack {
                Text("TIMER SETTINGS")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Color.blue.opacity(0.7))
                    .tracking(3)
                
                HelpButton(helpText: "RELEASE: usually a small number. When the circle is not being held, this timer counts down. Starts <NAP> timer when done.\n\nNAP: How long your nap will last.\n\nMAX: A failsafe time limit for the entire session.")
            }
            .padding(.bottom, 5)
            .frame(maxWidth: .infinity, alignment: .center)
            
            // Timer grid layout - reduced spacings to prevent edge cutoff
            HStack(alignment: .top, spacing: 8) {
                // Hold Timer (Timer A)
                CuteTimePicker(
                    value: $holdTime,
                    unit: $holdUnit,
                    label: "RELEASE",
                    focus: $focusedField,
                    timerField: .hold,
                    updateAction: updateHoldTimer
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(isHoldTooLong ? Color.orange.opacity(0.6) : Color.clear, lineWidth: 2)
                )
                
                // Nap Timer (Timer B)
                CuteTimePicker(
                    value: $napTime,
                    unit: $napUnit,
                    label: "NAP",
                    focus: $focusedField,
                    timerField: .nap,
                    updateAction: updateNapTimer
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(isMaxLessThanNap ? Color.orange.opacity(0.6) : Color.clear, lineWidth: 2)
                )
                
                // Max Timer (Timer C)
                CuteTimePicker(
                    value: $maxTime,
                    unit: $maxUnit,
                    label: "MAX",
                    focus: $focusedField,
                    timerField: .max,
                    updateAction: updateMaxTimer
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(isMaxLessThanNap ? Color.orange.opacity(0.6) : Color.clear, lineWidth: 2)
                )
            }
            
            // Subtle warning messages
            if isMaxLessThanNap || isHoldTooLong {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                    Text(isMaxLessThanNap ? "<Max> should be greater than <Nap> (add autoassist later, this just for debug)" : "<Release> + <Nap> should be less than <Max> ")
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
            // Initialize units and values
            setupInitialValues()
        }
    }
    
    // Setup initial values based on the existing durations
    private func setupInitialValues() {
        let hold = Int(holdDuration)
        if hold >= 60 && hold % 60 == 0 {
            holdUnit = .minutes
            holdTime = "\(hold / 60)"
        } else {
            holdUnit = .seconds
            holdTime = "\(hold)"
        }
        
        let nap = Int(napDuration)
        if nap >= 60 && nap % 60 == 0 {
            napUnit = .minutes
            napTime = "\(nap / 60)"
        } else {
            napUnit = .seconds
            napTime = "\(nap)"
        }
        
        let max = Int(maxDuration)
        if max >= 60 && max % 60 == 0 {
            maxUnit = .minutes
            maxTime = "\(max / 60)"
        } else {
            maxUnit = .seconds
            maxTime = "\(max)"
        }
    }
    
    private func updateHoldTimer() {
        let value = Int(holdTime) ?? 0
        holdDuration = TimeInterval(value) * holdUnit.multiplier
        // Save settings after update
        timerManager.saveSettings()
    }
    
    private func updateNapTimer() {
        let value = Int(napTime) ?? 0
        napDuration = TimeInterval(value) * napUnit.multiplier
        // Save settings after update
        timerManager.saveSettings()
    }
    
    private func updateMaxTimer() {
        let value = Int(maxTime) ?? 0
        maxDuration = TimeInterval(value) * maxUnit.multiplier
        // Save settings after update
        timerManager.saveSettings()
    }
    
    // Helper function to format time with unit
    private func formatTimeWithUnit(_ time: String, _ unit: TimeUnit) -> String {
        if let value = Int(time) {
            if value == 1 {
                return "1 " + unit.rawValue.dropLast() // Remove 's' for singular
            }
            return "\(value) " + unit.rawValue
        }
        return "0 " + unit.rawValue
    }
}

// New component for alarm sound selection
struct AlarmSoundSelector: View {
    @Binding var selectedAlarm: AlarmSound
    var onPreview: () -> Void
    @State private var isPlaying: Bool = false
    @EnvironmentObject var timerManager: TimerManager
    @State private var showDocumentPicker = false
    @State private var showingDeleteConfirmation = false
    @State private var soundToDelete: UUID? = nil
    
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
            
            // Sound selection and preview
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
                            .swipeActions {
                                Button(role: .destructive) {
                                    soundToDelete = customSound.id
                                    showingDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        
                        // Delete option menu section
                        Menu {
                            ForEach(timerManager.customSounds) { customSound in
                                Button(role: .destructive, action: {
                                    soundToDelete = customSound.id
                                    showingDeleteConfirmation = true
                                }) {
                                    Label(customSound.name, systemImage: "trash")
                                }
                            }
                        } label: {
                            Label("Remove Custom Sounds", systemImage: "trash")
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
                // Just a folder icon for adding custom sounds
                Button(action: {
                    showDocumentPicker = true
                }) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                }
                .buttonStyle(PlainButtonStyle())
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
            DocumentPicker(selectedFileURL: { url in
                timerManager.addCustomSound(from: url)
            })
        }
        .alert("Delete Custom Sound", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let id = soundToDelete {
                    timerManager.removeCustomSound(id: id)
                }
            }
        } message: {
            Text("Are you sure you want to delete this custom sound?")
        }
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
                            
                            // Circle size control
                            CircleSizeControl(
                                circleSize: $timerManager.circleSize,
                                textInputValue: $textInputValue,
                                onValueChanged: showPreviewBriefly
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
                        }
                        .padding(.horizontal, 5)
                    }
                    .focused($isAnyFieldFocused)
                    
                    // Global keyboard dismissal button - now green and cuter
                    VStack {
                        Spacer()
                        if isAnyFieldFocused {
                            Button(action: {
                                isAnyFieldFocused = false
                                hideKeyboard()
                            }) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18))
                                    Text("Confirm")
                                        .font(.system(size: 18, weight: .medium, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 14)
                                .frame(width: 130)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "66BB6A"), Color(hex: "43A047")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(25)
                                .shadow(color: Color(hex: "43A047").opacity(0.5), radius: 8, x: 0, y: 4)
                            }
                            .padding(.bottom, 25)
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
        .zIndex(999) // Ensure it's above everything
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

#Preview {
    SettingsScreen()
        .environmentObject(TimerManager())
        .preferredColorScheme(.dark)
}
