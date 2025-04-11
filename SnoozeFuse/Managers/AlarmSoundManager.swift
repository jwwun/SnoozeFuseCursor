import Foundation
import SwiftUI

// Notification name for alarm sound UI state changes
extension Notification.Name {
    static let alarmSoundUIStateChanged = Notification.Name("alarmSoundUIStateChanged")
}

// AlarmSoundManager for controlling UI visibility
class AlarmSoundManager: ObservableObject {
    static let shared = AlarmSoundManager()
    
    @Published var isHiddenFromMainSettings: Bool = false
    
    private init() {
        // Load saved settings from UserDefaults
        if UserDefaults.standard.object(forKey: "alarmSoundUIHidden") != nil {
            self.isHiddenFromMainSettings = UserDefaults.standard.bool(forKey: "alarmSoundUIHidden")
        } else {
            // Default to showing in main settings (not hidden)
            self.isHiddenFromMainSettings = false
            UserDefaults.standard.set(false, forKey: "alarmSoundUIHidden")
        }
        
        print("🔊 AlarmSoundManager initialized: isHidden = \(isHiddenFromMainSettings)")
    }
    
    func toggleHiddenState() {
        isHiddenFromMainSettings.toggle()
        // Save new hide state to UserDefaults
        UserDefaults.standard.set(isHiddenFromMainSettings, forKey: "alarmSoundUIHidden")
        
        // Notify UI to update
        NotificationCenter.default.post(name: .alarmSoundUIStateChanged, object: nil)
    }
} 