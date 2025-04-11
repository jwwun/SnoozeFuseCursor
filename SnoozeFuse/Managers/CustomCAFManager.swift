import Foundation
import AVFoundation
import UserNotifications

struct CustomCAFSound: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var fileURL: URL
    
    static func == (lhs: CustomCAFSound, rhs: CustomCAFSound) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Only encode the last path component for storage
    enum CodingKeys: String, CodingKey {
        case id, name, fileURLPath
    }
    
    init(id: UUID = UUID(), name: String, fileURL: URL) {
        self.id = id
        self.name = name
        self.fileURL = fileURL
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        
        // Recreate the URL from the stored path
        let path = try container.decode(String.self, forKey: .fileURLPath)
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = documentsDirectory.appendingPathComponent(path)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        
        // Only store the last path component
        try container.encode(fileURL.lastPathComponent, forKey: .fileURLPath)
    }
}

class CustomCAFManager: ObservableObject {
    // Shared instance
    static let shared = CustomCAFManager()
    
    // Properties
    @Published var cafSounds: [CustomCAFSound] = []
    @Published var selectedCAFSoundID: UUID?
    
    // Directory for storing sounds for notifications
    private var libraryDirectory: URL {
        return FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
    }
    
    private var soundsDirectory: URL {
        let soundsURL = libraryDirectory.appendingPathComponent("Sounds")
        
        // Create the directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: soundsURL.path) {
            try? FileManager.default.createDirectory(at: soundsURL, withIntermediateDirectories: true)
        }
        
        return soundsURL
    }
    
    // Initialize manager
    init() {
        loadCAFSounds()
    }
    
    // MARK: - CAF Sound Management
    
    // Add a CAF sound from a file URL
    func addCAFSound(name: String, fileURL: URL) -> CustomCAFSound? {
        // Check if it's a .caf file
        if fileURL.pathExtension.lowercased() != "caf" {
            print("Failed to add CAF sound: file is not in .caf format")
            return nil
        }
        
        // Create a copy of the file in the special Sounds directory for iOS notifications
        do {
            // Create a unique filename based on the original
            let uniqueID = UUID().uuidString
            let fileName = "\(uniqueID)_\(fileURL.lastPathComponent)"
            
            // Create a URL in the Documents directory (for app usage)
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let documentDestinationURL = documentsDirectory.appendingPathComponent(fileName)
            
            // Create a URL in the Library/Sounds directory (for notifications)
            let notificationDestinationURL = soundsDirectory.appendingPathComponent(fileName)
            
            // Copy the file to Documents directory
            try FileManager.default.copyItem(at: fileURL, to: documentDestinationURL)
            
            // Then copy to Sounds directory for notifications
            try FileManager.default.copyItem(at: fileURL, to: notificationDestinationURL)
            
            // Register the sound with iOS notification system
            let soundName = notificationDestinationURL.lastPathComponent
            UNNotificationSound.init(named: UNNotificationSoundName(rawValue: soundName))
            
            // Create and add the custom sound
            let newSound = CustomCAFSound(name: name, fileURL: documentDestinationURL)
            cafSounds.append(newSound)
            
            // Save the updated list
            saveCAFSounds()
            
            print("Successfully added CAF sound: \(name)")
            return newSound
        } catch {
            print("Failed to add CAF sound: \(error)")
            return nil
        }
    }
    
    // Remove a CAF sound by ID
    func removeCAFSound(id: UUID) {
        guard let index = cafSounds.firstIndex(where: { $0.id == id }) else { return }
        
        // Get the document URL
        let documentFileURL = cafSounds[index].fileURL
        
        // Get the notification sound URL
        let soundFileName = documentFileURL.lastPathComponent
        let notificationSoundURL = soundsDirectory.appendingPathComponent(soundFileName)
        
        // Clear selection if this sound was selected
        if selectedCAFSoundID == id {
            selectedCAFSoundID = nil
        }
        
        // Remove from array
        cafSounds.remove(at: index)
        
        // Delete document file
        try? FileManager.default.removeItem(at: documentFileURL)
        
        // Delete notification sound file
        try? FileManager.default.removeItem(at: notificationSoundURL)
        
        // Save changes
        saveCAFSounds()
    }
    
    // Load CAF sounds from UserDefaults
    func loadCAFSounds() {
        let defaults = UserDefaults.standard
        
        // Load CAF sounds list
        if let savedSounds = defaults.data(forKey: "cafSounds") {
            if let decodedSounds = try? JSONDecoder().decode([CustomCAFSound].self, from: savedSounds) {
                cafSounds = decodedSounds
            }
        }
        
        // Load selected sound ID
        if let selectedIDString = defaults.string(forKey: "selectedCAFSoundID"),
           let selectedID = UUID(uuidString: selectedIDString) {
            selectedCAFSoundID = selectedID
        }
    }
    
    // Save CAF sounds to UserDefaults
    func saveCAFSounds() {
        let defaults = UserDefaults.standard
        
        // Encode and save CAF sounds
        if let encodedSounds = try? JSONEncoder().encode(cafSounds) {
            defaults.set(encodedSounds, forKey: "cafSounds")
        }
        
        // Save selected sound ID
        if let selectedID = selectedCAFSoundID {
            defaults.set(selectedID.uuidString, forKey: "selectedCAFSoundID")
        } else {
            defaults.removeObject(forKey: "selectedCAFSoundID")
        }
    }
    
    // Get the selected CAF sound file URL
    func getSelectedCAFSoundURL() -> URL? {
        guard let selectedID = selectedCAFSoundID,
              let sound = cafSounds.first(where: { $0.id == selectedID }) else {
            return nil
        }
        
        // Get file name from the document URL
        let fileName = sound.fileURL.lastPathComponent
        
        // Return the URL in the notification sounds directory
        return soundsDirectory.appendingPathComponent(fileName)
    }
    
    // Get the selected CAF sound name for notifications
    func getSelectedCAFSoundName() -> String? {
        guard let url = getSelectedCAFSoundURL() else { return nil }
        return url.lastPathComponent
    }
} 