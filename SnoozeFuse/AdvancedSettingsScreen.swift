import SwiftUI
import UserNotifications

struct AdvancedSettingsScreen: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var hapticManager = HapticManager.shared
    @ObservedObject var orientationManager = OrientationManager.shared
    @ObservedObject var notificationManager = NotificationManager.shared
    @ObservedObject var presetManager = PresetManager.shared
    @EnvironmentObject var timerManager: TimerManager
    @State private var presetsRefreshTrigger = false // Force view updates for presets
    
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
                                        
                                    // Add critical alerts status if notifications are enabled
                                    if notificationManager.isNotificationAuthorized {
                                        HStack {
                                            Image(systemName: notificationManager.isCriticalAlertsAuthorized ? 
                                                  "bell.and.waves.left.and.right.fill" : "bell.and.waves.left.and.right")
                                                .font(.system(size: 14))
                                                .foregroundColor(notificationManager.isCriticalAlertsAuthorized ? 
                                                                Color.green : Color.orange)
                                            
                                            Text("Optional Critical Alerts: \(notificationManager.isCriticalAlertsAuthorized ? "Enabled" : "Disabled")")
                                                .font(.system(size: 12))
                                                .foregroundColor(notificationManager.isCriticalAlertsAuthorized ? 
                                                                Color.green.opacity(0.8) : Color.orange.opacity(0.8))
                                        }
                                    }
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
                        
                        // Show Presets UI if hidden from main settings
                        if presetManager.isHiddenFromMainSettings {
                            PresetUI()
                                .transition(.move(edge: .trailing))
                                .animation(.easeInOut(duration: 0.3), value: presetsRefreshTrigger)
                                .id("presetUI-\(presetsRefreshTrigger)")
                        }
                        
                        // Haptic Settings Section
                        VStack(alignment: .center, spacing: 15) {
                            Text("Haptic Feedback")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                            
                            Divider()
                                .background(Color.gray.opacity(0.5))
                                .padding(.horizontal)

                            Toggle("Enable haptics when pressing circle", isOn: $hapticManager.isHapticEnabled)
                                .padding(.horizontal)
                                .onChange(of: hapticManager.isHapticEnabled) { _ in
                                    hapticManager.saveSettings()
                                }
                            
                            // Update note about system alarm vibration
                            Text("Haptics control touch feedback only. Alarms will always use the system's standard alarm vibration pattern")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
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
                        
                        // Visual Settings Section
                        VStack(alignment: .center, spacing: 15) {
                            Text("Visual Settings")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                            
                            Divider()
                                .background(Color.gray.opacity(0.5))
                                .padding(.horizontal)
                            
                            Toggle("Show timer arcs on circle", isOn: $timerManager.showTimerArcs)
                                .padding(.horizontal)
                                .onChange(of: timerManager.showTimerArcs) { _ in
                                    timerManager.saveSettings()
                                }
                            
                            if timerManager.showTimerArcs {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("If disabled, the circular timer arcs will not be displayed around the circle during nap sessions.")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.7))
                                        .fixedSize(horizontal: false, vertical: true)
                                        .padding(.horizontal)
                                    
                                    Text("Battery impact: Enabling timer arcs may increase battery usage by approximately 2-3% during active sessions due to additional rendering.")
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.6))
                                        .fixedSize(horizontal: false, vertical: true)
                                        .padding(.horizontal)
                                        .padding(.top, 4)
                                }
                            }
                            
                            Toggle("Show sci-fi connecting line effect", isOn: $timerManager.showConnectingLine)
                                .padding(.horizontal)
                                .onChange(of: timerManager.showConnectingLine) { _ in
                                    timerManager.saveSettings()
                                }
                                .tint(Color.red.opacity(0.8)) // Red tint to match the line color
                            
                            if timerManager.showConnectingLine {
                                Text("Displays a red energy line when touching the screen in full-screen mode")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                    .padding(.horizontal)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 12)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(15)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 12)
                        
                        // Add info about critical alerts
                        if notificationManager.isNotificationAuthorized {
                            VStack(alignment: .center, spacing: 8) {
                                Text("Optional Critical Alerts")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Text("Critical alerts allow the app to make sounds and vibrations even when your device is in silent mode or Do Not Disturb is on. This is important for reliable alarm behavior.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                
                                if !notificationManager.isCriticalAlertsAuthorized {
                                    Text("Note: Critical alerts require special permission from Apple. SnoozeFuse may have requested this permission, but if it was denied, you'll need to enable it in Settings.")
                                        .font(.system(size: 12))
                                        .foregroundColor(.orange.opacity(0.8))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                    
                                    Button(action: {
                                        // Request critical alerts specifically
                                        notificationManager.requestNotificationAuthorization()
                                    }) {
                                        Text("Request Critical Alerts Permission")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 16)
                                            .background(
                                                Capsule()
                                                    .fill(LinearGradient(
                                                        colors: [Color.orange, Color.orange.opacity(0.7)],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    ))
                                            )
                                    }
                                    .padding(.top, 5)
                                }
                            }
                            .padding(.vertical, 10)
                        }
                        
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
            
            // Add observer for preset UI state changes
            NotificationCenter.default.addObserver(forName: .presetUIStateChanged, object: nil, queue: .main) { _ in
                // Toggle the refresh trigger to force UI update
                withAnimation {
                    self.presetsRefreshTrigger.toggle()
                }
            }
        }
        .onDisappear {
            // Save orientation settings when leaving the screen
            orientationManager.saveSettings(forceOverride: true)
            
            // Remove the observer when view disappears
            NotificationCenter.default.removeObserver(self, name: .presetUIStateChanged, object: nil)
        }
    }
}

#Preview {
    AdvancedSettingsScreen()
} 
