import SwiftUI

struct ContentView: View {
    @EnvironmentObject var timerManager: TimerManager
    @State private var isPressed = false
    private let circleSize: CGFloat = 200
    
    var body: some View {
        ZStack {
            // Background - dark mode
            Color.black.ignoresSafeArea()
            
            VStack {
                // Timer display
                Text(timerManager.formatTime(timerManager.holdTimer))
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding()
                
                Spacer()
                
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
                
                Spacer()
            }
        }
        .onAppear {
            // Start the max session timer and hold timer when the app opens
            timerManager.startMaxTimer()
            timerManager.startHoldTimer()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(TimerManager())
} 