import SwiftUI
import AudioToolbox
import AVFoundation

// MARK: - Haptic Feedback Manager
class HapticManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isHapticEnabled = true
    @Published var hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .medium
    @Published var isBPMPulseEnabled = true
    @Published var isVisualHeartbeatEnabled = true
    @Published var bpmValue: Double = 60 // Default BPM value
    
    // Add a property to store the current alarm vibration timer
    var alarmVibrationTimer: Timer?
    // Track whether vibration is active
    var isAlarmVibrationActive = false
    // BPM pulse timer
    var bpmPulseTimer: Timer?
    // BPM second beat timer (for double-beat effect)
    var bpmSecondBeatTimer: Timer?
    // Track if BPM pulsing is active
    var isBPMPulsing = false
    
    // MARK: - Singleton Instance
    static let shared = HapticManager()
    
    // MARK: - UserDefaults Keys
    private enum UserDefaultsKeys {
        static let isHapticEnabled = "isHapticEnabled"
        static let hapticStyle = "hapticStyle"
        static let isBPMPulseEnabled = "isBPMPulseEnabled"
        static let isVisualHeartbeatEnabled = "isVisualHeartbeatEnabled"
        static let bpmValue = "bpmValue"
    }
    
    // MARK: - Initialization
    private init() {
        loadSettings()
    }
    
    // MARK: - Haptic Feedback Methods
    
    /// Triggers impact haptic feedback with the current style
    func trigger() {
        guard isHapticEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: hapticStyle)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Triggers a softer haptic feedback for the second beat
    func triggerSecondBeat() {
        guard isHapticEnabled else { return }
        // Use a lighter feedback for the second beat
        let style: UIImpactFeedbackGenerator.FeedbackStyle
        
        switch hapticStyle {
        case .heavy:
            style = .medium
        case .medium:
            style = .light
        default:
            style = .light
        }
        
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred(intensity: 0.7) // Reduced intensity
    }
    
    /// Triggers notification haptic feedback
    /// - Parameter type: The type of notification feedback
    func triggerNotification(type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isHapticEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    /// Starts pulsing haptic feedback at the current BPM with realistic double-beat pattern
    func startBPMPulse() {
        guard isHapticEnabled && isBPMPulseEnabled && !isBPMPulsing else { return }
        
        // Stop any existing pulse
        stopBPMPulse()
        
        // Calculate interval in seconds based on BPM
        let beatsPerSecond = bpmValue / 60.0
        let mainInterval = 1.0 / beatsPerSecond 
        let secondBeatDelay = mainInterval * 0.3 // Second beat comes 30% after first beat
        
        // Mark pulsing as active
        isBPMPulsing = true
        
        // Notify listeners of state change
        objectWillChange.send()
        
        // Initial pulse
        trigger()
        
        // Schedule second beat for initial heartbeat
        DispatchQueue.main.asyncAfter(deadline: .now() + secondBeatDelay) {
            // Only trigger if still pulsing
            if self.isBPMPulsing {
                self.triggerSecondBeat()
            }
        }
        
        // Create a repeating timer for the first beat of each pulse
        bpmPulseTimer = Timer.scheduledTimer(withTimeInterval: mainInterval, repeats: true) { [weak self] _ in
            guard let self = self, self.isBPMPulsing else { return }
            
            // First beat (stronger)
            self.trigger()
            
            // Schedule second beat after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + secondBeatDelay) {
                // Only trigger if still pulsing
                if self.isBPMPulsing {
                    self.triggerSecondBeat()
                }
            }
        }
    }
    
    /// Stops the BPM pulse
    func stopBPMPulse() {
        // Only send change notification if we're actually changing state
        let wasActive = isBPMPulsing
        
        isBPMPulsing = false
        
        if let timer = bpmPulseTimer {
            timer.invalidate()
            bpmPulseTimer = nil
            
            // Only notify if there was an actual state change
            if wasActive {
                objectWillChange.send()
            }
        }
        
        if let timer = bpmSecondBeatTimer {
            timer.invalidate()
            bpmSecondBeatTimer = nil
        }
    }
    
    /// Triggers a continuous alarm vibration pattern
    /// - Returns: Timer that controls the vibration loop (can be used to stop vibration)
    @discardableResult
    func triggerAlarmVibration() -> Timer? {
        guard isHapticEnabled else { return nil }
        
        // Stop any existing vibration first
        stopAlarmVibration()
        
        // Mark vibration as active
        isAlarmVibrationActive = true
        
        // Use error notification for first hit (strongest vibration pattern)
        triggerNotification(type: .error)
        
        // Create a repeating timer to trigger vibrations in a pattern
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isAlarmVibrationActive else { return }
            
            // Alternating pattern of different vibrations for a more noticeable effect
            self.triggerNotification(type: .error)
            
            // Add secondary vibration with slight delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Use heavy impact for second vibration in pattern
                if self.isAlarmVibrationActive {
                    let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
                    heavyGenerator.impactOccurred()
                }
            }
        }
        
        // Store the timer reference for later cancellation
        alarmVibrationTimer = timer
        
        return timer
    }
    
    /// Stops the alarm vibration completely
    func stopAlarmVibration() {
        print("🚨 HapticManager: Stopping vibration TIMER and FLAG ONLY")
        
        // First stop the flag to prevent any queued vibrations
        isAlarmVibrationActive = false
        
        // Stop and clear any timers
        if let timer = alarmVibrationTimer {
            print("Invalidating HapticManager timer")
            timer.invalidate()
            alarmVibrationTimer = nil
        }
    }
    
    /// Last resort method to kill all system sounds and vibrations
    /// This targets the underlying system sound mechanism directly
    func killAllSystemSounds() {
        print("🚨 Emergency vibration kill initiated - SIMPLIFIED (NO SYSTEM CALLS)")
        
        // ONLY stop the timer and reset the flag here
        isAlarmVibrationActive = false
        if let timer = alarmVibrationTimer {
            print("Invalidating HapticManager timer from killAllSystemSounds")
            timer.invalidate()
            alarmVibrationTimer = nil
        }
        
        // Also stop BPM pulse
        stopBPMPulse()
    }
    
    /// Legacy method - redirects to stopAlarmVibration()
    func stopAlarmVibration(timer: Timer?) {
        stopAlarmVibration()
    }
    
    // MARK: - Settings Persistence
    
    /// Saves haptic settings to UserDefaults
    func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(isHapticEnabled, forKey: UserDefaultsKeys.isHapticEnabled)
        defaults.set(hapticStyle.rawValue, forKey: UserDefaultsKeys.hapticStyle)
        defaults.set(isBPMPulseEnabled, forKey: UserDefaultsKeys.isBPMPulseEnabled)
        defaults.set(isVisualHeartbeatEnabled, forKey: UserDefaultsKeys.isVisualHeartbeatEnabled)
        defaults.set(bpmValue, forKey: UserDefaultsKeys.bpmValue)
    }
    
    /// Loads haptic settings from UserDefaults
    private func loadSettings() {
        let defaults = UserDefaults.standard
        
        if defaults.object(forKey: UserDefaultsKeys.isHapticEnabled) != nil {
            isHapticEnabled = defaults.bool(forKey: UserDefaultsKeys.isHapticEnabled)
        }
        
        if let styleRawValue = defaults.object(forKey: UserDefaultsKeys.hapticStyle) as? Int,
           let style = UIImpactFeedbackGenerator.FeedbackStyle(rawValue: styleRawValue) {
            hapticStyle = style
        }
        
        if defaults.object(forKey: UserDefaultsKeys.isBPMPulseEnabled) != nil {
            isBPMPulseEnabled = defaults.bool(forKey: UserDefaultsKeys.isBPMPulseEnabled)
        }
        
        // Set visual heartbeat to true by default when first running the app
        if defaults.object(forKey: UserDefaultsKeys.isVisualHeartbeatEnabled) != nil {
            isVisualHeartbeatEnabled = defaults.bool(forKey: UserDefaultsKeys.isVisualHeartbeatEnabled)
        } else {
            isVisualHeartbeatEnabled = true
            defaults.set(true, forKey: UserDefaultsKeys.isVisualHeartbeatEnabled)
        }
        
        if defaults.object(forKey: UserDefaultsKeys.bpmValue) != nil {
            bpmValue = defaults.double(forKey: UserDefaultsKeys.bpmValue)
        }
    }
}

// MARK: - SettingsScreen Extension for Haptic Settings UI
extension SettingsScreen {
    struct HapticSettings: View {
        @ObservedObject var hapticManager = HapticManager.shared
        
        var body: some View {
            VStack(alignment: .center, spacing: 15) {

                
                Toggle("Enable Haptics", isOn: $hapticManager.isHapticEnabled)
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
        }
    }
} 
