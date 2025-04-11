import Foundation
import SwiftUI

class SettingsManager: ObservableObject {
    // Shared instance
    static let shared = SettingsManager()
    
    // Visual settings
    @Published var showTimerArcs: Bool = true
    @Published var showConnectingLine: Bool = true
    @Published var isFullScreenMode: Bool = false
    @Published var circleSize: CGFloat = 250
    
    // Timer durations (defaults)
    @Published var holdDuration: TimeInterval = 5    // Timer A: 5 seconds default
    @Published var napDuration: TimeInterval = 60    // Timer B: 1 minutes default
    @Published var maxDuration: TimeInterval = 120   // Timer C: 2 minutes default
    
    // Alarm sound settings
    @Published var selectedAlarmSound: AlarmSound = .testAlarm
    @Published var selectedCustomSoundID: UUID?
    
    // UserDefaults keys
    private enum UserDefaultsKeys {
        static let holdDuration = "holdDuration"
        static let napDuration = "napDuration"
        static let maxDuration = "maxDuration"
        static let circleSize = "circleSize"
        static let selectedAlarmSound = "selectedAlarmSound"
        static let selectedCustomSoundID = "selectedCustomSoundID"
        static let showTimerArcs = "showTimerArcs"
        static let showConnectingLine = "showConnectingLine"
        static let isFullScreenMode = "isFullScreenMode"
    }
    
    init() {
        loadSettings()
    }
    
    // Save all settings to UserDefaults
    func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(holdDuration, forKey: UserDefaultsKeys.holdDuration)
        defaults.set(napDuration, forKey: UserDefaultsKeys.napDuration)
        defaults.set(maxDuration, forKey: UserDefaultsKeys.maxDuration)
        defaults.set(circleSize, forKey: UserDefaultsKeys.circleSize)
        defaults.set(selectedAlarmSound.rawValue, forKey: UserDefaultsKeys.selectedAlarmSound)
        defaults.set(selectedCustomSoundID?.uuidString, forKey: UserDefaultsKeys.selectedCustomSoundID)
        defaults.set(showTimerArcs, forKey: UserDefaultsKeys.showTimerArcs)
        defaults.set(showConnectingLine, forKey: UserDefaultsKeys.showConnectingLine)
        defaults.set(isFullScreenMode, forKey: UserDefaultsKeys.isFullScreenMode)
        
        // Save custom sounds separately
        CustomSoundManager.shared.saveCustomSounds()
    }
    
    // Load all settings from UserDefaults
    func loadSettings() {
        let defaults = UserDefaults.standard
        
        if defaults.object(forKey: UserDefaultsKeys.holdDuration) != nil {
            holdDuration = defaults.double(forKey: UserDefaultsKeys.holdDuration)
        }
        
        if defaults.object(forKey: UserDefaultsKeys.napDuration) != nil {
            napDuration = defaults.double(forKey: UserDefaultsKeys.napDuration)
        }
        
        if defaults.object(forKey: UserDefaultsKeys.maxDuration) != nil {
            maxDuration = defaults.double(forKey: UserDefaultsKeys.maxDuration)
        }
        
        if defaults.object(forKey: UserDefaultsKeys.circleSize) != nil {
            circleSize = defaults.double(forKey: UserDefaultsKeys.circleSize)
        }
        
        if defaults.object(forKey: UserDefaultsKeys.showTimerArcs) != nil {
            showTimerArcs = defaults.bool(forKey: UserDefaultsKeys.showTimerArcs)
        }
        
        if defaults.object(forKey: UserDefaultsKeys.showConnectingLine) != nil {
            showConnectingLine = defaults.bool(forKey: UserDefaultsKeys.showConnectingLine)
        } else {
            // If not set yet, default to true (enabled by default)
            showConnectingLine = true
        }
        
        if defaults.object(forKey: UserDefaultsKeys.isFullScreenMode) != nil {
            isFullScreenMode = defaults.bool(forKey: UserDefaultsKeys.isFullScreenMode)
        }
        
        // Load selected alarm type
        if let soundValue = defaults.string(forKey: UserDefaultsKeys.selectedAlarmSound),
           let sound = AlarmSound(rawValue: soundValue) {
            selectedAlarmSound = sound
        }
        
        // Load selected custom sound ID
        if let idString = defaults.string(forKey: UserDefaultsKeys.selectedCustomSoundID),
           let id = UUID(uuidString: idString) {
            selectedCustomSoundID = id
        }
    }
    
    // Validation
    func validateTimerSettings() -> Bool {
        // Make sure max session is longer than nap time
        guard maxDuration > napDuration else { return false }
        // Make sure hold timer isn't longer than (max - nap)
        guard holdDuration <= (maxDuration - napDuration) else { return false }
        return true
    }
    
    // Utility method to format time intervals for display
    func formatTime(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(timeInterval)
        
        // Use hours format if 60 minutes or more
        if totalSeconds >= 3600 {
            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            let seconds = totalSeconds % 60
            
            if seconds == 0 {
                return "\(hours) hr \(minutes) min"
            } else {
                return "\(hours) hr \(minutes) min \(seconds) sec"
            }
        } 
        // Use minutes format if 60 seconds or more
        else if totalSeconds >= 60 {
            let minutes = totalSeconds / 60
            let seconds = totalSeconds % 60
            
            if seconds == 0 {
                return "\(minutes) min"
            } else {
                return "\(minutes) min \(seconds) sec"
            }
        } 
        // Use seconds only format if less than 60 seconds
        else {
            return "\(totalSeconds) sec"
        }
    }
} 