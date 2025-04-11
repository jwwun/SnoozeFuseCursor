import Foundation
import AVFoundation

// Only import MediaPlayer directly in this file, which is only used when the user
// explicitly requests music access by tapping the Import from Apple Music button
import MediaPlayer

// Completely isolated MediaPlayer helper - this is the ONLY class that imports MediaPlayer
class MediaPlayerHelper {
    // Singleton instance
    static let shared = MediaPlayerHelper()
    
    // Private initializer for singleton
    private init() {
        print("🎵 MediaPlayerHelper initialized - MediaPlayer import is isolated to this file")
    }
    
    // Flag to track if the user has requested music access
    private var hasRequestedMusicAccess = false
    
    // MARK: - Music Access Control
    
    // Handle import from Apple Music button tap - the ONLY entry point for Music Library access
    func handleMusicImportRequest(completion: @escaping (Bool, URL?) -> Void) {
        // Mark that user has explicitly requested music access
        hasRequestedMusicAccess = true
        
        // Log explicit user intent for debugging permission issues
        print("🎵 MediaPlayerHelper: User has explicitly requested music access")
        
        // Only check MediaPlayer authorization status when explicitly requested by user
        let currentStatus = MPMediaLibrary.authorizationStatus()
        
        switch currentStatus {
        case .authorized:
            // Already authorized, signal success
            completion(true, nil)
            
        case .denied, .restricted:
            // Already denied, inform caller
            showPermissionAlert()
            completion(false, nil)
            
        case .notDetermined:
            // Need to request permission - this is the key part
            print("🎵 MediaPlayerHelper: First time authorization request - showing system permission dialog")
            MPMediaLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    if status == .authorized {
                        // If permission granted, signal success
                        completion(true, nil)
                    } else {
                        // If permission denied, show alert
                        self.showPermissionAlert()
                        completion(false, nil)
                    }
                }
            }
            
        @unknown default:
            print("Unknown Music Library authorization status encountered.")
            completion(false, nil)
        }
    }
    
    // New method to show the music picker directly from this helper
    func showMusicPicker(onSelect: @escaping (URL?, String) -> Void, onCancel: @escaping () -> Void) {
        // Create the music picker
        let picker = MPMediaPickerController(mediaTypes: .music)
        picker.allowsPickingMultipleItems = false
        picker.showsCloudItems = false
        
        // Set up the picker delegate
        let delegate = MusicPickerDelegate(onSelect: onSelect, onCancel: onCancel)
        picker.delegate = delegate
        
        // Store delegate reference to prevent it from being deallocated
        self.pickerDelegate = delegate
        
        // Present the picker
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(picker, animated: true)
            }
        }
    }
    
    // Reference to keep the delegate alive while the picker is displayed
    private var pickerDelegate: MusicPickerDelegate?
    
    // Show permission alert
    private func showPermissionAlert() {
        // The actual alert will be shown by the caller
        print("Music Library permission required")
    }
    
    // Handle selected media item
    func processMediaItem(mediaItem: Any) -> URL? {
        guard let item = mediaItem as? MPMediaItem,
              let title = item.title else {
            print("Invalid media item")
            return nil
        }
        
        // Create a placeholder file
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let _displayName = item.artist != nil ? "\(item.artist!) - \(title)" : title
        let placeholderURL = documentsDirectory.appendingPathComponent("applemusic_\(item.playbackStoreID).txt")
        
        // Save media ID to the placeholder file
        try? "Apple Music ID: \(item.playbackStoreID)".write(to: placeholderURL, atomically: true, encoding: .utf8)
        
        return placeholderURL
    }
    
    // Add methods to play and stop Apple Music tracks
    func playAppleMusicTrack(withID trackIDString: String) {
        // Check if we can convert the ID string to a UInt64
        guard let trackID = UInt64(trackIDString) else {
            print("🚨 Invalid track ID: \(trackIDString)")
            return
        }
        
        print("🎵 Playing Apple Music track with ID: \(trackID)")
        
        // Set up the music player
        let musicPlayer = MPMusicPlayerController.applicationMusicPlayer
        let descriptor = MPMusicPlayerStoreQueueDescriptor(storeIDs: ["\(trackID)"])
        musicPlayer.setQueue(with: descriptor)
        musicPlayer.play()
    }
    
    // Stop any playing music
    func stopMusic() {
        // Stop the music player if it's playing
        if MPMusicPlayerController.applicationMusicPlayer.playbackState == .playing {
            MPMusicPlayerController.applicationMusicPlayer.stop()
        }
    }
}

// Delegate class for MPMediaPickerController
class MusicPickerDelegate: NSObject, MPMediaPickerControllerDelegate {
    private let onSelect: (URL?, String) -> Void
    private let onCancel: () -> Void
    
    init(onSelect: @escaping (URL?, String) -> Void, onCancel: @escaping () -> Void) {
        self.onSelect = onSelect
        self.onCancel = onCancel
        super.init()
    }
    
    // Called when the user selects media
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        mediaPicker.dismiss(animated: true) {
            // Process the selected item
            if let item = mediaItemCollection.items.first {
                let helper = MediaPlayerHelper.shared
                if let url = helper.processMediaItem(mediaItem: item) {
                    // Generate a display name
                    var name = "Apple Music Track"
                    if let title = item.title {
                        name = title
                        if let artist = item.artist {
                            name = "\(artist) - \(title)"
                        }
                    }
                    
                    // Call the completion handler with the results
                    self.onSelect(url, name)
                } else {
                    self.onCancel()
                }
            } else {
                self.onCancel()
            }
        }
    }
    
    // Called when the user cancels
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        mediaPicker.dismiss(animated: true) {
            self.onCancel()
        }
    }
} 