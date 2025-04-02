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
                    
                    // Button row - redesigned with better aesthetics
                    HStack(spacing: 40) {
                        // Back to Settings button (Home)
                        VStack {
                            if napFinished {
                                Button(action: {
                                    timerManager.stopAlarmSound()
                                    timerManager.resetTimers()
                                    // This properly returns to SettingsScreen
                                    presentationMode.wrappedValue.dismiss()
                                }) {
                                    buttonContent(icon: "house.fill", text: "Settings", color: .indigo)
                                }
                            } else {
                                MultiSwipeConfirmation(
                                    action: {
                                        timerManager.stopAlarmSound()
                                        timerManager.resetTimers()
                                        // This properly returns to SettingsScreen
                                        presentationMode.wrappedValue.dismiss()
                                    },
                                    requiredSwipes: 2,
                                    direction: .leading,
                                    label: "Swipe to Settings",
                                    confirmLabel: "Swipe again",
                                    finalLabel: "Release for Settings",
                                    isTimerActive: !napFinished
                                )
                                .frame(width: 130)
                            }
                        }
                        
                        // Back to Nap button (keeps settings)
                        VStack {
                            if napFinished {
                                Button(action: {
                                    timerManager.stopAlarmSound()
                                    dismiss() // This returns to NapScreen
                                }) {
                                    buttonContent(icon: "moon.zzz.fill", text: "Back to Nap", color: .purple)
                                }
                            } else {
                                MultiSwipeConfirmation(
                                    action: {
                                        timerManager.stopAlarmSound()
                                        dismiss() // This returns to NapScreen
                                    },
                                    requiredSwipes: 2,
                                    direction: .trailing,
                                    label: "Swipe to Nap",
                                    confirmLabel: "Swipe again",
                                    finalLabel: "Release for Nap",
                                    isTimerActive: !napFinished
                                )
                                .frame(width: 130)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
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
        .hideHomeIndicator(true)
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
    
    // Helper for consistent button appearance with enhanced aesthetics
    private func buttonContent(icon: String, text: String, color: Color = Color.blue) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(.white)
            
            Text(text)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(width: 130, height: 100)
        .background(
            ZStack {
                // Bottom layer - shadow effect
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.black.opacity(0.4))
                    .offset(y: 3)
                    .blur(radius: 2)
                
                // Middle layer - gradient background
                RoundedRectangle(cornerRadius: 22)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                color.opacity(0.6),
                                color.opacity(0.3)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Top layer - subtle shine effect
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.7),
                                Color.white.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
        )
        .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    SleepScreen()
        .environmentObject(TimerManager())
}
