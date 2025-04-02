import SwiftUI
import UserNotifications

struct AdvancedSettingsScreen: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var hapticManager = HapticManager.shared
    @ObservedObject var orientationManager = OrientationManager.shared
    @ObservedObject var notificationManager = NotificationManager.shared
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.9).ignoresSafeArea()
            
            VStack {
                // Header - using system back button
                HStack {
                    Spacer()
                    // we already have navigationtitle so this is redundant
                    // Text("Advanced Settings") 
                    //     .font(.system(size: 18, weight: .semibold))
                    //     .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.top, 10)
                .padding(.bottom, 5)
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Notification Settings Section
                        VStack(alignment: .center, spacing: 15) {
                            
                            HStack(spacing: 12) {
                                Image(systemName: notificationManager.isNotificationAuthorized ? 
                                      "bell.badge.fill" : "bell.slash.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(notificationManager.isNotificationAuthorized ? 
                                                    Color.green : Color.orange)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Alarm Notifications")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text(notificationManager.isNotificationAuthorized ? 
                                         "Notifications are enabled. You'll be alerted when your nap time is over." : 
                                         "Currently disabled.")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.8))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                                            Button(action: {
                                if notificationManager.isHiddenFromMainSettings {
                                    // Reset hidden state if currently hidden
                                    notificationManager.resetHiddenState()
                                }
                                
                                if notificationManager.isNotificationAuthorized {
                                    // If already authorized, go to settings to manage
                                    notificationManager.openAppSettings()
                                } else {
                                    // Request permission
                                    notificationManager.requestPermission { granted in
                                        if !granted {
                                            // If denied, prompt to open settings
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                notificationManager.openAppSettings()
                                            }
                                        }
                                    }
                                }
                            }) {

                                    Text(notificationManager.isNotificationAuthorized ? 
                                         "Manage Notifications" : "Enable")
                                
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .background(
                                    Capsule()
                                        .fill(LinearGradient(
                                            colors: [
                                                notificationManager.isNotificationAuthorized ? 
                                                Color.blue : Color.orange, 
                                                notificationManager.isNotificationAuthorized ? 
                                                Color.blue.opacity(0.7) : Color.orange.opacity(0.7)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ))
                                )
                            }
                            .padding(.top, 5)
                            }
                            .padding(.horizontal)
                            

                            
                            // Show button to move notification warning back to main settings
                            if notificationManager.isHiddenFromMainSettings && !notificationManager.isNotificationAuthorized {
                                Button(action: {
                                    notificationManager.resetHiddenState()
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.up.left.circle")
                                        Text("Move the below UI back to Main Settings")
                                    }
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 20)
                                    .background(
                                        Capsule()
                                            .fill(LinearGradient(
                                                colors: [Color.gray, Color.gray.opacity(0.7)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ))
                                    )
                                }
                                .padding(.top, 5)
                            }
                                                                                    // Show notification warning if hidden from main settings and notifications not authorized
                            if !notificationManager.isNotificationAuthorized && notificationManager.isHiddenFromMainSettings {
                                // Use NotificationPermissionWarning without the Hide button
                                NotificationPermissionWarning(showHideButton: false)
                                    .padding(.bottom, 10)
                            }
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 12)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(15)
                        .padding(.horizontal, 8)
                        
                        // Haptic Settings Section
                        VStack(alignment: .center, spacing: 15) {

                            Toggle("Enable haptics when pressing circle", isOn: $hapticManager.isHapticEnabled)
                                .padding(.horizontal)
                                .onChange(of: hapticManager.isHapticEnabled) { _ in
                                    hapticManager.saveSettings()
                                }
                            
                            if hapticManager.isHapticEnabled {
                                Picker("Intensity", selection: $hapticManager.hapticStyle) {
                                    Text("Light").tag(UIImpactFeedbackGenerator.FeedbackStyle.light)
                                    Text("Medium").tag(UIImpactFeedbackGenerator.FeedbackStyle.medium)
                                    Text("Heavy").tag(UIImpactFeedbackGenerator.FeedbackStyle.heavy)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .padding(.horizontal)
                                .onChange(of: hapticManager.hapticStyle) { _ in
                                    hapticManager.saveSettings()
                                }
                                
                                Button(action: {
                                    hapticManager.trigger()
                                }) {
                                    Text("Test Haptic")
                                        .foregroundColor(.white)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(Color.blue.opacity(0.6))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 12)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(15)
                        .padding(.horizontal, 8)
                        
                        // Orientation Settings
                        OrientationSettings()
                        
                        // More advanced settings can be added here
                        
                    }
                    .padding(.top, 10)
                }
            }
        }
        // Allow native back button to show
        // .navigationBarBackButtonHidden(true)  
        // .navigationBarHidden(true)
        .navigationTitle("Advanced Settings")
        .navigationBarTitleDisplayMode(.inline)
        .lockToOrientation(orientationManager)
        .onAppear {
            // Lock orientation when screen appears
            orientationManager.lockOrientation()
            // Refresh notification status
            notificationManager.checkNotificationPermission()
        }
        .onDisappear {
            // Save orientation settings when leaving the screen
            orientationManager.saveSettings(forceOverride: true)
        }
    }
}

#Preview {
    AdvancedSettingsScreen()
} 
