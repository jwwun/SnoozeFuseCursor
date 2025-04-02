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
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(Color.blue.opacity(0.7))
                                .tracking(3)
                                .padding(.bottom, 5)
                            
                            Text(timerManager.formatTime(timerManager.holdTimer))
                                .font(.system(size: 56, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 60)
                        .padding(.bottom, 10)
                        
                        if circlePosition != nil {
                            // Session timer info
                            HStack(spacing: 30) {
                                VStack {
                                    Text("MAX")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.gray)
                                    Text(timerManager.formatTime(timerManager.maxTimer))
                                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                VStack {
                                    Text("NAP")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.gray)
                                    Text(timerManager.formatTime(timerManager.napDuration))
                                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                            .padding(10)
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(10)
                        }
                        
                        Spacer()
                    }
                    
                    // Circle positioned at tap location
                    if let position = circlePosition {
                        ZStack {
                            CircleView(
                                size: timerManager.circleSize,
                                isPressed: isPressed,
                                showStatusText: true,
                                showInitialInstructions: timerManager.maxTimer == timerManager.maxDuration
                            )
                            
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
                        }
                        .position(position)
                    }
                    
                    // Initial message
                    if showPositionMessage {
                        Text("Tap anywhere to position your circle")
                            .font(.system(size: 24, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.blue.opacity(0.2))
                            )
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { location in
                    if showPositionMessage {
                        showPositionMessage = false
                        circlePosition = location
                        timerManager.resetTimers()
                        // Don't start timers until user interacts with the placed circle
                    }
                }
                
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
