import SwiftUI

struct ContentView: View {
    @EnvironmentObject var timerManager: TimerManager
    @State private var isPressed = false
    
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
                
                // Main circle
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                isPressed ? Color.blue.opacity(0.7) : Color.blue.opacity(0.4),
                                isPressed ? Color.blue.opacity(0.3) : Color.blue.opacity(0.1)
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .overlay(
                        Circle()
                            .stroke(Color.blue.opacity(0.6), lineWidth: 2)
                    )
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                    .animation(.spring(response: 0.3), value: isPressed)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in 
                                isPressed = true
                                timerManager.stopHoldTimer()
                            }
                            .onEnded { _ in 
                                isPressed = false
                                timerManager.startHoldTimer()
                            }
                    )
                
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