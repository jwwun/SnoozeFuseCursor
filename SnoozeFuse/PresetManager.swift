import Foundation
import Combine

// Add notification name extension
extension Notification.Name {
    static let presetUIStateChanged = Notification.Name("presetUIStateChanged")
}

// PresetItem struct to represent a single timer preset
struct PresetItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var holdDuration: TimeInterval
    var napDuration: TimeInterval
    var maxDuration: TimeInterval
    
    static func == (lhs: PresetItem, rhs: PresetItem) -> Bool {
        return lhs.id == rhs.id
    }
}

class PresetManager: ObservableObject {
    // Shared instance
    static let shared = PresetManager()
    
    // Published properties
    @Published var presets: [PresetItem] = []
    @Published var isHiddenFromMainSettings: Bool = true
    
    // UserDefaults keys
    private enum UserDefaultsKeys {
        static let presets = "presets"
        static let isHiddenFromMainSettings = "presets_isHiddenFromMainSettings"
    }
    
    init() {
        loadSettings()
        
        // Create default presets if none exist
        if presets.isEmpty {
            createDefaultPresets()
        }
    }
    
    // Create default nap presets
    private func createDefaultPresets() {
        // Basic nap preset: 30s -> 20m -> 30m
        let basicNapPreset = PresetItem(
            name: "Basic nap",
            holdDuration: 30, // 30 seconds
            napDuration: 20 * 60, // 20 minutes
            maxDuration: 30 * 60 // 30 minutes
        )
        
        // Quick test preset: 5s -> 20s -> 1m
        let quickTestPreset = PresetItem(
            name: "Quick test",
            holdDuration: 2, // 2 seconds
            napDuration: 5, // 5s
            maxDuration: 15 // 15s
        )
        
        // Add presets to the array
        presets.append(basicNapPreset)
        presets.append(quickTestPreset)
        
        // Save the presets
        saveSettings()
    }
    
    // Save settings to UserDefaults
    func saveSettings() {
        let defaults = UserDefaults.standard
        
        // Save presets
        if let encodedPresets = try? JSONEncoder().encode(presets) {
            defaults.set(encodedPresets, forKey: UserDefaultsKeys.presets)
        }
        
        // Save hidden state
        defaults.set(isHiddenFromMainSettings, forKey: UserDefaultsKeys.isHiddenFromMainSettings)
    }
    
    // Load settings from UserDefaults
    func loadSettings() {
        let defaults = UserDefaults.standard
        
        // Load presets
        if let savedPresets = defaults.data(forKey: UserDefaultsKeys.presets),
           let decodedPresets = try? JSONDecoder().decode([PresetItem].self, from: savedPresets) {
            presets = decodedPresets
        }
        
        // Load hidden state
        if defaults.object(forKey: UserDefaultsKeys.isHiddenFromMainSettings) != nil {
            isHiddenFromMainSettings = defaults.bool(forKey: UserDefaultsKeys.isHiddenFromMainSettings)
        }
    }
    
    // Toggle hidden state
    func toggleHiddenState() {
        isHiddenFromMainSettings.toggle()
        saveSettings()
    }
    
    // Create a new preset from current timer settings
    func createNewPreset(from timerManager: TimerManager) {
        // Determine the next preset number
        let nextNumber = presets.count + 1
        
        // Create new preset
        let newPreset = PresetItem(
            name: "Preset \(nextNumber)",
            holdDuration: timerManager.holdDuration,
            napDuration: timerManager.napDuration,
            maxDuration: timerManager.maxDuration
        )
        
        // Add to presets array
        presets.append(newPreset)
        
        // Save changes
        saveSettings()
    }
    
    // Apply preset to timer manager
    func applyPreset(_ preset: PresetItem, to timerManager: TimerManager) {
        timerManager.holdDuration = preset.holdDuration
        timerManager.napDuration = preset.napDuration
        timerManager.maxDuration = preset.maxDuration
        
        // Save the changes to TimerManager settings
        timerManager.saveSettings()
    }
    
    // Rename a preset
    func renamePreset(id: UUID, newName: String) {
        if let index = presets.firstIndex(where: { $0.id == id }) {
            presets[index].name = newName
            saveSettings()
        }
    }
    
    // Delete a preset
    func deletePreset(id: UUID) {
        presets.removeAll { $0.id == id }
        saveSettings()
    }
} 