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
            Circle()
                .fill(isConfirming ? Color.red.opacity(0.2) : Color.gray.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                )
        }
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
                            CircleView(size: timerManager.circleSize, isPressed: isPressed, showStatusText: true)
                            
                            MultiTouchHandler(
                                onTouchesChanged: { touchingCircle in
                                    if touchingCircle != isPressed {
                                        isPressed = touchingCircle
                                        if touchingCircle {
                                            timerManager.stopHoldTimer()
                                        } else {
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
                        timerManager.startMaxTimer()
                        timerManager.startHoldTimer()
                    }
                }
                
                // Back button overlay (always on top)
                VStack {
                    HStack {
                        CircularBackButton {
                            timerManager.stopHoldTimer()
                            timerManager.stopMaxTimer()
                            timerManager.stopAlarmSound()
                            presentationMode.wrappedValue.dismiss()
                        }
                        .padding(.leading, 20)
                        .padding(.top, 20)
                        .contentShape(Circle())
                        
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
            SleepScreen()
                .environmentObject(timerManager)
        }
    }
}

#Preview {
    NapScreen()
        .environmentObject(TimerManager())
}
