import SwiftUI

struct ContentView: View {
    @State private var isCircleTouched = false
    @State private var circleSize: CGFloat = 200 // Default size, will be configurable
    
    // Placeholder timer values for UI design
    @State private var timerARemaining: Double = 30.0
    @State private var timerBRemaining: Double = 600.0
    @State private var timerCRemaining: Double = 1200.0
    
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                // Timer displays at top
                TimerDisplayGroup(
                    timerA: timerARemaining,
                    timerB: timerBRemaining,
                    timerC: timerCRemaining
                )
                
                Spacer()
                
                // Main touch circle
                TouchCircle(
                    size: circleSize,
                    isPressed: $isCircleTouched
                )
                
                Spacer()
                
                // Settings and Stats buttons
                ControlButtons()
            }
            .padding()
        }
    }
}

// Touch Circle Component
struct TouchCircle: View {
    let size: CGFloat
    @Binding var isPressed: Bool
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [
                        isPressed ? Color.blue.opacity(0.7) : Color.blue.opacity(0.4),
                        isPressed ? Color.blue.opacity(0.3) : Color.blue.opacity(0.1)
                    ]),
                    center: .center,
                    startRadius: 0,
                    endRadius: size/2
                )
            )
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(Color.blue.opacity(0.6), lineWidth: 2)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3), value: isPressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

// Timer Display Component
struct TimerDisplayGroup: View {
    let timerA: Double
    let timerB: Double
    let timerC: Double
    
    var body: some View {
        VStack(spacing: 15) {
            TimerRow(label: "Hold Timer", value: timerA, color: .blue)
            TimerRow(label: "Nap Timer", value: timerB, color: .purple)
            TimerRow(label: "Session Timer", value: timerC, color: .orange)
        }
        .padding()
        .background(Color.black.opacity(0.6))
        .cornerRadius(15)
    }
}

struct TimerRow: View {
    let label: String
    let value: Double
    let color: Color
    
    var formattedTime: String {
        let minutes = Int(value) / 60
        let seconds = Int(value) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text(formattedTime)
                .foregroundColor(color)
                .font(.system(.title3, design: .monospaced))
        }
    }
}

// Control Buttons Component
struct ControlButtons: View {
    var body: some View {
        HStack(spacing: 40) {
            Button(action: {}) {
                VStack {
                    Image(systemName: "gear")
                        .font(.title2)
                    Text("Settings")
                        .font(.caption)
                }
            }
            
            Button(action: {}) {
                VStack {
                    Image(systemName: "chart.bar")
                        .font(.title2)
                    Text("Stats")
                        .font(.caption)
                }
            }
        }
        .foregroundColor(.gray)
        .padding()
    }
}

// Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 