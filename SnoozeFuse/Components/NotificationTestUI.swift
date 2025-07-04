import SwiftUI
import UserNotifications

/// UI component for testing out-of-app notifications without affecting main app functionality
struct NotificationTestUI: View {
    @ObservedObject private var notificationManager = NotificationManager.shared
    @ObservedObject private var cafManager = CustomCAFManager.shared
    @State private var testDelaySeconds: Double = 5
    @State private var isTesting = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // Extract help text to a separate property to reduce expression complexity
    private let helpText = "Test notifications with your selected sound and custom delay. This lets you verify how notifications appear when the app is in the background."
    
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            // Header
            headerView
            
            // Main content
            VStack(alignment: .leading, spacing: 10) {
                // Notification delay controls
                delayControlsView
                
                // Warning about permissions
                permissionWarningView
                
                // Test button
                testButtonView
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(Color.black.opacity(0.2))
            .cornerRadius(8)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Notification Test"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("NOTIFICATION TEST")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(Color.blue.opacity(0.7))
                .tracking(3)
            
            HelpButton(helpText: helpText)
            
            Spacer()
        }
        .padding(.bottom, 2)
    }
    
    private var delayControlsView: some View {
        // Single HStack for more compact layout
        HStack(spacing: 8) {
            // Label
            Text("Test after:")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
                .fixedSize()
            
            // Clock icon
            Image(systemName: "clock")
                .foregroundColor(.white.opacity(0.6))
                .font(.system(size: 12))
            
            // Slider
            Slider(value: $testDelaySeconds, in: 3...30, step: 1)
                .accentColor(.indigo.opacity(0.8))
            
            // Time display
            Text("\(Int(testDelaySeconds))s")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 30)
        }
    }
    
    @ViewBuilder
    private var permissionWarningView: some View {

            if !notificationManager.isNotificationAuthorized {
                Text("⚠️ Notifications are currently disabled. Please enable them in settings.")
                    .font(.system(size: 12))
                    .foregroundColor(.orange)
                    .padding(.top, 2)
            }

    }
    
    private var testButtonView: some View {
        Button(action: handleTestButtonTap) {
            HStack {
                if isTesting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                        .padding(.trailing, 4)
                }
                
                Image(systemName: "bell.and.waveform.fill")
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
    }
    
    // Extracted button action logic
    private func handleTestButtonTap() {
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
        
        // Set appropriate alert message
        setAlertMessage()
        
        // Show alert
        showAlert = true
        
        // Haptic feedback
        HapticManager.shared.trigger()
    }
    
    private func setAlertMessage() {
        if let selectedID = cafManager.selectedCAFSoundID,
           let customSound = cafManager.cafSounds.first(where: { $0.id == selectedID }) {
            alertMessage = "Testing notification with '\(customSound.name)' sound after \(Int(testDelaySeconds)) seconds. You can close the app to hear how it sounds when the app is in the background."
        } else if let firstSound = cafManager.cafSounds.first(where: { $0.isBuiltIn }) {
            alertMessage = "Test notification scheduled for \(Int(testDelaySeconds)) seconds from now using '\(firstSound.name)' sound (default). You can close the app to see how the notification appears."
        } else {
            alertMessage = "Test notification scheduled for \(Int(testDelaySeconds)) seconds from now using the system sound. You can close the app to see how the notification appears."
        }
    }
    
    private func scheduleTestNotification() {
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Notification Test"
        content.body = "This is a test notification from SnoozeFuse."
        
        // Set the appropriate sound based on user selection
        if let cafSoundName = cafManager.getSelectedCAFSoundName() {
            // Use the sound name directly for notifications
            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: cafSoundName))
            print("Testing with custom CAF sound: \(cafSoundName)")
        } else {
            // Use default critical sound for better audibility
            content.sound = UNNotificationSound.defaultCritical
            print("Testing with default critical notification sound")
        }
        
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
            } else {
                print("Notification test scheduled successfully")
            }
        }
    }
} 