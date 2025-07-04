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
                        
                        // Add small max timer display
                        HStack(spacing: 5) {
                            Image(systemName: "timer")
                                .foregroundColor(.purple.opacity(0.8))
                                .font(.system(size: 10))
                            
                            let maxTimerText = timerManager.formatTime(timerManager.maxTimer)
                            let components = parseTimerComponents(maxTimerText)
                            HStack(spacing: 0) {
                                ForEach(components, id: \.number) { component in
                                    Text(component.number)
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(.purple.opacity(0.9))
                                    
                                    Text(component.unit)
                                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                                        .foregroundColor(.purple.opacity(0.7))
                                        .baselineOffset(-2)
                                        .padding(.trailing, 1)
                                }
                            }
                            
                            Text("remaining")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.purple.opacity(0.8))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.3))
                        )
                        .opacity(0.8)
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
                        // Sleep message with Z's
                        VStack(spacing: 15) {
                            Text("😴")
                                .font(.system(size: 50))
                            
                            Text("Taking a nap...")
                                .font(.system(size: 28, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                            
                            // Static Z's
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
                    
                    // Timer display
                    VStack(spacing: 2) {
                        Text("NAP TIMER")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(Color.blue.opacity(0.7))
                            .tracking(4)
                        
                        let napTimerText = timerManager.formatTime(effectiveNapDuration)
                        let components = parseTimerComponents(napTimerText)
                        HStack(spacing: 0) {
                            ForEach(components, id: \.number) { component in
                                Text(component.number)
                                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                                    .foregroundColor(napFinished ? .green : .white)
                                
                                Text(component.unit)
                                    .font(.system(size: 20, weight: .medium, design: .monospaced))
                                    .foregroundColor(napFinished ? .green.opacity(0.8) : .white.opacity(0.8))
                                    .baselineOffset(-8)
                                    .padding(.trailing, 4)
                            }
                        }
                    }
                    .padding()
                    
                    // Button row - using computed properties for clarity
                    HStack(spacing: 20) {
                        leftButton
                        rightButton
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
            
            // Clear notification badge directly
            try? UNUserNotificationCenter.current().setBadgeCount(0)
            
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
            
            // Get access to the app delegate
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            
            // Check and request notifications before scheduling
            if !notificationManager.isNotificationAuthorized {
                // Request notifications when the user is starting a sleep timer
                appDelegate?.requestNotificationsPermissionWhenNeeded()
            }
            
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
            // Clear any badge count when leaving the sleep screen
            try? UNUserNotificationCenter.current().setBadgeCount(0)
            
            // Stop timers and alarms when screen is dismissed
            timerManager.stopNapTimer()
            timerManager.stopMaxTimer()
            timerManager.stopAlarmSound()
            
            // Clean up notification observers
            NotificationCenter.default.removeObserver(self)
        }
        // Hide home indicator but keep status bar visible
        .edgesIgnoringSafeArea(.all)
    }
    
    // MARK: - Computed Button Views
    
    /// Button for going back to NapScreen or initiating the nap swipe
    @ViewBuilder
    private var leftButton: some View {
        let action = {
            // Ensure alarm is fully stopped first
            timerManager.stopAlarmSound()
            // Also cancel any scheduled notifications
            NotificationManager.shared.cancelPendingNotifications()
            
            resetNapScreen?() // Call reset function if provided
            dismiss()
            timerManager.stopNapTimer() // Stop the nap timer
            // Don't automatically start hold timer here, NapScreen handles state
        }
        
        if napFinished {
            // Tap-only button when timer is done
            Button(action: action) {
                buttonContent(icon: "chevron.left", text: "Back to Nap", color: .blue)
            }
        } else {
            // Slide button when timer is active
            SlideToConfirmButton(
                action: action,
                direction: .leading,
                label: "Repeat nap", //by this point the user knows what slider does
                accentColor: .blue,
                opacity: 0.9
            )
            .frame(width: 200) // Make slider a bit wider than previous button
        }
    }
    
    /// Button for skipping the nap or going back to Settings
    @ViewBuilder
    private var rightButton: some View {
        if !napFinished {
            // Skip button using SlideToConfirmButton
            SlideToConfirmButton(
                action: {
                    // Ensure alarm is stopped first
                    timerManager.stopAlarmSound()
                    // Also cancel any scheduled notifications
                    NotificationManager.shared.cancelPendingNotifications()
                    
                    // Skip the nap
                    timerManager.stopNapTimer()
                    timerManager.napTimer = 0 // Effectively end the timer
                    napFinished = true
                    
                    // Fix bug: Play the alarm sound when skipping
                    timerManager.playAlarmSound()
                },
                direction: .trailing,
                label: "Skip",
                accentColor: .orange,
                opacity: 0.9
            )
            .frame(width: 200) // Make slider a bit wider than previous button
        } else {
            // Button to go back to Settings (reset timers) - tap-only when timer is done
            Button(action: {
                // Ensure alarm is fully stopped first
                timerManager.stopAlarmSound()
                // Also cancel any scheduled notifications
                NotificationManager.shared.cancelPendingNotifications()
                
                timerManager.stopNapTimer()
                timerManager.stopMaxTimer() // Stop max timer to prevent background notifications
                timerManager.resetTimers()
                // Go back to root view (Settings)
                dismissToSettings?()
            }) {
                 buttonContent(icon: "gearshape", text: "Back to Settings", color: .indigo)
            }
        }
    }
    
    /// Helper view for button content to reduce repetition
    private func buttonContent(icon: String, text: String, color: Color) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
            Text(text)
                .font(.system(size: 13, weight: .medium, design: .rounded))
        }
        .padding(.vertical, 15)
        .padding(.horizontal, 20)
        .foregroundColor(.white)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.7), lineWidth: 1)
        )
    }
    
    // Helper to parse timer components for display
    private func parseTimerComponents(_ text: String) -> [TimerComponent] {
        var components: [TimerComponent] = []
        let parts = text.split(separator: " ")
        
        for part in parts {
            let partString = String(part)
            let numberEndIndex = partString.firstIndex(where: { !$0.isNumber }) ?? partString.endIndex
            let number = String(partString[..<numberEndIndex])
            let unit = String(partString[numberEndIndex...])
            components.append(TimerComponent(number: number, unit: unit))
        }
        
        return components
    }
    
    struct TimerComponent {
        let number: String
        let unit: String
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
