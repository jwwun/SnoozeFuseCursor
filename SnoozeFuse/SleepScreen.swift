import SwiftUI
import UserNotifications

struct SleepScreen: View {
    @EnvironmentObject var timerManager: TimerManager
    @Environment(\.dismiss) private var dismiss
    @State private var napFinished = false
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var notificationManager = NotificationManager.shared
    
    // Confirmation state for skip button
    @State private var isSkipConfirmationShowing = false
    @State private var confirmationTimer: Timer? = nil
    
    // Computed property to determine which timer to use
    private var effectiveNapDuration: TimeInterval {
        // If max timer is less than nap timer, use max timer
        return timerManager.maxTimer < timerManager.napTimer ? timerManager.maxTimer : timerManager.napTimer
    }
    
    var body: some View {
        NavigationView {
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
                        
                        Text(timerManager.formatTime(effectiveNapDuration))
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(napFinished ? .green : .white)
                    }
                    .padding()
                    
                    // Button row - redesigned with two buttons
                    HStack(spacing: 20) {
                        // Button to go back to NapScreen (keeping settings)
                        if napFinished {
                            // Tap-only button when timer is done
                            Button(action: {
                                timerManager.stopAlarmSound()
                                dismiss()
                                timerManager.stopNapTimer()
                                timerManager.startHoldTimer()
                            }) {
                                VStack(spacing: 5) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 24))
                                    Text("Back to Nap")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .frame(width: 120, height: 70)
                                .foregroundColor(.white)
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.purple.opacity(0.6), Color.purple.opacity(0.3)]),
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.purple.opacity(0.7), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 3)
                            }
                        } else {
                            // Multi-swipe button when timer is active
                            MultiSwipeConfirmation(
                                action: {
                                    timerManager.stopAlarmSound()
                                    dismiss()
                                    timerManager.stopNapTimer()
                                    timerManager.startHoldTimer()
                                },
                                requiredSwipes: 2,
                                direction: .leading,
                                label: "Back to Nap",
                                confirmLabel: "Swipe once more",
                                finalLabel: "Swipe to confirm",
                                requireMultipleSwipes: timerManager.isAnyTimerActive
                            )
                            .frame(width: 120)
                        }
                        
                        // Skip button or Settings button
                        if !napFinished {
                            // Skip button (only when timer is active)
                            Button(action: {
                                if isSkipConfirmationShowing {
                                    // Second press - confirm and skip nap
                                    timerManager.stopNapTimer()
                                    timerManager.napTimer = 0
                                    napFinished = true
                                } else {
                                    // First press - show confirmation
                                    isSkipConfirmationShowing = true
                                    
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
                        } else {
                            // Button to go back to Settings (reset timers) - tap-only when timer is done
                            Button(action: {
                                timerManager.stopAlarmSound()
                                timerManager.stopNapTimer()
                                timerManager.resetTimers()
                                // Go back to root view (Settings)
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                VStack(spacing: 5) {
                                    Image(systemName: "gearshape")
                                        .font(.system(size: 24))
                                    Text("Back to Settings")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .frame(width: 140, height: 70)
                                .foregroundColor(.white)
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.indigo.opacity(0.6), Color.indigo.opacity(0.3)]),
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.indigo.opacity(0.7), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 3)
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            // Reset nap state
            napFinished = false
            
            // Reset timers to use the latest settings
            timerManager.resetTimers()
            
            // If max timer is less than nap timer, use max timer's value
            if timerManager.maxTimer < timerManager.napTimer {
                timerManager.napTimer = timerManager.maxTimer
            }
            
            // Start nap timer when screen appears
            timerManager.startNapTimer()
            
            // Schedule notification for the nap timer
            if notificationManager.isNotificationAuthorized {
                // We'll use the TimerManager's method which was updated to schedule notifications
                timerManager.scheduleAlarmNotification()
            }
            
            // Stop hold timer
            timerManager.stopHoldTimer()
            
            // Listen for nap timer finished notification
            NotificationCenter.default.addObserver(
                forName: .napTimerFinished,
                object: nil,
                queue: .main
            ) { _ in
                self.napFinished = true
                self.timerManager.playAlarmSound()
            }
            
            // Listen for max timer finished notification
            NotificationCenter.default.addObserver(
                forName: .maxTimerFinished,
                object: nil,
                queue: .main
            ) { _ in
                self.napFinished = true
                self.timerManager.playAlarmSound()
            }
        }
        .onDisappear {
            // Cleanup
            confirmationTimer?.invalidate()
            NotificationCenter.default.removeObserver(self)
            timerManager.stopAlarmSound() // Ensure alarm is stopped
            
            // Cancel any pending notifications when leaving the screen
            NotificationManager.shared.cancelPendingNotifications()
        }
        // Hide home indicator but keep status bar visible
        .edgesIgnoringSafeArea(.all)
    }
    
    // Calculate wake up time based on effective nap duration
    private func calculateWakeUpTime() -> String {
        let wakeTime = Date().addingTimeInterval(effectiveNapDuration)
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
