import SwiftUI

// MARK: - Haptic Feedback Manager
class HapticManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isHapticEnabled = true
    @Published var hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .medium
    
    // Add a property to store the current alarm vibration timer
    var alarmVibrationTimer: Timer?
    // Track whether vibration is active
    var isAlarmVibrationActive = false
    
    // MARK: - Singleton Instance
    static let shared = HapticManager()
    
    // MARK: - UserDefaults Keys
    private enum UserDefaultsKeys {
        static let isHapticEnabled = "isHapticEnabled"
        static let hapticStyle = "hapticStyle"
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
    
    /// Triggers notification haptic feedback
    /// - Parameter type: The type of notification feedback
    func triggerNotification(type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isHapticEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
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
        // First stop the flag to prevent any queued vibrations
        isAlarmVibrationActive = false
        
        // Stop and clear any timers
        if let timer = alarmVibrationTimer {
            timer.invalidate()
            alarmVibrationTimer = nil
        }
        
        // For good measure, trigger a silent notification to reset iOS haptic state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // This empty impact may help reset the haptic engine state
            let silentGenerator = UIImpactFeedbackGenerator(style: .light)
            silentGenerator.prepare()
        }
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
