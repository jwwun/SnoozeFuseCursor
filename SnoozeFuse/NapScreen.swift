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
    @EnvironmentObject var timerManager: TimerManager
    @Environment(\.presentationMode) var presentationMode
    @State private var isPressed = false
    @State private var showSleepScreen = false
    @State private var showPositionMessage = true
    @State private var circlePosition: CGPoint? = nil
    @State private var isFirstInteraction = true
    @State private var napFinished = false
    
    // Add state for tracking if app was in background
    @State private var wasInBackground = false
    
    // Method to reset the placement state
    func resetPlacementState() {
        showPositionMessage = true
        circlePosition = nil
        
        // Stop the holdTimer to prevent it from counting down during "tap anywhere" state
        timerManager.stopHoldTimer()
        // Stop the maxTimer as well
        timerManager.stopMaxTimer()
        
        // Ensure we're not tracking pressed state anymore
        isPressed = false
        
        // Reset the first interaction flag
        isFirstInteraction = true
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
                            let timerText = timerManager.formatTime(timerManager.holdTimer)
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
                        
                        if circlePosition != nil {
                            // Session timer info with enhanced visual hierarchy
                            HStack(spacing: 35) {
                                VStack(spacing: 2) {
                                    Text("MAX TIMER")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundColor(Color.purple.opacity(0.8))
                                        .tracking(1)
                                    
                                    let maxTimerText = timerManager.formatTime(timerManager.maxTimer)
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
                                
                                VStack(spacing: 2) {
                                    Text("NAP DURATION")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundColor(Color.blue.opacity(0.7))
                                        .tracking(1)
                                    
                                    let napTimerText = timerManager.formatTime(timerManager.napDuration)
                                    let napComponents = parseTimerComponents(napTimerText)
                                    HStack(spacing: 0) {
                                        ForEach(napComponents, id: \.number) { component in
                                            Text(component.number)
                                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                                .foregroundColor(.white.opacity(0.9))
                                            
                                            Text(component.unit)
                                                .font(.system(size: 9, weight: .medium, design: .monospaced))
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
                                        .fill(Color.black.opacity(0.2))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                        )
                                )
                            }
                        }
                        
                        Spacer()
                    }
                    .zIndex(0)
                    
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
                                timerValue: timerManager.formatTime(timerManager.maxTimer),
                                showTimer: true,
                                timerColor: .white.opacity(0.9),
                                timerProgress: timerManager.maxTimer / timerManager.maxDuration,
                                progressColor: Color.purple.opacity(0.8),
                                releaseTimerProgress: timerManager.holdTimer / timerManager.holdDuration,
                                showArcs: timerManager.showTimerArcs,
                                isFullScreenMode: timerManager.isFullScreenMode
                            )
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
                                                    
                                                    // If this is the first interaction since placing the circle,
                                                    // start the max timer when user first holds down
                                                    if isFirstInteraction {
                                                        timerManager.startMaxTimer()
                                                        isFirstInteraction = false
                                                    }
                                                    
                                                    // Stop the hold timer when holding
                                                    timerManager.stopHoldTimer()
                                                } else {
                                                    // User has released the circle
                                                    // Start/resume the hold timer
                                                    timerManager.startHoldTimer()
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
                                RoundedRectangle(cornerRadius: 22)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.purple.opacity(0.7),
                                                Color.blue.opacity(0.6)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .blur(radius: 0.5)
                                
                                // Animated pulsing effect
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
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.7), .blue.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: .black.opacity(0.5), radius: 15, x: 0, y: 8)
                        .overlay(
                            // Add subtle glass reflection
                            RoundedRectangle(cornerRadius: 22)
                                .fill(
                                    LinearGradient(
                                        colors: [.white.opacity(0.15), .clear],
                                        startPoint: .topLeading,
                                        endPoint: .center
                                    )
                                )
                                .padding(2)
                        )
                        .zIndex(2)
                    }
                    
                    // ADD: Full-screen touch detection overlay
                    // Only show when circle is placed and full-screen mode is enabled
                    if !showPositionMessage && timerManager.isFullScreenMode, circlePosition != nil {
                        // Replace DragGesture with FullScreenTouchHandler for better multi-touch handling
                        FullScreenTouchHandler(
                            onTouchesChanged: { isTouching in
                                if isTouching != isPressed {
                                    isPressed = isTouching
                                    if isTouching {
                                        // User is touching the screen
                                        
                                        // If this is the first interaction since placing the circle,
                                        // start the max timer when user first holds down
                                        if isFirstInteraction {
                                            timerManager.startMaxTimer()
                                            isFirstInteraction = false
                                        }
                                        
                                        // Stop the hold timer when holding
                                        timerManager.stopHoldTimer()
                                    } else {
                                        // User has released the screen
                                        // Start/resume the hold timer
                                        timerManager.startHoldTimer()
                                    }
                                }
                            }
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .zIndex(10) // Set high zIndex to ensure it's above all other content
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
                                timerManager.stopHoldTimer()
                                timerManager.stopMaxTimer()
                                timerManager.stopAlarmSound()
                                presentationMode.wrappedValue.dismiss()
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
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            // Reset nap state
            napFinished = false
            
            // Clear notification badge directly
            UIApplication.shared.applicationIconBadgeNumber = 0
            
            // Don't reset timers here, we need to preserve the current timer values
            // timerManager.resetTimers() - Removing this line
            
            // Reset state when screen appears
            showPositionMessage = true
            circlePosition = nil
            showSleepScreen = false
            
            // Always ensure holdTimer and maxTimer are stopped when "tap anywhere" UI is showing
            timerManager.stopHoldTimer()
            timerManager.stopMaxTimer()
            
            // Reset first interaction flag
            isFirstInteraction = true
            
            // Reset background flag
            wasInBackground = false
            
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
        }
        .onDisappear {
            // Clean up notification observer
            NotificationCenter.default.removeObserver(self)
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
