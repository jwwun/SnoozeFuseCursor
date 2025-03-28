import SwiftUI

struct NapScreen: View {
    @EnvironmentObject var timerManager: TimerManager
    @State private var isPressed = false
    @State private var showSleepScreen = false
    @State private var showPositionMessage = true
    @State private var circlePosition: CGPoint? = nil
    
    var body: some View {
        ZStack {
            // Simple gradient background - no particles
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.05, green: 0.05, blue: 0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Tap to position message
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
            
            // Timer display at top
            VStack {
                VStack(spacing: 0) {
                    Text("HOLD TIMER")
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
                            Text("SESSION")
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
                // Use shared CircleView with MultiTouchHandler overlay
                ZStack {
                    // Shared CircleView
                    CircleView(size: timerManager.circleSize, isPressed: isPressed, showStatusText: true)
                    
                    // MultiTouchHandler (invisible)
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
                        circleRadius: timerManager.circleSize / 2
                    )
                }
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
