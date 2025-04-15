import SwiftUI

struct CircularBackButton: View {
    var action: () -> Void
    @State private var isConfirming = false
    @State private var confirmationTimer: Timer?
    
    var body: some View {
        Button(action: {
            if isConfirming {
                action()
                isConfirming = false
                confirmationTimer?.invalidate()
            } else {
                isConfirming = true
                confirmationTimer?.invalidate()
                confirmationTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                    isConfirming = false
                }
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(isConfirming ? Color.red.opacity(0.5) : Color.blue.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isConfirming ? Color.red.opacity(0.7) : Color.blue.opacity(0.7),
                                lineWidth: 1
                            )
                    )
                    .frame(width: 95, height: 70)
                
                VStack(spacing: 5) {
                    Image(systemName: "chevron.left.2")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white)
                    Text(isConfirming ? "Confirm" : "Back")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NapScreen: View {
    // MARK: - Environment
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var timerManager: TimerManager
    
    // Using shared instances instead of environment objects
    private var hapticManager = HapticManager.shared
    private var orientationManager = OrientationManager.shared
    private var audioPlayerManager = AudioPlayerManager.shared
    
    // MARK: - State
    
    @State private var circlePosition: CGPoint? = nil
    @State private var isPressed: Bool = false
    @State private var showPositionMessage: Bool = true
    @State private var showSleepScreen: Bool = false
    @State private var napFinished: Bool = false
    @State private var isFirstInteraction: Bool = true
    @State private var wasInBackground: Bool = false
    
    // Touch line state
    @State private var currentTouchPosition: CGPoint? = nil
    @State private var isShowingTouchLine: Bool = false
    
    // Add animation state properties
    @State private var showRippleEffect: Bool = false
    @State private var showResetAnimation: Bool = false
    @State private var touchFeedbackPosition: CGPoint? = nil
    @State private var showTouchFeedback: Bool = false
    
    // MARK: - Actions
    
    func resetPlacementState() {
        showPositionMessage = true
        circlePosition = nil
        
        // Stop the holdTimer to prevent it from counting down during "tap anywhere" state
        timerManager.stopHoldTimer()
        // Stop the maxTimer as well
        timerManager.stopMaxTimer()
        
        // Reset the timer values to their original durations
        timerManager.holdTimer = timerManager.holdDuration
        timerManager.maxTimer = timerManager.maxDuration
        
        // Ensure we're not tracking pressed state anymore
        isPressed = false
        
        // Reset the first interaction flag
        isFirstInteraction = true
        
        // Show reset animation if enabled
        if timerManager.showMiniAnimations {
            showResetAnimation = true
            // Hide it after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                showResetAnimation = false
            }
        }
    }
    
    private func parseTimerComponents(_ text: String) -> [TimerComponent] {
        var components: [TimerComponent] = []
        let parts = text.split(separator: " ")
        
        for part in parts {
            let partString = String(part)
            let numberEndIndex = partString.firstIndex(where: { !$0.isNumber }) ?? partString.endIndex
            let number = String(partString[..<numberEndIndex])
            let unit = String(partString[numberEndIndex...])
            components.append(TimerComponent(number: number, unit: unit))
        }
        
        return components
    }
    
    struct TimerComponent {
        let number: String
        let unit: String
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                        Color(red: 0.05, green: 0.05, blue: 0.1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Main content
                ZStack {
                    // Timer display at top
                    VStack {
                        VStack(spacing: 0) {
                            Text("RELEASE TIMER")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(Color.blue.opacity(0.8))
                                .tracking(3)
                                .padding(.bottom, 5)
                            
                            // Timer display with big numbers, small units
                            // Force consistent format by rounding to the nearest second to avoid constantly switching
                            let holdTimerValue = floor(timerManager.holdTimer)
                            let timerText = timerManager.formatTime(holdTimerValue)
                            let components = parseTimerComponents(timerText)
                            VStack(spacing: 0) {
                                HStack(spacing: 1) {
                                    ForEach(components, id: \.number) { component in
                                        Text(component.number)
                                            .font(.system(size: 62, weight: .bold, design: .monospaced))
                                            .foregroundColor(isPressed ? Color.pink.opacity(0.9) : .white)
                                        
                                        Text(component.unit)
                                            .font(.system(size: 24, weight: .medium, design: .monospaced))
                                            .foregroundColor(isPressed ? Color.pink.opacity(0.7) : .white.opacity(0.8))
                                            .baselineOffset(-8)
                                            .padding(.trailing, 4)
                                    }
                                }
                            }
                            .shadow(color: .blue.opacity(0.5), radius: 2, x: 0, y: 0)
                        }
                        .padding(.top, 60)
                        .padding(.bottom, 10)
                        
                        // Always show session timer info - But only Max Timer now, moved Nap Duration to top right
                        HStack(spacing: 35) {
                            VStack(spacing: 2) {
                                Text("MAX TIMER")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.purple.opacity(0.8))
                                    .tracking(1)
                                
                                // Force consistent format by rounding to the nearest second to avoid constantly switching
                                let maxTimerValue = floor(timerManager.maxTimer)
                                // Use the same format consistently based on the original max duration
                                let maxTimerText = timerManager.maxDuration >= 60 ?
                                    "\(Int(maxTimerValue / 60))min \(Int(maxTimerValue.truncatingRemainder(dividingBy: 60)))sec" :
                                    "\(Int(maxTimerValue))sec"
                                let maxComponents = parseTimerComponents(maxTimerText)
                                HStack(spacing: 0) {
                                    ForEach(maxComponents, id: \.number) { component in
                                        Text(component.number)
                                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                                            .foregroundColor(.white.opacity(0.9))
                                        
                                        Text(component.unit)
                                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                                            .foregroundColor(.white.opacity(0.7))
                                            .baselineOffset(-2)
                                            .padding(.trailing, 2)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.black.opacity(0.3))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        
                        Spacer()
                    }
                    .zIndex(0)
                    
                    // Add "Up Next" nap duration in top right corner
                    VStack {
                        HStack {
                            Spacer()
                            
                            VStack(spacing: 4) {
                                Text("UP NEXT:")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.blue.opacity(0.6))
                                    .tracking(0.5)
                                
                                let napTimerText = timerManager.formatTime(timerManager.napDuration)
                                let napComponents = parseTimerComponents(napTimerText)
                                HStack(spacing: 0) {
                                    ForEach(napComponents, id: \.number) { component in
                                        Text(component.number)
                                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                                            .foregroundColor(.white.opacity(0.85))
                                        
                                        Text(component.unit)
                                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                                            .foregroundColor(.white.opacity(0.7))
                                            .baselineOffset(-2)
                                            .padding(.trailing, 2)
                                    }
                                }
                                
                                Text("NAP DURATION")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.blue.opacity(0.7))
                                    .tracking(1)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.black.opacity(0.25))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.blue.opacity(0.25), lineWidth: 1)
                                    )
                            )
                            .padding(.trailing, -5)
                            .padding(.top, -5)
                        }
                        
                        Spacer()
                    }
                    .zIndex(1)
                    
                    // Circle positioned at tap location
                    if let position = circlePosition {
                        ZStack {
                            // Regular Circle View (always visible for visual feedback)
                            CircleView(
                                size: timerManager.circleSize,
                                isPressed: isPressed,
                                showStatusText: true,
                                showInitialInstructions: timerManager.maxTimer == timerManager.maxDuration,
                                normalColor: .blue,
                                pressedColor: .purple,
                                timerValue: timerManager.formatTime(timerManager.holdTimer),
                                showTimer: true,
                                timerColor: .white.opacity(0.9),
                                timerProgress: timerManager.maxTimer / timerManager.maxDuration,
                                progressColor: Color.purple.opacity(0.8),
                                releaseTimerProgress: timerManager.holdTimer / timerManager.holdDuration,
                                showArcs: timerManager.showTimerArcs,
                                isFullScreenMode: timerManager.isFullScreenMode
                            )
                            
                            // Ripple effect when pressed
                            if showRippleEffect && timerManager.showRippleEffects {
                                RippleEffect(size: timerManager.circleSize * 1.2, color: .blue)
                            }
                        }
                        .overlay(
                            // Only use the circle touch handler when not in full-screen mode
                            Group {
                                if !timerManager.isFullScreenMode {
                                    MultiTouchHandler(
                                        onTouchesChanged: { touchingCircle in
                                            if touchingCircle != isPressed {
                                                isPressed = touchingCircle
                                                if touchingCircle {
                                                    // User is pressing the circle
                                                    
                                                    // Show ripple effect when circle is pressed
                                                    if timerManager.showRippleEffects {
                                                        showRippleEffect = true
                                                        // Hide after animation completes
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                                            showRippleEffect = false
                                                        }
                                                    }
                                                    
                                                    // If this is the first interaction since placing the circle,
                                                    // start the max timer when user first holds down
                                                    if isFirstInteraction {
                                                        timerManager.startMaxTimer()
                                                        isFirstInteraction = false
                                                    }
                                                    
                                                    // Stop the hold timer when holding
                                                    timerManager.stopHoldTimer()
                                                    
                                                    // Immediately reset hold timer to original duration when pressed
                                                    timerManager.holdTimer = timerManager.holdDuration
                                                    
                                                    // Start the haptic BPM pulse if enabled
                                                    if hapticManager.isBPMPulseEnabled && hapticManager.isHapticEnabled {
                                                        hapticManager.startBPMPulse()
                                                    }
                                                } else {
                                                    // User has released the circle
                                                    // Start/resume the hold timer
                                                    timerManager.startHoldTimer()
                                                    
                                                    // Stop the BPM pulse when circle is released
                                                    hapticManager.stopBPMPulse()
                                                }
                                            }
                                        },
                                        circleRadius: timerManager.circleSize / 2
                                    )
                                }
                            }
                        )
                        .position(position)
                        .zIndex(1)
                    }
                    
                    // Initial message
                    if showPositionMessage {
                        // This transparent layer captures taps
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture { location in
                                showPositionMessage = false
                                circlePosition = location
                                
                                // Reset timers but DON'T start them yet
                                timerManager.resetTimers()
                                
                                // Reset first interaction flag
                                isFirstInteraction = true
                            }
                            .zIndex(3)
                        
                        // Position the "tap anywhere" message in the center of the screen
                        GeometryReader { geometry in
                            VStack {
                                Spacer()
                                
                                VStack(spacing: 10) {
                                    Text("Tap Anywhere")
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .tracking(1.5)
                                        .shadow(color: .blue.opacity(0.6), radius: 3, x: 0, y: 1)
                                    
                                    Text("to position your circle")
                                        .font(.system(size: 18, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.9))
                                        .tracking(1)
                                    
                                    Image(systemName: "hand.tap.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.white)
                                        .padding(.top, 6)
                                        .shadow(color: .white.opacity(0.6), radius: 4, x: 0, y: 0)
                                        
                                    // Add full-screen mode indicator text
                                    if timerManager.isFullScreenMode {
                                        Text("Full-Screen Touch Mode is ON")
                                            .font(.system(size: 15, weight: .medium, design: .rounded))
                                            .foregroundColor(.pink.opacity(0.9))
                                            .padding(.top, 5)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 5)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.black.opacity(0.3))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .stroke(Color.pink.opacity(0.5), lineWidth: 1)
                                                    )
                                            )
                                    }
                                }
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                                .padding(.vertical, 25)
                                .background(
                                    ZStack {
                                        // Use transparent layered circles instead of gradients
                                        RoundedRectangle(cornerRadius: 22)
                                            .fill(Color.black.opacity(0.2))
                                        
                                        // Just keep small decorative dots for subtle texture
                                        Circle()
                                            .fill(Color.white.opacity(0.1))
                                            .frame(width: 20, height: 20)
                                            .offset(x: -60, y: -30)
                                        
                                        Circle()
                                            .fill(Color.white.opacity(0.1))
                                            .frame(width: 15, height: 15)
                                            .offset(x: 65, y: 40)
                                        
                                        Circle()
                                            .fill(Color.white.opacity(0.1))
                                            .frame(width: 25, height: 25)
                                            .offset(x: 70, y: -35)
                                    }
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                                )
                                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                                
                                Spacer()
                            }
                            .frame(width: geometry.size.width, height: geometry.size.height)
                        }
                        .zIndex(2)
                    }
                    
                    // ADD: Full-screen touch detection overlay
                    // Only show when circle is placed and full-screen mode is enabled
                    if !showPositionMessage && timerManager.isFullScreenMode, circlePosition != nil {
                        // Sci-fi connecting line from circle to finger - show when touching but not touching the circle
                        if isPressed, let touchPosition = currentTouchPosition, let circlePos = circlePosition, timerManager.showConnectingLine {
                            // Check if the touch is not on the circle
                            let distance = sqrt(pow(touchPosition.x - circlePos.x, 2) + pow(touchPosition.y - circlePos.y, 2))
                            let isNotTouchingCircle = distance > timerManager.circleSize / 2
                            
                            if isNotTouchingCircle {
                                // Calculate the point on the edge of the circle
                                let radius = timerManager.circleSize / 2
                                let dirX = touchPosition.x - circlePos.x
                                let dirY = touchPosition.y - circlePos.y
                                let dirLength = sqrt(dirX * dirX + dirY * dirY)
                                let normalizedDirX = dirX / dirLength
                                let normalizedDirY = dirY / dirLength
                                
                                let circleEdgePoint = CGPoint(
                                    x: circlePos.x + normalizedDirX * radius,
                                    y: circlePos.y + normalizedDirY * radius
                                )
                                
                                // The connecting line
                                ConnectingLine(
                                    startPoint: circleEdgePoint,
                                    endPoint: touchPosition,
                                    isActive: isPressed && isNotTouchingCircle,
                                    useRedColor: true
                                )
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .zIndex(9)
                                
                                // Add mini touch circle overlay
                                TouchPointCircle(position: touchPosition)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .zIndex(11)
                            }
                        }

                        // Replace DragGesture with FullScreenTouchHandler for better multi-touch handling
                        FullScreenTouchHandler(
                            onTouchesChanged: { isTouching in
                                if isTouching != isPressed {
                                    isPressed = isTouching
                                    if isTouching {
                                        // User is touching the screen
                                        
                                        // Enhanced touch feedback if enabled
                                        if timerManager.showTouchFeedback, let touchPos = currentTouchPosition {
                                            touchFeedbackPosition = touchPos
                                            showTouchFeedback = true
                                            // Hide after animation completes
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                showTouchFeedback = false
                                            }
                                        }
                                        
                                        // If this is the first interaction since placing the circle,
                                        // start the max timer when user first holds down
                                        if isFirstInteraction {
                                            timerManager.startMaxTimer()
                                            isFirstInteraction = false
                                        }
                                        
                                        // Show ripple effect when pressed
                                        if timerManager.showRippleEffects {
                                            showRippleEffect = true
                                            // Hide after animation completes
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                                showRippleEffect = false
                                            }
                                        }
                                        
                                        // Stop the hold timer when holding
                                        timerManager.stopHoldTimer()
                                        
                                        // Immediately reset hold timer to original duration when pressed
                                        timerManager.holdTimer = timerManager.holdDuration
                                        
                                        // Start the haptic BPM pulse if enabled
                                        if hapticManager.isBPMPulseEnabled && hapticManager.isHapticEnabled {
                                            hapticManager.startBPMPulse()
                                        }
                                    } else {
                                        // User has released the screen
                                        // Start/resume the hold timer
                                        timerManager.startHoldTimer()
                                        
                                        // Stop the BPM pulse when touch is released
                                        hapticManager.stopBPMPulse()
                                    }
                                }
                            },
                            onTouchMoved: { location in
                                // Update touch position for connecting line
                                currentTouchPosition = location
                            }
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .zIndex(10) // Set high zIndex to ensure it's above all other content
                        
                        // Touch feedback animation
                        if showTouchFeedback, let position = touchFeedbackPosition, timerManager.showTouchFeedback {
                            Circle()
                                .fill(RadialGradient(
                                    gradient: Gradient(colors: [.white, .blue.opacity(0.5), .clear]),
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 20
                                ))
                                .frame(width: 40, height: 40)
                                .position(position)
                                .transition(.opacity)
                                .zIndex(15)
                        }
                    }
                }
                .contentShape(Rectangle())
                
                // Back button overlay (always on top)
                VStack {
                    // Top row with space for the timer
                    Spacer().frame(height: 30) // Reduced from 100 to 30
                    
                    HStack {
                        SlideToConfirmButton(
                            action: {
                                // Check if the hold timer is close to finishing (less than 0.5 seconds)
                                // This prevents the race condition where the timer finishes during slide
                                if timerManager.isHoldTimerRunning && timerManager.holdTimer < 0.5 {
                                    // If timer is about to finish, force the proper transition
                                    // Stop timers but don't dismiss to Settings
                                    timerManager.stopHoldTimer()
                                    timerManager.stopMaxTimer()
                                    
                                    // Force transition to sleep screen
                                    showSleepScreen = true
                                } else {
                                    // Normal behavior - go back to settings
                                    timerManager.stopHoldTimer()
                                    timerManager.stopMaxTimer() 
                                    timerManager.stopAlarmSound()
                                    presentationMode.wrappedValue.dismiss()
                                }
                            },
                            direction: .leading,
                            label: "Slide to exit",
                            accentColor: .blue,
                            opacity: 0.7 // Make it semi-transparent
                        )
                        .frame(width: 220) // Wider but less visually intrusive
                        .padding(.leading, 5)
                        .padding(.top, -40) // Added negative top padding
                        
                        Spacer()
                    }
                    Spacer()
                }
                .allowsHitTesting(true)
                .zIndex(20) // Make sure this is higher than the full-screen touch overlay
                
                // Show mini reset animation
                if showResetAnimation {
                    GeometryReader { geometry in
                        ResetMiniAnimation(size: 60, color: .blue)
                            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    }
                    .zIndex(25)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            // Reset badge count when the screen appears
            try? UNUserNotificationCenter.current().setBadgeCount(0)
            
            // Reset nap state
            napFinished = false
            
            // Don't reset timers here, we need to preserve the current timer values
            
            // Reset state when screen appears
            showPositionMessage = true
            circlePosition = nil
            showSleepScreen = false
            
            // Always ensure holdTimer and maxTimer are stopped when "tap anywhere" UI is showing
            timerManager.stopHoldTimer()
            timerManager.stopMaxTimer()
            
            // Reset the timer values to their original durations for initial display
            timerManager.holdTimer = timerManager.holdDuration
            timerManager.maxTimer = timerManager.maxDuration
            
            // Reset first interaction flag
            isFirstInteraction = true
            
            // Reset background flag
            wasInBackground = false
            
            // Make sure haptic BPM is not running when screen first appears
            hapticManager.stopBPMPulse()
            
            // Subscribe to holdTimer reaching zero
            NotificationCenter.default.addObserver(
                forName: .holdTimerFinished,
                object: nil,
                queue: .main
            ) { _ in
                self.showSleepScreen = true
            }
            
            // Subscribe to maxTimer reaching zero
            NotificationCenter.default.addObserver(
                forName: .maxTimerFinished,
                object: nil,
                queue: .main
            ) { _ in
                // When max timer reaches zero, also go to sleep screen
                self.showSleepScreen = true
                
                // Start playing alarm sound immediately
                self.timerManager.playAlarmSound()
            }
            
            // Add observers for app state changes
            NotificationCenter.default.addObserver(
                forName: UIApplication.didEnterBackgroundNotification,
                object: nil,
                queue: .main
            ) { _ in
                // Set flag that we went to background
                wasInBackground = true
                
                // If user was pressing, release the press
                if isPressed {
                    isPressed = false
                    // Start the hold timer when going to background if it was being held
                    timerManager.startHoldTimer()
                }
            }
            
            NotificationCenter.default.addObserver(
                forName: UIApplication.willEnterForegroundNotification,
                object: nil,
                queue: .main
            ) { _ in
                // When coming back from background, ensure press state is reset
                if isPressed {
                    isPressed = false
                    timerManager.startHoldTimer()
                }
            }
            
            // Setup background audio handling
            audioPlayerManager.setupBackgroundAudio()
            
            // Lock orientation when screen appears
            orientationManager.lockOrientation()
        }
        .onDisappear {
            // Clean up notification observer
            NotificationCenter.default.removeObserver(self)
            
            // Stop any active timers to ensure clean state
            timerManager.stopHoldTimer()
            timerManager.stopMaxTimer()
            
            // Stop alarms to ensure they don't continue playing
            timerManager.stopAlarmSound()
            
            // Unlock orientation when screen disappears
            orientationManager.unlockOrientation()
            
            // Stop BPM pulse
            hapticManager.stopBPMPulse()
        }
        .fullScreenCover(isPresented: $showSleepScreen) {
            // Simple transition - no fancy effects
            SleepScreen(
                dismissToSettings: {
                    // First dismiss SleepScreen
                    self.showSleepScreen = false
                    // Then dismiss NapScreen to get back to SettingsScreen
                    self.presentationMode.wrappedValue.dismiss()
                },
                resetNapScreen: self.resetPlacementState
            )
                .environmentObject(timerManager)
        }
        // Hide home indicator but keep status bar visible
        .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    NapScreen()
        .environmentObject(TimerManager())
}

// MARK: - ConnectingLine View
struct ConnectingLine: View {
    var startPoint: CGPoint
    var endPoint: CGPoint
    var isActive: Bool = true
    var useRedColor: Bool = false
    
    @State private var animationPhase: CGFloat = 0
    @State private var particleSpeed: [CGFloat] = [1.0, 1.3, 0.8, 1.1, 0.9]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Blur glow effect underneath
                Path { path in
                    path.move(to: startPoint)
                    path.addLine(to: endPoint)
                }
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: useRedColor ? 
                                         [.red.opacity(0.7), .orange.opacity(0.5)] : 
                                         [.blue.opacity(0.7), .cyan.opacity(0.5)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 5)
                )
                .blur(radius: 8)
                
                // Main line with animated dash pattern
                Path { path in
                    path.move(to: startPoint)
                    path.addLine(to: endPoint)
                }
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: useRedColor ? 
                                         [.white, .orange, .red] : 
                                         [.white, .cyan, .blue]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(
                        lineWidth: 2,
                        lineCap: .round,
                        lineJoin: .round,
                        dash: [8, 6],
                        dashPhase: animationPhase
                    )
                )
                
                // Energy particles along the line
                ForEach(0..<5, id: \.self) { index in
                    let progress = (CGFloat(index) / 5.0 + animationPhase / (50.0 * particleSpeed[index])).truncatingRemainder(dividingBy: 1.0)
                    let position = interpolatePoint(start: startPoint, end: endPoint, progress: progress)
                    
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: useRedColor ? 
                                                 [.white, .orange.opacity(0.8), .clear] : 
                                                 [.white, .cyan.opacity(0.8), .clear]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 5
                            )
                        )
                        .frame(width: 4 + CGFloat.random(in: 0...2), height: 4 + CGFloat.random(in: 0...2))
                        .position(position)
                        .blur(radius: 2)
                }
                
                // Small energy burst at finger position
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: useRedColor ? 
                                             [.white, .orange, .red.opacity(0.5), .clear] : 
                                             [.white, .cyan, .blue.opacity(0.5), .clear]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 10
                        )
                    )
                    .frame(width: 20, height: 20)
                    .position(endPoint)
                    .blur(radius: 3)
            }
            .opacity(isActive ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.2), value: isActive)
            .onAppear {
                // Start the animation with a longer, less predictable pattern
                withAnimation(Animation.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                    animationPhase = 120
                }
            }
        }
    }
    
    // Helper function to interpolate between two points
    private func interpolatePoint(start: CGPoint, end: CGPoint, progress: CGFloat) -> CGPoint {
        let x = start.x + (end.x - start.x) * progress
        let y = start.y + (end.y - start.y) * progress
        return CGPoint(x: x, y: y)
    }
}

struct NapScreen_Previews: PreviewProvider {
    static var previews: some View {
        NapScreen()
            .environmentObject(TimerManager())
    }
}

// MARK: - TouchPointCircle View
struct TouchPointCircle: View {
    var position: CGPoint
    
    @State private var pulseSize: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Outer glowing ring
            Circle()
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.red.opacity(0.7), .orange.opacity(0.5)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 3
                )
                .frame(width: 70 * pulseSize, height: 70 * pulseSize)
                .blur(radius: 3)
                .position(position)
            
            // Inner circle
            Circle()
                .fill(Color.orange.opacity(0.7))
                .frame(width: 35, height: 35)
                .position(position)
            
            // Center dot
            Circle()
                .fill(Color.white)
                .frame(width: 15, height: 15)
                .position(position)
        }
        .onAppear {
            // Add subtle pulsing animation
            withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulseSize = 1.2
            }
        }
    }
}

// MARK: - Ripple Effect Animation
struct RippleEffect: View {
    var size: CGFloat
    var color: Color
    
    @State private var rippleScale: CGFloat = 0.5
    @State private var opacity: Double = 0.7
    
    var body: some View {
        Circle()
            .stroke(color, lineWidth: 2)
            .scaleEffect(rippleScale)
            .opacity(opacity)
            .onAppear {
                withAnimation(Animation.easeOut(duration: 0.8)) {
                    rippleScale = 1.5
                    opacity = 0
                }
            }
            .frame(width: size, height: size)
    }
}

// MARK: - Reset Mini Animation
struct ResetMiniAnimation: View {
    var size: CGFloat
    var color: Color
    
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.8
    
    var body: some View {
        ZStack {
            // Burst particles
            ForEach(0..<8) { index in
                let angle = Double(index) * 45.0
                let distance = size * 0.6
                
                Circle()
                    .fill(color)
                    .frame(width: 5, height: 5)
                    .offset(
                        x: CGFloat(cos(angle * .pi / 180) * distance),
                        y: CGFloat(sin(angle * .pi / 180) * distance)
                    )
                    .opacity(opacity)
                    .scaleEffect(scale)
            }
            
            // Center swirl
            Image(systemName: "arrow.triangle.2.circlepath")
                .foregroundColor(color)
                .font(.system(size: size * 0.4))
                .rotationEffect(.degrees(rotation))
                .opacity(opacity)
                .scaleEffect(scale)
        }
        .onAppear {
            withAnimation(Animation.spring(response: 0.6, dampingFraction: 0.7)) {
                rotation = 360
                scale = 1.2
            }
            
            withAnimation(Animation.easeOut(duration: 0.8)) {
                opacity = 0
            }
        }
    }
}
