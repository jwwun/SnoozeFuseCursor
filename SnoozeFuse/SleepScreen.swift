import SwiftUI

struct SleepScreen: View {
    @EnvironmentObject var timerManager: TimerManager
    @Environment(\.dismiss) private var dismiss
    @State private var napFinished = false
    
    // Confirmation state for safety buttons
    @State private var isBackConfirmationShowing = false
    @State private var isSkipConfirmationShowing = false
    @State private var confirmationTimer: Timer? = nil
    
    var body: some View {
        ZStack {
            // Simple dark background
            Color(red: 0.02, green: 0.03, blue: 0.10)
                .ignoresSafeArea()
            
            VStack {
                // Wake up time display
                VStack(spacing: 8) {
                    Text("WAKE UP AT")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Color.blue.opacity(0.8))
                        .tracking(5)
                    
                    Text(calculateWakeUpTime())
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    HStack {
                        Image(systemName: "alarm")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.system(size: 14))
                        
                        Text("No later than \(calculateMaxWakeUpTime())")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 4)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.3))
                    )
                }
                .padding(.vertical)
                .padding(.horizontal, 30)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.black.opacity(0.2))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
                .padding(.top, 40)
                
                Spacer()
                
                // Sleep message or wake up message depending on state
                if napFinished {
                    VStack(spacing: 15) {
                        Text("🔔")
                            .font(.system(size: 50))
                        
                        Text("Time to wake up!")
                            .font(.system(size: 28, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Your nap is complete")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                    }
                } else {
                    // Sleep message - simple
                    VStack(spacing: 15) {
                        Text("😴")
                            .font(.system(size: 50))
                        
                        Text("Taking a nap...")
                            .font(.system(size: 28, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                        
                        // Simple static Z's
                        HStack(spacing: 10) {
                            Text("Z")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text("Z")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text("Z")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                }
                
                Spacer()
                
                // Timer display - simple
                VStack(spacing: 2) {
                    Text("NAP TIMER")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Color.blue.opacity(0.7))
                        .tracking(4)
                    
                    Text(timerManager.formatTime(timerManager.napTimer))
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(napFinished ? .green : .white)
                }
                .padding()
                
                // Button row - simplified
                HStack(spacing: 40) {
                    // Back button with confirmation
                    Button(action: {
                        if isBackConfirmationShowing {
                            // Second press - confirm and go back
                            dismiss()
                            timerManager.stopNapTimer()
                            timerManager.startHoldTimer()
                        } else {
                            // First press - show confirmation
                            isBackConfirmationShowing = true
                            isSkipConfirmationShowing = false
                            
                            // Reset confirmation after 3 seconds
                            confirmationTimer?.invalidate()
                            confirmationTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                                isBackConfirmationShowing = false
                            }
                        }
                    }) {
                        VStack {
                            Image(systemName: napFinished ? "house" : "arrow.left")
                                .font(.system(size: 24))
                            Text(isBackConfirmationShowing ? "Confirm?" : (napFinished ? "Home" : "Back"))
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                        }
                        .frame(width: 80, height: 80)
                        .foregroundColor(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(isBackConfirmationShowing ? Color.red.opacity(0.4) : Color.blue.opacity(0.3))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(isBackConfirmationShowing ? Color.red.opacity(0.5) : Color.blue.opacity(0.5), lineWidth: 1)
                        )
                    }
                    
                    // Skip button with confirmation (only show if nap not finished)
                    if !napFinished {
                        Button(action: {
                            if isSkipConfirmationShowing {
                                // Second press - confirm and skip nap
                                timerManager.stopNapTimer()
                                timerManager.napTimer = 0
                                napFinished = true
                            } else {
                                // First press - show confirmation
                                isSkipConfirmationShowing = true
                                isBackConfirmationShowing = false
                                
                                // Reset confirmation after 3 seconds
                                confirmationTimer?.invalidate()
                                confirmationTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                                    isSkipConfirmationShowing = false
                                }
                            }
                        }) {
                            VStack {
                                Image(systemName: "forward.end")
                                    .font(.system(size: 24))
                                Text(isSkipConfirmationShowing ? "Confirm?" : "Skip")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                            }
                            .frame(width: 80, height: 80)
                            .foregroundColor(.white)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(isSkipConfirmationShowing ? Color.red.opacity(0.4) : Color.purple.opacity(0.3))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(isSkipConfirmationShowing ? Color.red.opacity(0.5) : Color.purple.opacity(0.5), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            // Reset nap state
            napFinished = false
            
            // Reset timers to use the latest settings
            timerManager.resetTimers()
            
            // Start nap timer when screen appears
            timerManager.startNapTimer()
            
            // Listen for nap timer finished notification
            NotificationCenter.default.addObserver(
                forName: .napTimerFinished,
                object: nil,
                queue: .main
            ) { _ in
                self.napFinished = true
                // Play alarm sound here in the future
                self.timerManager.playAlarmSound()
            }
        }
        .onDisappear {
            // Cleanup
            confirmationTimer?.invalidate()
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    // Calculate wake up time based on current time + nap duration
    private func calculateWakeUpTime() -> String {
        let wakeTime = Date().addingTimeInterval(timerManager.napTimer)
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: wakeTime)
    }
    
    // Calculate max possible wake up time
    private func calculateMaxWakeUpTime() -> String {
        let maxWakeTime = Date().addingTimeInterval(timerManager.maxTimer)
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: maxWakeTime)
    }
}

#Preview {
    SleepScreen()
        .environmentObject(TimerManager())
}