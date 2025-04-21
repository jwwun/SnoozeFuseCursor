import Foundation
import SwiftUI
import Combine

// Define notification name for circle size UI state changes
extension Notification.Name {
    static let circleSizeUIStateChanged = Notification.Name("circleSizeUIStateChanged")
}

// Circle size manager singleton that conforms to ObservableObject for SwiftUI
class CircleSizeManager: ObservableObject {
    static let shared = CircleSizeManager()
    
    // MARK: - Observable Properties
    
    // Circle size (100-500)
    @Published var circleSize: CGFloat = 250  // Default is 250
    
    // Full screen mode toggle
    @Published var isFullScreenMode: Bool = false
    
    // UI state property - controls if circle size UI is shown in main or advanced settings
    @Published var isHiddenFromMainSettings: Bool = false
    
    // MARK: - Initialization
    
    private init() {
        // Load saved settings
        loadSavedSettings()
    }
    
    // MARK: - Public Methods
    
    /// Toggle the hidden state and notify observers
    func toggleHiddenState() {
        isHiddenFromMainSettings.toggle()
        saveSettings()
        
        // Notify any observers about the state change
        NotificationCenter.default.post(name: .circleSizeUIStateChanged, object: nil)
    }
    
    // MARK: - Private Methods
    
    private func loadSavedSettings() {
        let defaults = UserDefaults.standard
        
        // Load circle size setting
        circleSize = CGFloat(defaults.float(forKey: "circleSize"))
        if circleSize < 100 || circleSize > 500 {
            circleSize = 250 // Default size
        }
        
        // Load full screen mode setting
        isFullScreenMode = defaults.bool(forKey: "isFullScreenMode")
        
        // Load UI state
        if defaults.object(forKey: "circleSizeUIHidden") != nil {
            isHiddenFromMainSettings = defaults.bool(forKey: "circleSizeUIHidden")
        } else {
            // Default to showing in main settings (not hidden)
            isHiddenFromMainSettings = false
            defaults.set(false, forKey: "circleSizeUIHidden")
        }
        
        print("⭕ CircleSizeManager initialized: size = \(Int(circleSize)), fullscreen = \(isFullScreenMode), isHidden = \(isHiddenFromMainSettings)")
    }
    
    func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(Float(circleSize), forKey: "circleSize")
        defaults.set(isFullScreenMode, forKey: "isFullScreenMode")
        defaults.set(isHiddenFromMainSettings, forKey: "circleSizeUIHidden")
    }
} 