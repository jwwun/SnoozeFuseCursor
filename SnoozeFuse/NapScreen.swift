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
                            
                            Text(timerManager.formatTime(timerManager.holdTimer))
                                .font(.system(size: 62, weight: .bold, design: .monospaced))
                                .foregroundColor(isPressed ? Color.pink.opacity(0.9) : .white)
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
                                    Text(timerManager.formatTime(timerManager.maxTimer))
                                        .font(.system(size: 18, weight: .semibold, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.9))
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
                                    Text(timerManager.formatTime(timerManager.napDuration))
                                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.7))
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
                            showArcs: timerManager.showTimerArcs
                        )
                        .overlay(
                            MultiTouchHandler(
                                onTouchesChanged: { touchingCircle in
                                    if touchingCircle != isPressed {
                                        isPressed = touchingCircle
                                        if touchingCircle {
                                            // User is pressing the circle
                                            
                                            // If this is the first interaction (timers haven't started yet),
                                            // start the max timer when user first holds down
                                            if timerManager.maxTimer == timerManager.maxDuration {
                                                timerManager.startMaxTimer()
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
                                
                                // Debug printouts to see what's happening
                                print("Tap location: \(location)")
                                print("Circle size: \(timerManager.circleSize)")
                                
                                timerManager.resetTimers()
                                // Don't start timers until user interacts with the placed circle
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
                }
                .contentShape(Rectangle())
                
                // Back button overlay (always on top)
                VStack {
                    HStack {
                        MultiSwipeConfirmation(
                            action: {
                                timerManager.stopHoldTimer()
                                timerManager.stopMaxTimer()
                                timerManager.stopAlarmSound()
                                presentationMode.wrappedValue.dismiss()
                            },
                            requiredSwipes: 2,
                            direction: .leading,
                            label: "Swipe to exit",
                            confirmLabel: "Swipe once more",
                            finalLabel: "Swipe again to confirm",
                            requireMultipleSwipes: timerManager.isAnyTimerActive
                        )
                        .padding(.leading, 5)
                        .padding(.top, 10)
                        
                        Spacer()
                    }
                    Spacer()
                }
                .allowsHitTesting(true)
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            // Reset state when screen appears
            showPositionMessage = true
            circlePosition = nil
            showSleepScreen = false
            
            // Reset timers to use the latest settings
            timerManager.resetTimers()
            // Don't start timers until circle is placed
            
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
                timerManager.playAlarmSound()
            }
        }
        .onDisappear {
            // Clean up notification observer
            NotificationCenter.default.removeObserver(self)
        }
        .fullScreenCover(isPresented: $showSleepScreen) {
            // Simple transition - no fancy effects
            SleepScreen(dismissToSettings: {
                // First dismiss SleepScreen
                self.showSleepScreen = false
                // Then dismiss NapScreen to get back to SettingsScreen
                self.presentationMode.wrappedValue.dismiss()
            })
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
