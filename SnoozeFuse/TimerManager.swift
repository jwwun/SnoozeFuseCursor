import Foundation
import Combine
import AVFoundation
import UserNotifications
import MediaPlayer

// Define notification names
extension Notification.Name {
    static let holdTimerFinished = Notification.Name("holdTimerFinished")
    static let napTimerFinished = Notification.Name("napTimerFinished")
    static let maxTimerFinished = Notification.Name("maxTimerFinished")
}

// Custom sound struct for persistence and management
struct CustomSound: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var fileURL: URL
    
    static func == (lhs: CustomSound, rhs: CustomSound) -> Bool {
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

// Available alarm sounds
enum AlarmSound: String, CaseIterable, Identifiable {
    case testAlarm = "Test Alarm"
    case firecracker = "Firecracker"
    case vtuberAlarm = "Korone Alarm"
    case warAmbience = "War Ambience"
    case custom = "Custom Sound"
    
    var id: String { self.rawValue }
    
    var filename: String {
        switch self {
        case .testAlarm: return "testalarm"
        case .firecracker: return "firecracker"
        case .vtuberAlarm: return "vtuberalarm"
        case .warAmbience: return "war ambience"
        case .custom: return "customSound"
        }
    }
    
    var fileExtension: String {
        switch self {
        case .warAmbience, .firecracker: return "wav"
        case .testAlarm, .vtuberAlarm, .custom: return "mp3"
        }
    }
}

// Timer type for code reuse
enum TimerType {
    case hold, nap, max
    
    var notificationName: Notification.Name {
        switch self {
        case .hold: return .holdTimerFinished
        case .nap: return .napTimerFinished
        case .max: return .maxTimerFinished
        }
    }
}

class TimerManager: ObservableObject {
    // Shared instance for use by other managers
    static let shared = TimerManager()
    
    // Timer durations (defaults)
    @Published var holdDuration: TimeInterval = 5    // Timer A: 5 seconds default
    @Published var napDuration: TimeInterval = 60   // Timer B: 1 minutes default
    @Published var maxDuration: TimeInterval = 120   // Timer C: 2 minutes default
    
    // Current timer values
    @Published var holdTimer: TimeInterval = 5
    @Published var napTimer: TimeInterval = 60
    @Published var maxTimer: TimeInterval = 120
    
    // Timer states
    @Published var isHoldTimerRunning = false
    @Published var isNapTimerRunning = false
    @Published var isMaxTimerRunning = false
    
    // Circle size (for visual representation)
    @Published var circleSize: CGFloat = 250
    
    // Visual settings
    @Published var showTimerArcs: Bool = true
    
    // Animation state
    @Published var isLogoAnimating = false
    
    // Alarm sound settings
    @Published var selectedAlarmSound: AlarmSound = .testAlarm
    @Published var customSounds: [CustomSound] = []
    @Published var selectedCustomSoundID: UUID?
    @Published var isExportingMusic: Bool = false
    
    // Timer cancellables
    private var holdCancellable: AnyCancellable?
    private var napCancellable: AnyCancellable?
    private var maxCancellable: AnyCancellable?
    
    // Storage for cancellables
    private var cancellables = Set<AnyCancellable>()
    
    // UserDefaults keys
    private enum UserDefaultsKeys {
        static let holdDuration = "holdDuration"
        static let napDuration = "napDuration"
        static let maxDuration = "maxDuration"
        static let circleSize = "circleSize"
        static let selectedAlarmSound = "selectedAlarmSound"
        static let selectedCustomSoundID = "selectedCustomSoundID"
        static let customSounds = "customSounds"
        static let showTimerArcs = "showTimerArcs"
    }
    
    // Audio player for alarm sounds
    private var audioPlayer: AVAudioPlayer?
    
    init() {
        // Initialize timers with default values
        resetTimers()
        
        // Subscribe to changes in duration settings
        setupDurationObservers()
        
        // Load saved settings
        loadSettings()
        
        // Listen for audio session notifications to help debug issues
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioSessionChanged),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }
    
    deinit {
        // Clean up observers
        NotificationCenter.default.removeObserver(self)
    }
    
    // Monitor audio session state changes
    @objc private func audioSessionChanged(notification: Notification) {
        if notification.name == AVAudioSession.interruptionNotification {
            guard let userInfo = notification.userInfo,
                  let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
            }
            
            let reasonStr = type == .began ? "began" : "ended"
            print("🔊 Audio Session Interruption: \(reasonStr)")
        }
    }
    
    private func setupDurationObservers() {
        // When holdDuration changes, reset holdTimer if not running
        $holdDuration
            .sink { [weak self] newDuration in
                guard let self = self, !self.isHoldTimerRunning else { return }
                self.holdTimer = newDuration
            }
            .store(in: &cancellables)
        
        // When napDuration changes, reset napTimer if not running
        $napDuration
            .sink { [weak self] newDuration in
                guard let self = self, !self.isNapTimerRunning else { return }
                self.napTimer = newDuration
            }
            .store(in: &cancellables)
        
        // When maxDuration changes, reset maxTimer if not running
        $maxDuration
            .sink { [weak self] newDuration in
                guard let self = self, !self.isMaxTimerRunning else { return }
                self.maxTimer = newDuration
            }
            .store(in: &cancellables)
    }
    
    func resetTimers() {
        holdTimer = holdDuration
        napTimer = napDuration
        maxTimer = maxDuration
    }
    
    // Generic timer start function
    private func startTimer(type: TimerType) {
        switch type {
        case .hold:
            isHoldTimerRunning = true
            holdTimer = holdDuration
            
            holdCancellable = createTimerPublisher { [weak self] in
                guard let self = self else { return }
                if self.holdTimer > 0 {
                    self.holdTimer -= 0.1
                } else {
                    self.stopTimer(type: .hold)
                    NotificationCenter.default.post(name: type.notificationName, object: nil)
                }
            }
            
        case .nap:
            isNapTimerRunning = true
            napTimer = napDuration
            
            napCancellable = createTimerPublisher { [weak self] in
                guard let self = self else { return }
                if self.napTimer > 0 {
                    self.napTimer -= 0.1
                } else {
                    self.stopTimer(type: .nap)
                    NotificationCenter.default.post(name: type.notificationName, object: nil)
                }
            }
            
        case .max:
            isMaxTimerRunning = true
            maxTimer = maxDuration
            
            maxCancellable = createTimerPublisher { [weak self] in
                guard let self = self else { return }
                if self.maxTimer > 0 {
                    self.maxTimer -= 0.1
                } else {
                    self.stopTimer(type: .max)
                    NotificationCenter.default.post(name: type.notificationName, object: nil)
                }
            }
        }
    }
    
    private func createTimerPublisher(action: @escaping () -> Void) -> AnyCancellable {
        return Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in action() }
    }
    
    // Generic timer stop function
    private func stopTimer(type: TimerType) {
        switch type {
        case .hold:
            isHoldTimerRunning = false
            holdCancellable?.cancel()
        case .nap:
            isNapTimerRunning = false
            napCancellable?.cancel()
        case .max:
            isMaxTimerRunning = false
            maxCancellable?.cancel()
        }
    }
    
    // Public timer control functions
    func startHoldTimer() {
        startTimer(type: .hold)
    }
    
    func stopHoldTimer() {
        stopTimer(type: .hold)
    }
    
    func startNapTimer() {
        startTimer(type: .nap)
        scheduleAlarmNotification()
    }
    
    func stopNapTimer() {
        stopTimer(type: .nap)
        NotificationManager.shared.cancelPendingNotifications()
    }
    
    func startMaxTimer() {
        startTimer(type: .max)
        scheduleAlarmNotification()
    }
    
    func stopMaxTimer() {
        stopTimer(type: .max)
        NotificationManager.shared.cancelPendingNotifications()
    }
    
    // Validation
    func validateTimerSettings() -> Bool {
        // Make sure max session is longer than nap time
        guard maxDuration > napDuration else { return false }
        // Make sure hold timer isn't longer than (max - nap)
        guard holdDuration <= (maxDuration - napDuration) else { return false }
        return true
    }
    
    // Formatting for display
    func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        let decimal = Int((timeInterval.truncatingRemainder(dividingBy: 1)) * 10)
        
        if minutes > 0 {
            return String(format: "%02d:%02d.%d", minutes, seconds, decimal)
        } else {
            return String(format: "%02d.%d", seconds, decimal)
        }
    }
    
    // MARK: - Background Audio Support
    
    // Setup audio session for background playback
    func setupBackgroundAudio() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            print("Successfully set up background audio session")
        } catch {
            print("Failed to set up background audio session: \(error)")
        }
    }
    
    // Special method to start playing alarm sound in background
    func startBackgroundAlarmSound() {
        setupBackgroundAudio()
        playAlarmSound()
    }
    
    // Handle audio interruptions (calls, etc)
    @objc private func handleAudioInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            // Audio has been interrupted, pause if needed
            audioPlayer?.pause()
            print("Audio interrupted: pausing playback")
        case .ended:
            // Interruption ended, check if should resume
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt,
                  AVAudioSession.InterruptionOptions(rawValue: optionsValue).contains(.shouldResume) else {
                return
            }
            // Resume audio
            print("Audio interruption ended: resuming playback")
            setupBackgroundAudio() // Re-setup audio session
            audioPlayer?.play()
        @unknown default:
            break
        }
    }
    
    // Helper function to get the URL for the currently selected alarm sound
    private func getAlarmSoundURL() -> URL? {
        // Handle custom sound selection
        if selectedAlarmSound == .custom, let customSoundID = selectedCustomSoundID {
            // Ensure custom sounds are loaded before trying to access them
            if customSounds.isEmpty {
                loadCustomSounds(skipMusicCheck: true)
            }
            
            if let customSound = customSounds.first(where: { $0.id == customSoundID }) {
                print("🔊 Attempting to use custom sound URL: \(customSound.fileURL.lastPathComponent)")
                
                // Special case for Apple Music placeholder files
                if customSound.fileURL.lastPathComponent.starts(with: "applemusic_") {
                    print("🎵 This is an Apple Music track that can't be directly played")
                    
                    // Try to read the stored Apple Music ID
                    if let musicIDContent = try? String(contentsOf: customSound.fileURL, encoding: .utf8),
                       let musicIDString = musicIDContent.components(separatedBy: ": ").last,
                       let musicID = UInt64(musicIDString) {
                        
                        print("🎵 Found Apple Music ID: \(musicID), will attempt to play via MPMusicPlayerController")
                        
                        // Set up a music player controller to play this specific item
                        let musicPlayer = MPMusicPlayerController.applicationMusicPlayer
                        let descriptor = MPMusicPlayerStoreQueueDescriptor(storeIDs: ["\(musicID)"])
                        musicPlayer.setQueue(with: descriptor)
                        musicPlayer.play()
                        
                        // Return nil so our normal AVAudioPlayer code doesn't run
                        // (music is played via MPMusicPlayerController instead)
                        return nil
                    }
                    
                    // If we couldn't play via Apple Music, fall through to default sounds
                    print("🚨 ERROR: Could not play Apple Music track, falling back to default sound")
                }
                
                // Check if the custom sound file actually exists before returning URL
                else if FileManager.default.fileExists(atPath: customSound.fileURL.path) {
                    return customSound.fileURL
                } else {
                    print("🚨 ERROR: Custom sound file not found at path: \(customSound.fileURL.path). Falling back.")
                    // Fall through to default/selected built-in sound if file is missing
                }
            } else {
                print("🚨 ERROR: Selected custom sound ID \(customSoundID) not found in customSounds array. Falling back.")
                // Fall through if ID is invalid
            }
        }
        
        // Handle built-in sound selection (or fallback from custom)
        let soundToPlay = (selectedAlarmSound == .custom) ? .testAlarm : selectedAlarmSound // Fallback to testAlarm if custom failed
        
        print("🔊 Attempting to use built-in sound: \(soundToPlay.filename).\(soundToPlay.fileExtension)")
        guard let url = Bundle.main.url(
            forResource: soundToPlay.filename,
            withExtension: soundToPlay.fileExtension
        ) else {
            print("🚨 ERROR: Could not find built-in sound file: \(soundToPlay.filename).\(soundToPlay.fileExtension)")
            return nil
        }
        return url
    }

    // Play the selected alarm sound
    func playAlarmSound() {
        print("🔊 Playing alarm sound request... Current selection: \(selectedAlarmSound.rawValue)")
        
        // Stop any existing audio first
        stopAlarmSound()
        
        // Get the sound URL using the helper
        guard let soundURL = getAlarmSoundURL() else {
            print("🚨 ERROR: Could not get a valid sound URL to play.")
            return // Cannot proceed without a URL
        }
        
        // Setup audio session for playback
        do {
            // Use .playback category for continuous background audio
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            print("🔊 Audio session activated for playback.")
        } catch {
            print("🚨 ERROR: Failed to setup audio session: \(error)")
            // Attempt to continue playback even if session setup fails partially
        }
        
        // Now play the sound from the determined URL
        do {
            print("🔊 Initializing AVAudioPlayer with URL: \(soundURL.lastPathComponent)")
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.numberOfLoops = -1 // Loop continuously (-1 means loop indefinitely)
            audioPlayer?.volume = 1.0
            
            // Add a slight delay before playing to ensure session is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let playResult = self.audioPlayer?.play() ?? false
                print("🔊 Audio player play() called. Result: \(playResult)")
                if !playResult {
                    print("🚨 ERROR: audioPlayer.play() returned false.")
                }
            }
            
            // Register for interruptions *after* successfully initializing the player
            NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleAudioInterruption),
                name: AVAudioSession.interruptionNotification,
                object: AVAudioSession.sharedInstance()
            )
            print("🔊 Registered for audio interruptions.")
            
        } catch {
            print("🚨 ERROR: Could not initialize or play alarm sound from URL \(soundURL.lastPathComponent): \(error.localizedDescription)")
            // Clean up session if player fails to initialize
             stopAlarmSound()
        }
    }
    
    // Stop playing alarm sound - with robust handling
    func stopAlarmSound() {
        print("Stopping all alarm sounds")
        
        // First make sure the player stops
        audioPlayer?.stop()
        
        // Force volume to zero as a fallback in case stopping fails
        audioPlayer?.volume = 0
        
        // Set to nil to release resources
        audioPlayer = nil
        
        // Only stop Apple Music content if we're using a custom Apple Music sound
        // This avoids unnecessarily requesting permissions
        if selectedAlarmSound == .custom && 
           selectedCustomSoundID != nil && 
           !customSounds.isEmpty {
            
            // Check if we have any Apple Music tracks in our custom sounds
            let hasAppleMusicTracks = customSounds.contains { sound in
                sound.fileURL.lastPathComponent.starts(with: "applemusic_")
            }
            
            // Only stop MPMusicPlayerController if we actually might be using it
            if hasAppleMusicTracks {
                MPMusicPlayerController.applicationMusicPlayer.stop()
            }
        }
        
        // Remove the interruption observer
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
        
        // Deactivate audio session to fully release audio resources
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            print("Successfully deactivated audio session")
        } catch {
            print("Warning: Failed to deactivate audio session: \(error)")
            
            // As a backup, try to set the category to ambient which reduces volume
            do {
                try AVAudioSession.sharedInstance().setCategory(.ambient)
                try AVAudioSession.sharedInstance().setActive(true)
                print("Fallback: Set to ambient category instead")
            } catch {
                print("Even ambient category fallback failed: \(error)")
            }
        }
    }
    
    // Test play alarm sound for preview
    func previewAlarmSound() {
        playAlarmSound()
    }
    
    // MARK: - Custom Sound Management
    
    // Add a custom sound from a local file URL
    func addCustomSound(name: String, fileURL: URL) {
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
            
            // Auto-select the new sound
            selectedAlarmSound = .custom
            selectedCustomSoundID = newSound.id
            
            // Save settings
            saveSettings()
            
            print("Successfully added custom sound: \(name)")
        } catch {
            print("Failed to add custom sound: \(error)")
        }
    }
    
    // Add a sound from Apple Music
    func addMusicSound(item: MPMediaItem) {
        guard let title = item.title else {
            print("Invalid media item: missing title")
            isExportingMusic = false
            return
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
            
            exporter?.exportAsynchronously {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    // Set exporting flag to false when complete
                    defer { self.isExportingMusic = false }
                    
                    if let error = exporter?.error {
                        print("Failed to export Apple Music item: \(error)")
                        self.handleExportFailure(item: item, displayName: displayName)
                        return
                    }
                    
                    // Success! Create and add the custom sound
                    let newSound = CustomSound(name: displayName, fileURL: destinationURL)
                    self.customSounds.append(newSound)
                    
                    // Auto-select the new sound
                    self.selectedAlarmSound = .custom
                    self.selectedCustomSoundID = newSound.id
                    
                    // Save settings
                    self.saveSettings()
                    
                    print("Successfully added Apple Music sound: \(displayName)")
                }
            }
        } else {
            // No asset URL available - handle as fallback case
            print("No asset URL available for this music item")
            handleExportFailure(item: item, displayName: displayName)
        }
    }
    
    // Helper to handle failed exports by creating a placeholder
    private func handleExportFailure(item: MPMediaItem, displayName: String) {
        print("Creating placeholder for music: \(displayName)")
        
        // Store the ID as a placeholder
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let placeholderURL = documentsDirectory.appendingPathComponent("applemusic_\(item.playbackStoreID).txt")
        
        // Create placeholder file with the ID
        try? "Apple Music ID: \(item.playbackStoreID)".write(to: placeholderURL, atomically: true, encoding: .utf8)
        
        // Create and add special custom sound
        let newSound = CustomSound(name: "🎵 \(displayName)", fileURL: placeholderURL)
        self.customSounds.append(newSound)
        
        // Select the new sound
        self.selectedAlarmSound = .custom
        self.selectedCustomSoundID = newSound.id
        
        // Save settings
        self.saveSettings()
        
        // Reset exporting state
        self.isExportingMusic = false
    }
    
    // Remove a custom sound by ID
    func removeCustomSound(id: UUID) {
        guard let index = customSounds.firstIndex(where: { $0.id == id }) else { return }
        
        // If it's the selected sound, deselect it
        if selectedCustomSoundID == id {
            selectedCustomSoundID = nil
            selectedAlarmSound = .testAlarm // Fallback to default
        }
        
        // Get the URL to delete the file
        let fileURL = customSounds[index].fileURL
        
        // Remove from array
        customSounds.remove(at: index)
        
        // Delete file
        try? FileManager.default.removeItem(at: fileURL)
        
        // Save settings
        saveSettings()
    }
    
    // MARK: - Settings persistence
    
    // Computed property to check if any timer is active
    var isAnyTimerActive: Bool {
        return isHoldTimerRunning || isNapTimerRunning || isMaxTimerRunning
    }
    
    // Save all settings to UserDefaults
    func saveSettings() {
        let defaults = UserDefaults.standard
        
        // Save timer durations
        defaults.set(holdDuration, forKey: UserDefaultsKeys.holdDuration)
        defaults.set(napDuration, forKey: UserDefaultsKeys.napDuration)
        defaults.set(maxDuration, forKey: UserDefaultsKeys.maxDuration)
        
        // Save circle size
        defaults.set(circleSize, forKey: UserDefaultsKeys.circleSize)
        
        // Save selected alarm type
        defaults.set(selectedAlarmSound.rawValue, forKey: UserDefaultsKeys.selectedAlarmSound)
        
        // Save selected custom sound ID
        if let id = selectedCustomSoundID {
            defaults.set(id.uuidString, forKey: UserDefaultsKeys.selectedCustomSoundID)
        } else {
            defaults.removeObject(forKey: UserDefaultsKeys.selectedCustomSoundID)
        }
        
        // Save custom sounds list
        if let encodedSounds = try? JSONEncoder().encode(customSounds) {
            defaults.set(encodedSounds, forKey: UserDefaultsKeys.customSounds)
        }
        
        // Save showTimerArcs setting
        defaults.set(showTimerArcs, forKey: UserDefaultsKeys.showTimerArcs)
    }
    
    // Load all settings from UserDefaults
    func loadSettings() {
        let defaults = UserDefaults.standard
        
        // Load timer durations
        if let hold = defaults.object(forKey: UserDefaultsKeys.holdDuration) as? TimeInterval {
            holdDuration = hold
            holdTimer = hold
        }
        
        if let nap = defaults.object(forKey: UserDefaultsKeys.napDuration) as? TimeInterval {
            napDuration = nap
            napTimer = nap
        }
        
        if let max = defaults.object(forKey: UserDefaultsKeys.maxDuration) as? TimeInterval {
            maxDuration = max
            maxTimer = max
        }
        
        // Load circle size
        if let size = defaults.object(forKey: UserDefaultsKeys.circleSize) as? CGFloat {
            circleSize = size
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
        
        // Load showTimerArcs setting (default to true if not found)
        if defaults.object(forKey: UserDefaultsKeys.showTimerArcs) != nil {
            self.showTimerArcs = defaults.bool(forKey: UserDefaultsKeys.showTimerArcs)
        } else {
            // Keep the default value of true that was set in the property declaration
            self.showTimerArcs = true
        }
        
        // Defer loading of custom sounds until needed (don't access files at startup)
        // This prevents file access permission prompts until the user actually needs them
    }
    
    // Load custom sounds - only called when needed
    func loadCustomSounds(skipMusicCheck: Bool = false) {
        let defaults = UserDefaults.standard
        
        // Load custom sounds list
        if let savedSounds = defaults.data(forKey: UserDefaultsKeys.customSounds) {
            if let decodedSounds = try? JSONDecoder().decode([CustomSound].self, from: savedSounds) {
                customSounds = decodedSounds
            }
        }
    }
    
    // MARK: - Notification Sound Registration
    
    // No longer needed - iOS only allows using sounds that are in the app bundle with .caf extension
    // This is a placeholder method to maintain compatibility
    func registerBuiltInSoundsForNotifications() {
        print("Note: iOS requires notification sounds to be in the app bundle with .caf extension")
        print("Using default system sounds for notifications")
        
        // This is left as a stub for future enhancement if we decide to include .caf sounds in the app bundle
    }
    
    // New method to schedule alarm notification
    func scheduleAlarmNotification() {
        // Cancel any existing notifications first
        NotificationManager.shared.cancelPendingNotifications()
        
        // Only schedule if napTimer is running
        if isNapTimerRunning {
            // Schedule for napTimer's remaining time
            NotificationManager.shared.scheduleAlarmNotification(after: napTimer)
        } else if isMaxTimerRunning {
            // Or for maxTimer if that's what's running
            NotificationManager.shared.scheduleAlarmNotification(after: maxTimer)
        }
    }
}
