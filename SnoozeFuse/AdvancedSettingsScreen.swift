import SwiftUI
import UserNotifications

struct AdvancedSettingsScreen: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var hapticManager = HapticManager.shared
    @ObservedObject var orientationManager = OrientationManager.shared
    @ObservedObject var notificationManager = NotificationManager.shared
    @ObservedObject var mediaLibraryManager = MediaLibraryManager.shared
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
    
    // Collapsible section states
    @State private var notificationsExpanded = false
    @State private var presetsExpanded = false
    @State private var audioExpanded = false
    @State private var hapticsExpanded = false
    @State private var orientationExpanded = false
    @State private var visualExpanded = false
    @State private var criticalAlertsExpanded = false
    @State private var criticalAlertsSubsectionExpanded = false
    
    // UserDefaultsKeys enum for section collapse states
    private enum UserDefaultsKeys {
        static let notificationsExpanded = "advancedNotificationsExpanded"
        static let presetsExpanded = "advancedPresetsExpanded"
        static let audioExpanded = "advancedAudioExpanded"
        static let hapticsExpanded = "advancedHapticsExpanded"
        static let orientationExpanded = "advancedOrientationExpanded"
        static let visualExpanded = "advancedVisualExpanded"
        static let criticalAlertsExpanded = "advancedCriticalAlertsExpanded"
        static let criticalAlertsSubsectionExpanded = "advancedCriticalAlertsSubsectionExpanded"
    }
    
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
                    VStack(spacing: 15) {
                        // App Notifications Section (moved to the TOP)
                        CollapsibleSection(
                            title: "Notifications",
                            icon: "bell.badge.fill",
                            isExpanded: $notificationsExpanded
                        ) {
                            VStack(spacing: 15) {
                                HStack(spacing: 12) {
                                    Image(systemName: notificationManager.isNotificationAuthorized ? 
                                          "bell.badge.fill" : "bell.slash.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(notificationManager.isNotificationAuthorized ? 
                                                        Color.blue : Color.orange)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("App Notifications")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                        
                                        Text(notificationManager.isNotificationAuthorized ? 
                                             "Notifications are enabled. You'll be alerted when your nap timer ends." : 
                                             "Notifications are disabled. Enable them to receive alerts when your nap ends.")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.8))
                                            .fixedSize(horizontal: false, vertical: true)
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
                                             "Settings" : "Enable")
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
                                
                                // Show media library warning if hidden from main settings and media library not authorized
                                if !mediaLibraryManager.isMediaLibraryAuthorized && mediaLibraryManager.isHiddenFromMainSettings {
                                    // Use MediaLibraryPermissionWarning without the Hide button
                                    MediaLibraryPermissionWarning(showHideButton: false)
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
                                
                                // Add Critical Alerts section inside Notifications
                                Divider()
                                    .background(Color.gray.opacity(0.5))
                                    .padding(.horizontal)
                                    .padding(.vertical, 5)
                                
                                // Collapsible Critical Alerts section
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        criticalAlertsSubsectionExpanded.toggle()
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "bell.and.waves.left.and.right")
                                            .font(.system(size: 16))
                                            .foregroundColor(.orange)
                                            .frame(width: 20, height: 20)
                                        
                                        Text("Critical Alerts Status")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Text("Not available in this version")
                                            .font(.system(size: 12))
                                            .foregroundColor(.orange.opacity(0.8))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(Color.orange.opacity(0.1))
                                            .cornerRadius(4)
                                        
                                        Image(systemName: criticalAlertsSubsectionExpanded ? "chevron.up" : "chevron.down")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal)
                                
                                if criticalAlertsSubsectionExpanded {
                                    CriticalAlertStatusControl()
                                        .padding(.horizontal, 4)
                                        .padding(.bottom, 5)
                                        .transition(.move(edge: .top).combined(with: .opacity))
                                }
                            }
                            .padding(.bottom, 5)
                        }
                        
                        // Show Presets UI if hidden from main settings
                        if presetManager.isHiddenFromMainSettings {
                            CollapsibleSection(
                                title: "Timer Presets", 
                                icon: "clock.arrow.2.circlepath",
                                isExpanded: $presetsExpanded
                            ) {
                                PresetUI()
                                    .transition(.move(edge: .trailing))
                                    .animation(.easeInOut(duration: 0.3), value: presetsRefreshTrigger)
                                    .id("presetUI-\(presetsRefreshTrigger)")
                                    .padding(.bottom, 5)
                            }
                        }
                        
                        // AUDIO SETTINGS SECTION - Combine AudioOutput and AudioVolume in one cubby
                        if audioManager.isHiddenFromMainSettings || AudioVolumeManager.shared.isHiddenFromMainSettings || alarmSoundManager.isHiddenFromMainSettings {
                            CollapsibleSection(
                                title: "Audio Settings",
                                icon: "speaker.wave.3.fill",
                                isExpanded: $audioExpanded
                            ) {
                                VStack(alignment: .center, spacing: 15) {
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
                                .padding(.bottom, 5)
                            }
                        }
                        
                        // Haptic Settings Section
                        CollapsibleSection(
                            title: "Haptic Feedback",
                            icon: "iphone.radiowaves.left.and.right",
                            isExpanded: $hapticsExpanded
                        ) {
                            VStack(alignment: .center, spacing: 15) {
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
                                    
                                    // BPM Settings
                                    Divider()
                                        .background(Color.gray.opacity(0.5))
                                        .padding(.horizontal)
                                        .padding(.vertical, 5)
                                    
                                    // Improved heading for haptic heartbeat section
                                    Text("Heartbeat Haptic Feedback")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white.opacity(0.9))
                                        .padding(.bottom, 4)
                                    
                                    // BPM Pulse Toggle
                                    Toggle("Enable heartbeat haptic feedback", isOn: $hapticManager.isBPMPulseEnabled)
                                        .padding(.horizontal)
                                        .onChange(of: hapticManager.isBPMPulseEnabled) { _ in
                                            hapticManager.saveSettings()
                                            // Don't automatically start the pulse when toggled on
                                            if !hapticManager.isBPMPulseEnabled {
                                                hapticManager.stopBPMPulse()
                                            }
                                        }
                                    
                                    if hapticManager.isBPMPulseEnabled {
                                        // BPM Value Control
                                        VStack(spacing: 5) {
                                            HStack {
                                                Text("BPM: \(Int(hapticManager.bpmValue))")
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(.white.opacity(0.9))
                                                    .frame(width: 70, alignment: .leading)
                                                
                                                Spacer()
                                                
                                                // Improved test button
                                                Button(action: {
                                                    // Toggle BPM pulse
                                                    if hapticManager.isBPMPulsing {
                                                        hapticManager.stopBPMPulse()
                                                    } else {
                                                        hapticManager.startBPMPulse()
                                                    }
                                                    // Force UI refresh
                                                    withAnimation {
                                                        hapticManager.objectWillChange.send()
                                                    }
                                                }) {
                                                    HStack(spacing: 6) {
                                                        Image(systemName: hapticManager.isBPMPulsing ? "stop.fill" : "play.fill")
                                                            .font(.system(size: 10))
                                                        Text(hapticManager.isBPMPulsing ? "Stop" : "Test")
                                                            .font(.system(size: 13))
                                                    }
                                                    .foregroundColor(.white)
                                                    .padding(.vertical, 5)
                                                    .padding(.horizontal, 12)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 6)
                                                            .fill(hapticManager.isBPMPulsing ? Color.red.opacity(0.7) : Color.blue.opacity(0.6))
                                                    )
                                                }
                                            }
                                            .padding(.horizontal)
                                            
                                            // BPM slider with better visual design
                                            Slider(
                                                value: $hapticManager.bpmValue,
                                                in: 40...120,
                                                step: 1.0,
                                                onEditingChanged: { _ in
                                                    hapticManager.saveSettings()
                                                    if hapticManager.isBPMPulsing {
                                                        // Restart the pulse with new BPM
                                                        hapticManager.stopBPMPulse()
                                                        hapticManager.startBPMPulse()
                                                    }
                                                }
                                            )
                                            .accentColor(Color.purple.opacity(0.7))
                                            .padding(.horizontal)
                                            
                                            // Add BPM range indicators
                                            HStack {
                                                Text("40")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.white.opacity(0.5))
                                                Spacer()
                                                Text("Heart Rate (BPM)")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.white.opacity(0.7))
                                                Spacer()
                                                Text("120")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.white.opacity(0.5))
                                            }
                                            .padding(.horizontal)
                                        }
                                        .padding(.top, 5)
                                        
                                        // Visual indicator for test mode
                                        if hapticManager.isBPMPulsing {
                                            Text("Press the red button to stop the test")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.red.opacity(0.9))
                                                .padding(.top, 5)
                                        }
                                    }
                                    
                                    // Explanation text with better formatting
                                    Text("Heartbeat feedback produces a realistic double-pulse haptic pattern at the selected BPM. The visual animation can be enabled separately in Visual Settings.")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.7))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                        .padding(.top, 5)
                                        .padding(.bottom, 2)
                                }
                            }
                            .padding(.bottom, 5)
                        }
                        
                        // Orientation Settings
                        CollapsibleSection(
                            title: "Orientation Settings",
                            icon: "rotate.right",
                            isExpanded: $orientationExpanded
                        ) {
                            OrientationSettings()
                                .padding(.bottom, 5)
                        }
                        
                        // Visual Settings Section
                        CollapsibleSection(
                            title: "Visual Settings",
                            icon: "eye.fill",
                            isExpanded: $visualExpanded
                        ) {
                            VStack(alignment: .center, spacing: 15) {
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
                                
                                // Heartbeat visual toggle
                                Toggle("Show heartbeat animation on touch", isOn: $hapticManager.isVisualHeartbeatEnabled)
                                    .padding(.horizontal)
                                    .onChange(of: hapticManager.isVisualHeartbeatEnabled) { _ in
                                        hapticManager.saveSettings()
                                    }
                                
                                Divider()
                                    .background(Color.gray.opacity(0.5))
                                    .padding(.horizontal)
                                    .padding(.vertical, 5)
                                
                                // New animation toggles section
                                Text("Touch Animations")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.blue.opacity(0.8))
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.bottom, 5)
                                
                                Toggle("Ripple effect when pressing", isOn: $timerManager.showRippleEffects)
                                    .padding(.horizontal)
                                    .onChange(of: timerManager.showRippleEffects) { _ in
                                        timerManager.saveSettings()
                                    }
                                
                                Toggle("Mini animations when resetting", isOn: $timerManager.showMiniAnimations)
                                    .padding(.horizontal)
                                    .onChange(of: timerManager.showMiniAnimations) { _ in
                                        timerManager.saveSettings()
                                    }
                                
                                Toggle("Touch feedback in full-screen mode", isOn: $timerManager.showTouchFeedback)
                                    .padding(.horizontal)
                                    .onChange(of: timerManager.showTouchFeedback) { _ in
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
                            .padding(.bottom, 5)
                        }
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
            
            // Refresh media library status
            mediaLibraryManager.checkMediaLibraryPermission()
            
            // Load collapse states
            loadCollapseStates()
            
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
        .onChange(of: notificationsExpanded) { _ in saveCollapseStates() }
        .onChange(of: presetsExpanded) { _ in saveCollapseStates() }
        .onChange(of: audioExpanded) { _ in saveCollapseStates() }
        .onChange(of: hapticsExpanded) { _ in saveCollapseStates() }
        .onChange(of: orientationExpanded) { _ in saveCollapseStates() }
        .onChange(of: visualExpanded) { _ in saveCollapseStates() }
        .onChange(of: criticalAlertsExpanded) { _ in saveCollapseStates() }
        .onChange(of: criticalAlertsSubsectionExpanded) { _ in saveCollapseStates() }
        .onDisappear {
            // Save orientation settings when leaving the screen
            orientationManager.saveSettings(forceOverride: true)
            
            // Remove the observer when view disappears
            NotificationCenter.default.removeObserver(self, name: .presetUIStateChanged, object: nil)
            NotificationCenter.default.removeObserver(self, name: .audioOutputUIStateChanged, object: nil)
            NotificationCenter.default.removeObserver(self, name: .audioVolumeUIStateChanged, object: nil)
            NotificationCenter.default.removeObserver(self, name: .circleSizeUIStateChanged, object: nil)
            
            // Save collapse states
            saveCollapseStates()
        }
    }
    
    // Save collapse states
    private func saveCollapseStates() {
        UserDefaults.standard.set(notificationsExpanded, forKey: UserDefaultsKeys.notificationsExpanded)
        UserDefaults.standard.set(presetsExpanded, forKey: UserDefaultsKeys.presetsExpanded)
        UserDefaults.standard.set(audioExpanded, forKey: UserDefaultsKeys.audioExpanded)
        UserDefaults.standard.set(hapticsExpanded, forKey: UserDefaultsKeys.hapticsExpanded)
        UserDefaults.standard.set(orientationExpanded, forKey: UserDefaultsKeys.orientationExpanded)
        UserDefaults.standard.set(visualExpanded, forKey: UserDefaultsKeys.visualExpanded)
        UserDefaults.standard.set(criticalAlertsExpanded, forKey: UserDefaultsKeys.criticalAlertsExpanded)
        UserDefaults.standard.set(criticalAlertsSubsectionExpanded, forKey: UserDefaultsKeys.criticalAlertsSubsectionExpanded)
    }
    
    // Load collapse states
    private func loadCollapseStates() {
        notificationsExpanded = UserDefaults.standard.bool(forKey: UserDefaultsKeys.notificationsExpanded)
        presetsExpanded = UserDefaults.standard.bool(forKey: UserDefaultsKeys.presetsExpanded)
        audioExpanded = UserDefaults.standard.bool(forKey: UserDefaultsKeys.audioExpanded)
        hapticsExpanded = UserDefaults.standard.bool(forKey: UserDefaultsKeys.hapticsExpanded)
        orientationExpanded = UserDefaults.standard.bool(forKey: UserDefaultsKeys.orientationExpanded)
        visualExpanded = UserDefaults.standard.bool(forKey: UserDefaultsKeys.visualExpanded)
        criticalAlertsExpanded = UserDefaults.standard.bool(forKey: UserDefaultsKeys.criticalAlertsExpanded)
        criticalAlertsSubsectionExpanded = UserDefaults.standard.bool(forKey: UserDefaultsKeys.criticalAlertsSubsectionExpanded)
    }
}

// Extension to add defaultValue support for UserDefaults
extension UserDefaults {
    func bool(forKey key: String, defaultValue: Bool) -> Bool {
        if object(forKey: key) != nil {
            return bool(forKey: key)
        }
        return defaultValue
    }
}

#Preview {
    AdvancedSettingsScreen()
} 

