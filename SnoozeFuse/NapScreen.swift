import SwiftUI

struct NapScreen: View {
    @EnvironmentObject var timerManager: TimerManager
    @State private var isPressed = false
    @State private var showSleepScreen = false
    @State private var showPositionMessage = true
    @State private var circlePosition: CGPoint? = nil
    
    private let circleSize: CGFloat = 200
    
    var body: some View {
        ZStack {
            // Background - dark mode
            Color.black.ignoresSafeArea()
            
            // Tap to position message
            if showPositionMessage {
                Text("Tap anywhere to position your circle")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(10)
            }
            
            // Timer display at top
            VStack {
                Text(timerManager.formatTime(timerManager.holdTimer))
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding()
                
                Spacer()
            }
            
            // Circle positioned at tap location
            if let position = circlePosition {
                // Main circle with multi-touch handling
                ZStack {
                    // Visual circle
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    isPressed ? Color.blue.opacity(0.7) : Color.blue.opacity(0.4),
                                    isPressed ? Color.blue.opacity(0.3) : Color.blue.opacity(0.1)
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: circleSize / 2
                            )
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.blue.opacity(0.6), lineWidth: 2)
                        )
                        .scaleEffect(isPressed ? 0.95 : 1.0)
                        .animation(.spring(response: 0.3), value: isPressed)
                    
                    // Multi-touch handler (invisible)
                    MultiTouchHandler(
                        onTouchesChanged: { touchingCircle in
                            // Update visual state and timer
                            if touchingCircle != isPressed {
                                isPressed = touchingCircle
                                if touchingCircle {
                                    timerManager.stopHoldTimer()
                                } else {
                                    timerManager.startHoldTimer()
                                }
                            }
                        },
                        circleRadius: circleSize / 2
                    )
                }
                .frame(width: circleSize, height: circleSize)
                .position(position)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { location in
            if showPositionMessage {
                // Hide the message and position the circle where tapped
                showPositionMessage = false
                circlePosition = location
                
                // Start timers when circle appears
                timerManager.startMaxTimer()
                timerManager.startHoldTimer()
            }
        }
        .onAppear {
            // Reset state when screen appears
            showPositionMessage = true
            circlePosition = nil
            
            // Subscribe to holdTimer reaching zero
            NotificationCenter.default.addObserver(forName: .holdTimerFinished, object: nil, queue: .main) { _ in
                showSleepScreen = true
            }
        }
        .fullScreenCover(isPresented: $showSleepScreen) {
            // Show sleep screen when timer reaches zero
            SleepScreen()
                .environmentObject(timerManager)
        }
    }
}

#Preview {
    NapScreen()
        .environmentObject(TimerManager())
} 