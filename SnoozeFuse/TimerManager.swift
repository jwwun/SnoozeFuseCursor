import Foundation
import Combine
import AVFoundation
import UserNotifications

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
            if let customSound = customSounds.first(where: { $0.id == customSoundID }) {
                print("🔊 Attempting to use custom sound URL: \(customSound.fileURL.lastPathComponent)")
                // Check if the custom sound file actually exists before returning URL
                 if FileManager.default.fileExists(atPath: customSound.fileURL.path) {
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
    
    // Add a custom sound from a file URL
    func addCustomSound(from url: URL) {
        // Get filename for display
        let filename = url.lastPathComponent
        
        // Copy the file to the app's documents directory for persistence
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationURL = documentsDirectory.appendingPathComponent(UUID().uuidString + "." + url.pathExtension)
        
        do {
            try fileManager.copyItem(at: url, to: destinationURL)
            
            // Create a new custom sound and add to the list
            let newSound = CustomSound(name: filename, fileURL: destinationURL)
            customSounds.append(newSound)
            
            // Set it as the selected sound
            selectedAlarmSound = .custom
            selectedCustomSoundID = newSound.id
            
            // Save settings
            saveSettings()
            
            print("Custom sound added successfully: \(filename)")
        } catch {
            print("Error copying custom sound: \(error.localizedDescription)")
        }
    }
    
    // Remove a custom sound
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
        
        // Load custom sounds list
        if let savedSounds = defaults.data(forKey: UserDefaultsKeys.customSounds) {
            if let decodedSounds = try? JSONDecoder().decode([CustomSound].self, from: savedSounds) {
                customSounds = decodedSounds
            }
        }
        
        // Load selected custom sound ID
        if let idString = defaults.string(forKey: UserDefaultsKeys.selectedCustomSoundID),
           let id = UUID(uuidString: idString) {
            selectedCustomSoundID = id
        }
        
        // Load selected alarm type
        if let soundValue = defaults.string(forKey: UserDefaultsKeys.selectedAlarmSound),
           let sound = AlarmSound(rawValue: soundValue) {
            selectedAlarmSound = sound
        }
        
        // Load showTimerArcs setting
        self.showTimerArcs = defaults.bool(forKey: UserDefaultsKeys.showTimerArcs)
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
