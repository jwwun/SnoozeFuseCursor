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
    
    // MARK: - Private Properties
    // Timers and state tracking
    private var alarmVibrationTimer: Timer?
    private var bpmPulseTimer: Timer?
    private var bpmSecondBeatTimer: Timer?
    
    // State flags
    private(set) var isAlarmVibrationActive = false
    private(set) var isBPMPulsing = false
    
    // Debounce handling
    private var lastPulseStartTime: Date = Date(timeIntervalSince1970: 0)
    private var pendingPulseWorkItems: [DispatchWorkItem] = []
    
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
    
    // MARK: - Basic Haptic Feedback
    
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
    func triggerNotification(type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isHapticEnabled else { return }
        
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    // MARK: - BPM Heartbeat Control
    
    /// Starts pulsing haptic feedback with realistic double-beat heart pattern
    func startBPMPulse() {
        // Don't start if haptics are disabled or already pulsing
        guard isHapticEnabled && isBPMPulseEnabled && !isBPMPulsing else { return }
        
        // Add debouncing to prevent rapid re-triggers
        let now = Date()
        if now.timeIntervalSince(lastPulseStartTime) < 0.2 {
            // Too soon since last pulse started, ignore this request
            return
        }
        lastPulseStartTime = now
        
        // Stop any existing pulse
        stopBPMPulse()
        
        // Mark pulsing as active
        isBPMPulsing = true
        objectWillChange.send()
        
        // Calculate timing based on BPM
        let interval = 60.0 / bpmValue  // Convert BPM to seconds
        let secondBeatDelay = interval * 0.3  // Second beat after 30% of interval
        
        // Initial pulse sequence
        playHeartbeatSequence(interval: interval, secondBeatDelay: secondBeatDelay)
        
        // Set up repeating timer for heartbeat pattern
        bpmPulseTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self, self.isBPMPulsing else { return }
            self.playHeartbeatSequence(interval: interval, secondBeatDelay: secondBeatDelay)
        }
    }
    
    /// Plays a single heartbeat sequence (main + second beat)
    private func playHeartbeatSequence(interval: Double, secondBeatDelay: Double) {
        // First beat (stronger)
        trigger()
        
        // Cancel any pending work items to prevent overlapping effects
        cancelPendingPulseWorkItems()
        
        // Schedule second beat after delay
        let secondBeatWorkItem = DispatchWorkItem { [weak self] in
            guard let self = self, self.isBPMPulsing else { return }
            self.triggerSecondBeat()
        }
        pendingPulseWorkItems.append(secondBeatWorkItem)
        DispatchQueue.main.asyncAfter(deadline: .now() + secondBeatDelay, execute: secondBeatWorkItem)
    }
    
    /// Cancels any pending haptic pulse work items
    private func cancelPendingPulseWorkItems() {
        pendingPulseWorkItems.forEach { $0.cancel() }
        pendingPulseWorkItems.removeAll()
    }
    
    /// Stops the BPM pulse
    func stopBPMPulse() {
        // Only notify if state is changing
        let wasActive = isBPMPulsing
        
        // Update state
        isBPMPulsing = false
        
        // Cancel any pending work items
        cancelPendingPulseWorkItems()
        
        // Clean up timers
        bpmPulseTimer?.invalidate()
        bpmPulseTimer = nil
        
        bpmSecondBeatTimer?.invalidate()
        bpmSecondBeatTimer = nil
        
        // Notify listeners if there was a state change
        if wasActive {
            objectWillChange.send()
        }
    }
    
    // MARK: - Alarm Vibration
    
    /// Triggers a continuous alarm vibration pattern
    @discardableResult
    func triggerAlarmVibration() -> Timer? {
        guard isHapticEnabled else { return nil }
        
        // Stop any existing vibration first
        stopAlarmVibration()
        
        // Mark vibration as active
        isAlarmVibrationActive = true
        
        // Initial vibration (strongest pattern)
        triggerNotification(type: .error)
        
        // Set up recurring pattern
        alarmVibrationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isAlarmVibrationActive else { return }
            
            // Main vibration
            self.triggerNotification(type: .error)
            
            // Secondary vibration after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self, self.isAlarmVibrationActive else { return }
                
                let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
                heavyGenerator.impactOccurred()
            }
        }
        
        return alarmVibrationTimer
    }
    
    /// Stops the alarm vibration
    func stopAlarmVibration() {
        // Update state flag first to prevent queued haptics
        isAlarmVibrationActive = false
        
        // Clean up timer
        alarmVibrationTimer?.invalidate()
        alarmVibrationTimer = nil
    }
    
    /// Emergency method to stop all haptic feedback
    func killAllSystemSounds() {
        // Stop alarm vibration
        isAlarmVibrationActive = false
        alarmVibrationTimer?.invalidate()
        alarmVibrationTimer = nil
        
        // Also stop BPM pulse
        stopBPMPulse()
    }
    
    // MARK: - Settings Persistence
    
    /// Saves all haptic settings to UserDefaults
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
        
        // Load haptic enabled state
        if defaults.object(forKey: UserDefaultsKeys.isHapticEnabled) != nil {
            isHapticEnabled = defaults.bool(forKey: UserDefaultsKeys.isHapticEnabled)
        }
        
        // Load haptic style
        if let styleRawValue = defaults.object(forKey: UserDefaultsKeys.hapticStyle) as? Int,
           let style = UIImpactFeedbackGenerator.FeedbackStyle(rawValue: styleRawValue) {
            hapticStyle = style
        }
        
        // Load BPM pulse enabled state
        if defaults.object(forKey: UserDefaultsKeys.isBPMPulseEnabled) != nil {
            isBPMPulseEnabled = defaults.bool(forKey: UserDefaultsKeys.isBPMPulseEnabled)
        }
        
        // Set visual heartbeat to true by default first time
        if defaults.object(forKey: UserDefaultsKeys.isVisualHeartbeatEnabled) != nil {
            isVisualHeartbeatEnabled = defaults.bool(forKey: UserDefaultsKeys.isVisualHeartbeatEnabled)
        } else {
            isVisualHeartbeatEnabled = true
            defaults.set(true, forKey: UserDefaultsKeys.isVisualHeartbeatEnabled)
        }
        
        // Load BPM value
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
