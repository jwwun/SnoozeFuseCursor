import SwiftUI
import UserNotifications

struct AdvancedSettingsScreen: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var hapticManager = HapticManager.shared
    @ObservedObject var orientationManager = OrientationManager.shared
    @ObservedObject var notificationManager = NotificationManager.shared
    @ObservedObject var presetManager = PresetManager.shared
    @ObservedObject var audioManager = AudioOutputManager.shared
    @ObservedObject var alarmSoundManager = AlarmSoundManager.shared
    @ObservedObject var circleSizeManager = CircleSizeManager.shared
    @ObservedObject var cafManager = CustomCAFManager.shared
    @EnvironmentObject var timerManager: TimerManager
    @State private var presetsRefreshTrigger = false // Force view updates for presets
    @State private var audioOutputRefreshTrigger = false
    @State private var advancedSaveCountdown = 3
    @State private var showNewSectionBadge = false
    @State private var presetRefreshTrigger = false
    @State private var volumeRefreshTrigger = false
    @State private var circleSizeRefreshTrigger = false
    @State private var textInputValue: String = ""  // For circle size input
    
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
                        // Critical Alerts Section (Prioritized)
                        if notificationManager.isNotificationAuthorized {
                            VStack(alignment: .center, spacing: 15) {
                                HStack(spacing: 12) {
                                    Image(systemName: notificationManager.isCriticalAlertsAuthorized ? 
                                          "bell.and.waves.left.and.right.fill" : "bell.and.waves.left.and.right")
                                        .font(.system(size: 24))
                                        .foregroundColor(notificationManager.isCriticalAlertsAuthorized ? 
                                                        Color.green : Color.red)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Critical Alerts")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.white)
                                        
                                        Text(notificationManager.isCriticalAlertsAuthorized ? 
                                             "Critical alerts are enabled. Your alarm will sound even in silent mode." : 
                                             "⚠️ Critical alerts disabled! Alarms may not sound in silent mode.")
                                            .font(.system(size: 14))
                                            .foregroundColor(notificationManager.isCriticalAlertsAuthorized ? 
                                                            .green.opacity(0.8) : .red.opacity(0.9))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        // First try to request notification authorization with critical alerts
                                        notificationManager.requestNotificationAuthorization()
                                        
                                        // Also open settings in case user needs to manually enable
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            notificationManager.openAppSettings()
                                        }
                                    }) {
                                        Text("Enable")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                            .padding(.vertical, 10)
                                            .padding(.horizontal, 20)
                                            .background(
                                                Capsule()
                                                    .fill(LinearGradient(
                                                        colors: [Color.red, Color.red.opacity(0.7)],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    ))
                                            )
                                    }
                                }
                                
                                Text("Critical alerts are essential for reliable alarm behavior. They allow sounds to play even when your device is in silent mode or Do Not Disturb is on.")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                    .padding(.top, 5)
                                
                                if !notificationManager.isCriticalAlertsAuthorized {
                                    Text("Enable critical alerts in your device settings to ensure alarms sound even when your phone is on silent or in Do Not Disturb mode.")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.yellow.opacity(0.9))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                        .padding(.top, 2)
                                }
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 12)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(15)
                            .padding(.horizontal, 8)
                        }
                        
                        // Show Presets UI if hidden from main settings
                        if presetManager.isHiddenFromMainSettings {
                            PresetUI()
                                .transition(.move(edge: .trailing))
                                .animation(.easeInOut(duration: 0.3), value: presetsRefreshTrigger)
                                .id("presetUI-\(presetsRefreshTrigger)")
                        }
                        
                        // AUDIO SETTINGS SECTION - Combine AudioOutput and AudioVolume in one cubby
                        if audioManager.isHiddenFromMainSettings || AudioVolumeManager.shared.isHiddenFromMainSettings || alarmSoundManager.isHiddenFromMainSettings {
                            VStack(alignment: .center, spacing: 15) {
                                // Section header
                                Text("Audio Settings")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                
                                Divider()
                                    .background(Color.gray.opacity(0.5))
                                    .padding(.horizontal)
                                
                                // Audio Output UI if hidden from main settings
                                if audioManager.isHiddenFromMainSettings {
                                    VStack(alignment: .center, spacing: 10) {
                                        AudioOutputUI()
                                    }
                                    .padding(.bottom, 10)
                                    .transition(.move(edge: .trailing))
                                    .animation(.easeInOut(duration: 0.3), value: audioOutputRefreshTrigger)
                                    .id("audioOutputUI-\(audioOutputRefreshTrigger)")
                                }
                                
                                // Add a divider between components if multiple are shown
                                if (audioManager.isHiddenFromMainSettings && AudioVolumeManager.shared.isHiddenFromMainSettings) ||
                                   (audioManager.isHiddenFromMainSettings && alarmSoundManager.isHiddenFromMainSettings) ||
                                   (AudioVolumeManager.shared.isHiddenFromMainSettings && alarmSoundManager.isHiddenFromMainSettings) {
                                    Divider()
                                        .background(Color.gray.opacity(0.5))
                                        .padding(.horizontal, 30)
                                        .padding(.vertical, 5)
                                }
                                
                                // Audio Volume UI if hidden from main settings
                                if AudioVolumeManager.shared.isHiddenFromMainSettings {
                                    VStack(alignment: .center, spacing: 10) {
                                        AudioVolumeUI()
                                    }
                                    .padding(.top, 5)
                                    .transition(.move(edge: .trailing))
                                    .animation(.easeInOut(duration: 0.3), value: volumeRefreshTrigger)
                                    .id("volumeUI-\(volumeRefreshTrigger)")
                                }
                                
                                // Add a divider before alarm sound if needed
                                if (audioManager.isHiddenFromMainSettings || AudioVolumeManager.shared.isHiddenFromMainSettings) && 
                                   alarmSoundManager.isHiddenFromMainSettings {
                                    Divider()
                                        .background(Color.gray.opacity(0.5))
                                        .padding(.horizontal, 30)
                                        .padding(.vertical, 5)
                                }
                                
                                // Alarm Sound Selector if hidden from main settings
                                if alarmSoundManager.isHiddenFromMainSettings {
                                    VStack(alignment: .center, spacing: 10) {
                                        AlarmSoundSelector(
                                            selectedAlarm: $timerManager.selectedAlarmSound,
                                            onPreview: timerManager.previewAlarmSound
                                        )
                                    }
                                    .padding(.top, 5)
                                    .transition(.move(edge: .trailing))
                                    .animation(.easeInOut(duration: 0.3), value: presetsRefreshTrigger)
                                    .id("alarmSoundUI-\(presetsRefreshTrigger)")
                                }
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 12)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(15)
                            .padding(.horizontal, 8)
                            .padding(.top, 10)
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
                            
                            Toggle("Show FS Touch Mode line", isOn: $timerManager.showConnectingLine)
                                .padding(.horizontal)
                                .onChange(of: timerManager.showConnectingLine) { _ in
                                    timerManager.saveSettings()
                                }
                            
                            // Circle size control when hidden from main settings
                            if circleSizeManager.isHiddenFromMainSettings {
                                Divider()
                                    .background(Color.gray.opacity(0.5))
                                    .padding(.horizontal)
                                    .padding(.vertical, 5)
                                
                                CircleSizeControl(
                                    textInputValue: $textInputValue,
                                    onValueChanged: {
                                        // Preview isn't needed in advanced settings
                                    }
                                )
                                .padding(.horizontal, 8)
                            }
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 12)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(15)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 12)
                        
                        // Backup Notification Settings Section (moved to bottom)
                        // Always show regardless of critical alerts status
                        VStack(alignment: .center, spacing: 15) {
                            
                            HStack(spacing: 12) {
                                Image(systemName: notificationManager.isNotificationAuthorized ? 
                                      "bell.badge.fill" : "bell.slash.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(notificationManager.isNotificationAuthorized ? 
                                                    Color.blue : Color.orange)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Backup Notifications")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    if notificationManager.isCriticalAlertsAuthorized {
                                        Text("Regular notifications serve as a backup if critical alerts fail or if the app is completely terminated.")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.8))
                                            .fixedSize(horizontal: false, vertical: true)
                                    } else {
                                        Text(notificationManager.isNotificationAuthorized ? 
                                             "You'll see a banner when your nap time is over." : 
                                             "Currently disabled.")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.8))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                                
                                Spacer()
                                
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
                                         "Manage" : "Enable")
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
                            }
                            .padding(.horizontal)
                            .padding(.top, 5)
                        
                            // Show notification warning if hidden from main settings and notifications not authorized
                            if !notificationManager.isNotificationAuthorized && notificationManager.isHiddenFromMainSettings {
                                // Use NotificationPermissionWarning without the Hide button
                                NotificationPermissionWarning(showHideButton: false)
                                    .padding(.bottom, 10)
                            }
                            
                            // Add CAF Sound Selection (only when notifications are authorized)
                            if notificationManager.isNotificationAuthorized {
                                Divider()
                                    .background(Color.gray.opacity(0.5))
                                    .padding(.horizontal)
                                    .padding(.vertical, 5)
                                
                                // Sound controls without nested cell styling
                                VStack(spacing: 15) {
                                    // CAF sound selector component
                                    CAFSoundSelector()
                                    
                                    Divider()
                                        .background(Color.gray.opacity(0.5))
                                        .padding(.horizontal, 30)
                                    
                                    // CAF notification test component
                                    NotificationTestUI()
                                }
                            }
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 12)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(15)
                        .padding(.horizontal, 8)
                        .padding(.top, 10)
                        .padding(.bottom, 16)
                    }
                }
                .padding(.top, 10)
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
            
            // Add observer for audio output UI state changes
            NotificationCenter.default.addObserver(forName: .audioOutputUIStateChanged, object: nil, queue: .main) { _ in
                // Toggle the refresh trigger to force UI update
                withAnimation {
                    self.audioOutputRefreshTrigger.toggle()
                }
            }

            // Add observer for volume UI state changes
            NotificationCenter.default.addObserver(forName: .audioVolumeUIStateChanged, object: nil, queue: .main) { _ in
                // Toggle the refresh trigger to force UI update
                withAnimation {
                    self.volumeRefreshTrigger.toggle()
                }
            }

            // Add observer for circle size UI state changes
            NotificationCenter.default.addObserver(forName: .circleSizeUIStateChanged, object: nil, queue: .main) { _ in
                // Toggle the refresh trigger to force UI update
                withAnimation {
                    self.circleSizeRefreshTrigger.toggle()
                }
            }
        }
        .onDisappear {
            // Save orientation settings when leaving the screen
            orientationManager.saveSettings(forceOverride: true)
            
            // Remove the observer when view disappears
            NotificationCenter.default.removeObserver(self, name: .presetUIStateChanged, object: nil)
            NotificationCenter.default.removeObserver(self, name: .audioOutputUIStateChanged, object: nil)
            NotificationCenter.default.removeObserver(self, name: .audioVolumeUIStateChanged, object: nil)
            NotificationCenter.default.removeObserver(self, name: .circleSizeUIStateChanged, object: nil)
        }
    }
}

#Preview {
    AdvancedSettingsScreen()
} 

