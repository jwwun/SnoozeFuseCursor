import SwiftUI

/// UI component for testing out-of-app notifications without affecting main app functionality
struct NotificationTestUI: View {
    @ObservedObject private var notificationManager = NotificationManager.shared
    @State private var testDelaySeconds: Double = 5
    @State private var isTesting = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            HStack {
                Text("NOTIFICATION TEST")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Color.blue.opacity(0.7))
                    .tracking(3)
                
                HelpButton(helpText: "This lets you test out-of-app notifications without interfering with the regular alarm system. Use this to verify your notification settings are working correctly.")
                
                Spacer()
            }
            .padding(.bottom, 2)
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Test notification after:")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                    
                    Spacer()
                    
                    Text("\(Int(testDelaySeconds)) seconds")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // Slider for setting delay time
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.white.opacity(0.6))
                    
                    Slider(value: $testDelaySeconds, in: 3...30, step: 1)
                        .accentColor(.indigo.opacity(0.8))
                    
                    Text("\(Int(testDelaySeconds))")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 30)
                }
                
                // Warning about permissions
                if !notificationManager.isNotificationAuthorized {
                    Text("⚠️ Notifications are currently disabled. Please enable them in settings.")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                        .padding(.top, 2)
                }
                
                // Test button
                Button(action: {
                    if !notificationManager.isNotificationAuthorized {
                        alertMessage = "Notifications are not authorized. Please enable them in Settings first."
                        showAlert = true
                        return
                    }
                    
                    isTesting = true
                    
                    // Schedule test notification
                    scheduleTestNotification()
                    
                    // Reset state after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isTesting = false
                    }
                    
                    // Alert the user about the scheduled test
                    alertMessage = "Test notification scheduled for \(Int(testDelaySeconds)) seconds from now. You can close the app to see how the notification appears."
                    showAlert = true
                    
                    // Haptic feedback
                    HapticManager.shared.trigger()
                }) {
                    HStack {
                        if isTesting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                                .padding(.trailing, 4)
                        }
                        
                        Image(systemName: "bell.badge")
                            .font(.system(size: 14))
                        
                        Text(isTesting ? "Scheduling..." : "Schedule Test Notification")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 15)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.indigo.opacity(isTesting ? 0.5 : 0.7))
                    )
                    .foregroundColor(.white)
                }
                .disabled(isTesting)
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("Notification Test"),
                        message: Text(alertMessage),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(Color.black.opacity(0.2))
            .cornerRadius(8)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(15)
        .padding(.horizontal, 8)
    }
    
    private func scheduleTestNotification() {
        // Create a unique identifier for test notifications 
        // to avoid interfering with real alarm notifications
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "This is a test notification from SnoozeFuse."
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "testCategory" // Use different category from alarms
        
        // Create trigger with specified delay
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: testDelaySeconds,
            repeats: false
        )
        
        // Create request with unique identifier
        let request = UNNotificationRequest(
            identifier: "testNotification-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling test notification: \(error.localizedDescription)")
            }
        }
    }
} 