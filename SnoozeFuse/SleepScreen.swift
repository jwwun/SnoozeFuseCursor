import SwiftUI
import UserNotifications

struct SleepScreen: View {
    @EnvironmentObject var timerManager: TimerManager
    @Environment(\.dismiss) private var dismiss
    @State private var napFinished = false
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var notificationManager = NotificationManager.shared
    
    // Closure to dismiss back to settings
    var dismissToSettings: (() -> Void)? = nil
    
    // Closure to reset the NapScreen state
    var resetNapScreen: (() -> Void)? = nil
    
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
                                // Ensure alarm is fully stopped first
                                timerManager.stopAlarmSound()
                                // Also cancel any scheduled notifications
                                NotificationManager.shared.cancelPendingNotifications()
                                
                                resetNapScreen?() // Call reset function if provided
                                dismiss()
                                timerManager.stopNapTimer()
                                timerManager.startHoldTimer()
                            }) {
                                VStack(spacing: 5) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 22, weight: .medium))
                                    Text("Back to Nap")
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                }
                                .padding(.vertical, 15)
                                .padding(.horizontal, 20)
                                .foregroundColor(.white)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.blue.opacity(0.5))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.blue.opacity(0.7), lineWidth: 1)
                                )
                            }
                        } else {
                            // Multi-swipe button when timer is active
                            MultiSwipeConfirmation(
                                action: {
                                    // Ensure alarm is fully stopped first
                                    timerManager.stopAlarmSound()
                                    // Also cancel any scheduled notifications
                                    NotificationManager.shared.cancelPendingNotifications()
                                    
                                    resetNapScreen?() // Call reset function if provided
                                    dismiss()
                                    timerManager.stopNapTimer()
                                    timerManager.startHoldTimer()
                                },
                                requiredSwipes: 2,
                                direction: .leading,
                                label: "Swipe to Nap",
                                confirmLabel: "Swipe once more",
                                finalLabel: "Swipe to confirm",
                                requireMultipleSwipes: timerManager.isAnyTimerActive
                            )
                            .frame(width: 145)
                        }
                        
                        // Skip button or Settings button
                        if !napFinished {
                            // Skip button using MultiSwipeConfirmation
                            MultiSwipeConfirmation(
                                action: {
                                    // Ensure alarm is stopped first
                                    timerManager.stopAlarmSound()
                                    
                                    // Skip the nap
                                    timerManager.stopNapTimer()
                                    timerManager.napTimer = 0
                                    napFinished = true
                                },
                                requiredSwipes: 2,
                                direction: .trailing,
                                label: "Swipe to skip",
                                confirmLabel: "Swipe once more",
                                finalLabel: "Swipe to confirm",
                                requireMultipleSwipes: timerManager.isAnyTimerActive
                            )
                            .frame(width: 145)
                        } else {
                            // Button to go back to Settings (reset timers) - tap-only when timer is done
                            Button(action: {
                                // Ensure alarm is fully stopped first
                                timerManager.stopAlarmSound()
                                // Also cancel any scheduled notifications
                                NotificationManager.shared.cancelPendingNotifications()
                                
                                timerManager.stopNapTimer()
                                timerManager.resetTimers()
                                // Go back to root view (Settings)
                                if let dismissAction = dismissToSettings {
                                    dismissAction()
                                } else {
                                    // Fallback to just dismissing this screen
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }) {
                                VStack(spacing: 5) {
                                    Image(systemName: "gearshape")
                                        .font(.system(size: 22, weight: .medium))
                                    Text("Back to Settings")
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                }
                                .padding(.vertical, 15)
                                .padding(.horizontal, 20)
                                .foregroundColor(.white)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.indigo.opacity(0.5))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.indigo.opacity(0.7), lineWidth: 1)
                                )
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
            
            // Don't reset timers here, we need to preserve the current timer values
            // timerManager.resetTimers() - Removing this line
            
            // If max timer is less than nap timer, use max timer's current value (not the full duration)
            if timerManager.maxTimer < timerManager.napDuration {
                timerManager.napTimer = timerManager.maxTimer
            } else {
                // Otherwise use the full nap duration
                timerManager.napTimer = timerManager.napDuration
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
                // Play the alarm sound
                self.timerManager.playAlarmSound()
            }
        }
        .onDisappear {
            // Cleanup
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
    SleepScreen(dismissToSettings: {
        print("Dismiss to settings action")
    }, resetNapScreen: {
        print("Reset NapScreen state")
    })
        .environmentObject(TimerManager())
}
