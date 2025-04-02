import SwiftUI

// MARK: - Haptic Feedback Manager
class HapticManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isHapticEnabled = true
    @Published var hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .medium
    
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
                Text("HAPTIC FEEDBACK")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Color.blue.opacity(0.7))
                    .tracking(3)
                    .padding(.bottom, 5)
                    .frame(maxWidth: .infinity, alignment: .center)
                
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
