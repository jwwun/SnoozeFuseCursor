import SwiftUI

class HapticManager: ObservableObject {
    @Published var isHapticEnabled = true
    @Published var hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .medium
    
    static let shared = HapticManager()
    
    private init() {}
    
    func trigger() {
        guard isHapticEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: hapticStyle)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func triggerNotification(type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isHapticEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}

// Extension to add haptic settings to SettingsScreen
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
                
                if hapticManager.isHapticEnabled {
                    Picker("Intensity", selection: $hapticManager.hapticStyle) {
                        Text("Light").tag(UIImpactFeedbackGenerator.FeedbackStyle.light)
                        Text("Medium").tag(UIImpactFeedbackGenerator.FeedbackStyle.medium)
                        Text("Heavy").tag(UIImpactFeedbackGenerator.FeedbackStyle.heavy)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
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