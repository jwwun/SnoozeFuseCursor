import SwiftUI

struct SleepScreen: View {
    @EnvironmentObject var timerManager: TimerManager
    @Environment(\.dismiss) private var dismiss
    
    // Confirmation state for safety buttons
    @State private var isBackConfirmationShowing = false
    @State private var isSkipConfirmationShowing = false
    @State private var confirmationTimer: Timer? = nil
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            VStack {
                // Wake up time display
                VStack(spacing: 4) {
                    Text("Wake up at")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                    
                    Text(calculateWakeUpTime())
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("No later than \(calculateMaxWakeUpTime())")
                        .font(.system(size: 16))
                        .foregroundColor(.gray.opacity(0.8))
                        .padding(.top, 4)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Sleep message
                Text("Zzz... Taking a nap 😴")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                // Timer display
                Text(timerManager.formatTime(timerManager.napTimer))
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding()
                
                // Button row with safety features
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
                            Image(systemName: "arrow.left")
                                .font(.system(size: 24))
                            Text(isBackConfirmationShowing ? "Confirm?" : "Back")
                                .font(.system(size: 14))
                        }
                        .frame(width: 80, height: 80)
                        .foregroundColor(.white)
                        .background(isBackConfirmationShowing ? Color.red.opacity(0.5) : Color.blue.opacity(0.3))
                        .cornerRadius(15)
                    }
                    
                    // Skip button with confirmation
                    Button(action: {
                        if isSkipConfirmationShowing {
                            // Second press - confirm and skip nap
                            timerManager.stopNapTimer()
                            timerManager.napTimer = 0
                            dismiss()
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
                                .font(.system(size: 14))
                        }
                        .frame(width: 80, height: 80)
                        .foregroundColor(.white)
                        .background(isSkipConfirmationShowing ? Color.red.opacity(0.5) : Color.blue.opacity(0.3))
                        .cornerRadius(15)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            // Start nap timer when screen appears
            timerManager.startNapTimer()
        }
        .onDisappear {
            // Cleanup
            confirmationTimer?.invalidate()
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
