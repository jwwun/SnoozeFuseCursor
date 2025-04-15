import SwiftUI

struct CriticalAlertStatusControl: View {
    @ObservedObject private var notificationManager = NotificationManager.shared
    @State private var showDeveloperOptions = false
    @State private var showInfoAlert = false
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            // Status description - more compact
            Text(userFriendlyDescription)
                .font(.system(size: 13))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 5)
                .padding(.top, 3)
            
            // Simple toggle for developer mode
            HStack {
                Spacer()
                
                Button(action: {
                    showDeveloperOptions.toggle()
                }) {
                    HStack {
                        Image(systemName: showDeveloperOptions ? "chevron.up.circle" : "chevron.down.circle")
                        Text(showDeveloperOptions ? "Hide Developer Options" : "Developer Options")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.gray)
                }
            }
            .padding(.top, 2)
            
            // Developer options
            if showDeveloperOptions {
                Divider()
                    .background(Color.gray.opacity(0.5))
                    .padding(.vertical, 8)
                
                Text("Developer Status Control")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Text("These controls are for developers to simulate different critical alert approval states for testing. Users should not need to change these.")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 8)
                
                // Developer status controls
                HStack(spacing: 12) {
                    // Pending Approval button
                    Button(action: {
                        notificationManager.updateCriticalAlertStatus(.pendingApproval)
                    }) {
                        HStack {
                            Image(systemName: "hourglass")
                            Text("Pending")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Capsule().fill(Color.blue.opacity(0.7)))
                    }
                    .disabled(notificationManager.criticalAlertsStatus == .pendingApproval)
                    .opacity(notificationManager.criticalAlertsStatus == .pendingApproval ? 0.6 : 1.0)
                    
                    // Approved button
                    Button(action: {
                        notificationManager.updateCriticalAlertStatus(.approved)
                        // Request authorization with critical alerts if marked as approved
                        requestCriticalAlerts()
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle")
                            Text("Approved")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Capsule().fill(Color.green.opacity(0.7)))
                    }
                    .disabled(notificationManager.criticalAlertsStatus == .approved)
                    .opacity(notificationManager.criticalAlertsStatus == .approved ? 0.6 : 1.0)
                    
                    // Denied button (should rarely be used)
                    Button(action: {
                        notificationManager.updateCriticalAlertStatus(.denied)
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle")
                            Text("Denied")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Capsule().fill(Color.red.opacity(0.7)))
                    }
                    .disabled(notificationManager.criticalAlertsStatus == .denied)
                    .opacity(notificationManager.criticalAlertsStatus == .denied ? 0.6 : 1.0)
                }
            }
        }
        .alert(isPresented: $showInfoAlert) {
            Alert(
                title: Text("About Critical Alerts"),
                message: Text("Critical Alerts allow SnoozeFuse to play alarm sounds even when your device is in silent mode or Do Not Disturb. This feature requires special approval from Apple.\n\nWhile approval is pending, regular notifications will be used instead. Your alarm will only sound if your device is not in silent mode."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // User-friendly status text
    private var userFriendlyStatus: String {
        switch notificationManager.criticalAlertsStatus {
        case .approved:
            return "Enabled"
        case .denied:
            return "Unavailable"
        case .pendingApproval, .notRequested:
            return "Using Regular Notifications"
        }
    }
    
    // User-friendly description - more compact and less alarming
    private var userFriendlyDescription: String {
        switch notificationManager.criticalAlertsStatus {
        case .approved:
            return "Developer testing mode - simulating approved status. Background notifications are enabled but won't bypass silent mode without Apple's entitlement."
        case .denied:
            return "Developer testing mode - simulating denied status. Standard notifications won't sound if your device is silenced."
        case .pendingApproval, .notRequested:
            return "Developer testing mode - simulating pending approval. Standard notifications won't sound if your device is silenced."
        }
    }
    
    // Computed property for status color
    private var statusColor: Color {
        switch notificationManager.criticalAlertsStatus {
        case .notRequested:
            return .blue
        case .pendingApproval:
            return .blue
        case .approved:
            return .green
        case .denied:
            return .red
        }
    }
    
    // Request critical alerts if marked as approved
    private func requestCriticalAlerts() {
        // Only attempt to request critical alerts if we've marked them as approved
        guard notificationManager.criticalAlertsStatus == .approved else { return }
        
        // Use a proper authorization request with critical alerts option
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert]) { success, error in
            DispatchQueue.main.async {
                if success {
                    print("Critical alert authorization request sent successfully")
                    // Update the authorization flag
                    notificationManager.checkCriticalAlertsAuthorization()
                } else if let error = error {
                    print("Critical alert authorization request failed: \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()
        
        CriticalAlertStatusControl()
            .padding()
    }
} 