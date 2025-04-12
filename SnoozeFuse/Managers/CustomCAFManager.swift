import Foundation
import AVFoundation
import UserNotifications

struct CustomCAFSound: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var fileURL: URL
    var isBuiltIn: Bool = false
    
    static func == (lhs: CustomCAFSound, rhs: CustomCAFSound) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Only encode the last path component for storage
    enum CodingKeys: String, CodingKey {
        case id, name, fileURLPath, isBuiltIn
    }
    
    init(id: UUID = UUID(), name: String, fileURL: URL, isBuiltIn: Bool = false) {
        self.id = id
        self.name = name
        self.fileURL = fileURL
        self.isBuiltIn = isBuiltIn
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        isBuiltIn = try container.decodeIfPresent(Bool.self, forKey: .isBuiltIn) ?? false
        
        // Recreate the URL from the stored path
        let path = try container.decode(String.self, forKey: .fileURLPath)
        
        if isBuiltIn {
            // Use bundle URL for built-in sounds
            guard let bundleURL = Bundle.main.url(forResource: path, withExtension: "caf") else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: container.codingPath,
                        debugDescription: "Cannot find built-in sound: \(path).caf"
                    )
                )
            }
            fileURL = bundleURL
        } else {
            // Use documents directory for custom sounds
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            fileURL = documentsDirectory.appendingPathComponent(path)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(isBuiltIn, forKey: .isBuiltIn)
        
        // Store either the filename without extension (for built-in) or the last path component
        if isBuiltIn {
            // Just store the base name without extension for built-in sounds
            let baseName = fileURL.deletingPathExtension().lastPathComponent
            try container.encode(baseName, forKey: .fileURLPath)
        } else {
            // Store the full filename for custom sounds
            try container.encode(fileURL.lastPathComponent, forKey: .fileURLPath)
        }
    }
}

class CustomCAFManager: ObservableObject {
    // Shared instance
    static let shared = CustomCAFManager()
    
    // Properties
    @Published var cafSounds: [CustomCAFSound] = []
    @Published var selectedCAFSoundID: UUID?
    
    // Built-in sound filenames without extensions - these match our actual CAF files
    private let builtInSoundNames = ["beep", "vtuber", "firecracker"]
    
    // Mapping from CAF filenames to display names (matching AlarmSound enum)
    private let displayNameMapping = [
        "beep": "Intense Computer Warning",
        "vtuber": "Ohio_Ohayō's Edit of Korone, Gawr Gura, Watson Amelia",
        "firecracker": "Firecracker"
    ]
    
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
        
        // Add built-in sounds if this is first launch or they're missing
        addBuiltInSoundsIfNeeded()
        
        // Copy built-in sounds to the sounds directory for notifications
        setupBuiltInSoundsForNotifications()
    }
    
    // MARK: - Built-in Sounds
    
    // Add built-in sounds if they aren't already in the list
    private func addBuiltInSoundsIfNeeded() {
        // Check if we need to add built-in sounds
        var needsSave = false
        
        for soundName in builtInSoundNames {
            // Skip if this built-in sound is already in the list
            if cafSounds.contains(where: { $0.isBuiltIn && $0.name == displayNameMapping[soundName] }) {
                continue
            }
            
            // Get the sound URL from bundle
            if let soundURL = Bundle.main.url(forResource: soundName, withExtension: "caf") {
                // Get the friendly display name from our mapping
                let displayName = displayNameMapping[soundName] ?? soundName.capitalized
                
                // Create and add the built-in sound
                let builtInSound = CustomCAFSound(
                    name: displayName,
                    fileURL: soundURL,
                    isBuiltIn: true
                )
                
                cafSounds.append(builtInSound)
                needsSave = true
                
                print("Added built-in CAF sound: \(displayName)")
            }
        }
        
        // Save if we added any sounds
        if needsSave {
            saveCAFSounds()
        }
    }
    
    // Copy built-in sounds to the sounds directory for notifications
    private func setupBuiltInSoundsForNotifications() {
        for soundName in builtInSoundNames {
            if let bundleURL = Bundle.main.url(forResource: soundName, withExtension: "caf") {
                let destinationURL = soundsDirectory.appendingPathComponent("\(soundName).caf")
                
                // Only copy if the file doesn't already exist
                if !FileManager.default.fileExists(atPath: destinationURL.path) {
                    do {
                        try FileManager.default.copyItem(at: bundleURL, to: destinationURL)
                        print("Copied built-in sound to notifications directory: \(soundName).caf")
                    } catch {
                        print("Error copying built-in sound: \(error)")
                    }
                }
            }
        }
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
        
        // Cannot remove built-in sounds
        if cafSounds[index].isBuiltIn {
            print("Cannot remove built-in sound")
            return
        }
        
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
        
        // For built-in sounds, return the URL in the notification sounds directory
        if sound.isBuiltIn {
            let fileName = sound.fileURL.deletingPathExtension().lastPathComponent + ".caf"
            return soundsDirectory.appendingPathComponent(fileName)
        }
        
        // For custom sounds, get file name from the document URL and return the notification directory URL
        let fileName = sound.fileURL.lastPathComponent
        return soundsDirectory.appendingPathComponent(fileName)
    }
    
    // Get the selected CAF sound name for notifications
    func getSelectedCAFSoundName() -> String? {
        guard let selectedID = selectedCAFSoundID,
              let sound = cafSounds.first(where: { $0.id == selectedID }) else {
            return nil
        }
        
        // For built-in sounds, use just the filename
        if sound.isBuiltIn {
            return sound.fileURL.deletingPathExtension().lastPathComponent + ".caf"
        }
        
        // For custom sounds, use the full filename
        return sound.fileURL.lastPathComponent
    }
    
    // Get the first built-in sound name for notifications when no sound is selected
    func getFirstBuiltInSoundName() -> String? {
        // Look for the first built-in sound
        guard let firstBuiltInSound = cafSounds.first(where: { $0.isBuiltIn }) else {
            return nil
        }
        
        // Return the filename with .caf extension
        let baseName = firstBuiltInSound.fileURL.deletingPathExtension().lastPathComponent
        return baseName + ".caf"
    }
    
    func copyCAFSoundToNotificationDirectory(sound: CustomCAFSound) -> String? {
        do {
            // Create sounds directory if it doesn't exist
            let soundsDirectory = try FileManager.default.url(
                for: .libraryDirectory, 
                in: .userDomainMask, 
                appropriateFor: nil, 
                create: true
            ).appendingPathComponent("Sounds", isDirectory: true)
            
            try FileManager.default.createDirectory(at: soundsDirectory, withIntermediateDirectories: true)
            
            // Determine sound file name and destination
            let soundFileName: String
            let sourceURL: URL
            
            if sound.isBuiltIn, let baseFilename = builtInSoundNames.first(where: { displayNameMapping[$0] == sound.name }) {
                // For built-in sounds, use the original filename
                soundFileName = baseFilename + ".caf"
                sourceURL = sound.fileURL
            } else {
                // For custom sounds, create a unique filename
                let uniqueID = UUID().uuidString
                soundFileName = "custom_\(uniqueID).caf"
                sourceURL = sound.fileURL
            }
            
            let destinationURL = soundsDirectory.appendingPathComponent(soundFileName)
            
            // Copy the file
            if !FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                print("Copied CAF sound to: \(destinationURL.path)")
            }
            
            // Return just the filename without extension to be used in the notification
            return soundFileName.components(separatedBy: ".").first
        } catch {
            print("Error copying CAF sound: \(error.localizedDescription)")
            return nil
        }
    }
} 