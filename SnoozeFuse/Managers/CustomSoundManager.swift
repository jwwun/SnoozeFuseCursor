import Foundation
import AVFoundation
import MediaPlayer
import Combine

class CustomSoundManager: ObservableObject {
    // Shared instance
    static let shared = CustomSoundManager()
    
    // Properties
    @Published var customSounds: [CustomSound] = []
    @Published var isExportingMusic: Bool = false
    
    // Initialize manager
    init() {
        loadCustomSounds()
    }
    
    // MARK: - Custom Sound Management
    
    // Add a custom sound from a local file URL
    func addCustomSound(name: String, fileURL: URL) -> CustomSound? {
        // Create a copy of the file in the app's document directory
        do {
            // Create a unique filename based on the original
            let fileName = "\(UUID().uuidString)_\(fileURL.lastPathComponent)"
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let destinationURL = documentsDirectory.appendingPathComponent(fileName)
            
            // Copy the file
            try FileManager.default.copyItem(at: fileURL, to: destinationURL)
            
            // Create and add the custom sound
            let newSound = CustomSound(name: name, fileURL: destinationURL)
            customSounds.append(newSound)
            
            print("Successfully added custom sound: \(name)")
            return newSound
        } catch {
            print("Failed to add custom sound: \(error)")
            return nil
        }
    }
    
    // Add a sound from Apple Music
    func addMusicSound(item: MPMediaItem) -> CustomSound? {
        guard let title = item.title else {
            print("Invalid media item: missing title")
            isExportingMusic = false
            return nil
        }
        
        // Set exporting flag to true at the start
        isExportingMusic = true
        
        // Debug item properties
        print("Processing Apple Music item: \(title)")
        print("- Has asset URL: \(item.assetURL != nil)")
        
        // Prepare display name (Artist - Title)
        var displayName = title
        if let artist = item.artist {
            displayName = "\(artist) - \(title)"
        }
        
        // Create a unique filename using the song title
        let sanitizedTitle = title.replacingOccurrences(of: " ", with: "_")
                                  .replacingOccurrences(of: "/", with: "_")
                                  .replacingOccurrences(of: ":", with: "_")
        let fileName = "\(UUID().uuidString)_\(sanitizedTitle).m4a"
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationURL = documentsDirectory.appendingPathComponent(fileName)
        
        // Try direct export if we have a URL (works for most music including pirated)
        if let assetURL = item.assetURL,
           let avAsset = AVURLAsset(url: assetURL) as AVAsset? {
            
            let exporter = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetAppleM4A)
            exporter?.outputURL = destinationURL
            exporter?.outputFileType = .m4a
            
            // This is now handled via completion handler
            var resultSound: CustomSound? = nil
            
            exporter?.exportAsynchronously {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    // Set exporting flag to false when complete
                    defer { self.isExportingMusic = false }
                    
                    if let error = exporter?.error {
                        print("Failed to export Apple Music item: \(error)")
                        resultSound = self.handleExportFailure(item: item, displayName: displayName)
                        return
                    }
                    
                    // Success! Create and add the custom sound
                    let newSound = CustomSound(name: displayName, fileURL: destinationURL)
                    self.customSounds.append(newSound)
                    resultSound = newSound
                    
                    print("Successfully added Apple Music sound: \(displayName)")
                }
            }
            
            // Return the placeholder for now - real file will be updated asynchronously
            return handleExportFailure(item: item, displayName: displayName)
        } else {
            // No asset URL available - handle as fallback case
            print("No asset URL available for this music item")
            return handleExportFailure(item: item, displayName: displayName)
        }
    }
    
    // Helper to handle failed exports by creating a placeholder
    private func handleExportFailure(item: MPMediaItem, displayName: String) -> CustomSound {
        print("Creating placeholder for music: \(displayName)")
        
        // Store the ID as a placeholder
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let placeholderURL = documentsDirectory.appendingPathComponent("applemusic_\(item.playbackStoreID).txt")
        
        // Create placeholder file with the ID
        try? "Apple Music ID: \(item.playbackStoreID)".write(to: placeholderURL, atomically: true, encoding: .utf8)
        
        // Create and add special custom sound
        let newSound = CustomSound(name: "🎵 \(displayName)", fileURL: placeholderURL)
        self.customSounds.append(newSound)
        
        // Reset exporting state
        self.isExportingMusic = false
        
        return newSound
    }
    
    // Remove a custom sound by ID
    func removeCustomSound(id: UUID) {
        guard let index = customSounds.firstIndex(where: { $0.id == id }) else { return }
        
        // Get the URL to delete the file
        let fileURL = customSounds[index].fileURL
        
        // Remove from array
        customSounds.remove(at: index)
        
        // Delete file
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    // Load custom sounds - only called when needed
    func loadCustomSounds(skipMusicCheck: Bool = false) {
        let defaults = UserDefaults.standard
        
        // Load custom sounds list
        if let savedSounds = defaults.data(forKey: "customSounds") {
            if let decodedSounds = try? JSONDecoder().decode([CustomSound].self, from: savedSounds) {
                customSounds = decodedSounds
            }
        }
    }
    
    // Save custom sounds to UserDefaults
    func saveCustomSounds() {
        let defaults = UserDefaults.standard
        
        // Encode and save custom sounds
        if let encodedSounds = try? JSONEncoder().encode(customSounds) {
            defaults.set(encodedSounds, forKey: "customSounds")
        }
    }
} 