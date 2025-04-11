import SwiftUI

// Warning component for notification permissions
struct NotificationPermissionWarning: View {
    @ObservedObject private var notificationManager = NotificationManager.shared
    
    var body: some View {
        if !notificationManager.isNotificationAuthorized {
            HStack {
                Image(systemName: "bell.slash.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 18))
                    .padding(.trailing, 4)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Notifications are required for alarms")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text("Without notification permission, alarms won't work when app is closed")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Button(action: {
                    notificationManager.requestAuthorization()
                }) {
                    Text("Allow")
                        .font(.system(size: 14, weight: .bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.7))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(Color.black.opacity(0.5))
            .cornerRadius(12)
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 4)
        }
    }
} 