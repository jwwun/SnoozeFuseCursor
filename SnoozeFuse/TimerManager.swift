import Foundation
import Combine
import AVFoundation
import UserNotifications
import MediaPlayer
import SwiftUI

// Import additional dependencies
import AudioToolbox

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
    case testAlarm = "Korone-Gura-Amelia-Kureiji Alarm"
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
    
    // Full-screen mode toggle
    @Published var isFullScreenMode: Bool = false
    
    // Visual settings
    @Published var showTimerArcs: Bool = true
    @Published var showConnectingLine: Bool = true
    
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
        static let showConnectingLine = "showConnectingLine"
        static let isFullScreenMode = "isFullScreenMode"
    }
    
    // Audio player for alarm sounds
    var audioPlayer: AVAudioPlayer?
    var backupPlayer: AVAudioPlayer?
    
    // snooze stuff
    @Published var snoozeCount = 0
    @Published var isAlarmActive = false
    @Published var isPlayingAlarm = false
    
    init() {
        // Initialize timers with default values
        resetTimers()
        
        // First load settings to ensure proper initial values
        loadSettings()
        
        // Then subscribe to changes in duration settings
        // Add delay to setup observers to prevent immediate feedback loops
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.setupDurationObservers()
        }
        
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
            // Immediately reset to original duration when timer is stopped
            holdTimer = holdDuration
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
        // Only proceed if the timer is actually running 
        if isHoldTimerRunning {
            stopTimer(type: .hold)
            
            // Cancel any related notifications just to be safe
            NotificationManager.shared.cancelPendingNotifications()
        }
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
    
    // MARK: - Background Audio Support
    
    // Setup audio session for background playback
    func setupBackgroundAudio() {
        // First, safely deactivate any existing session
        do {
            if !AVAudioSession.sharedInstance().isOtherAudioPlaying {
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            }
        } catch {
            // Non-critical error, continue
        }
        
        // Check user preference
        let useSpeaker = AudioOutputManager.shared.useSpeaker
        
        do {
            if useSpeaker {
                // Set up for speaker output
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
                
                // If not on speaker yet, try alternative method
                if AVAudioSession.sharedInstance().currentRoute.outputs.first?.portType != .builtInSpeaker {
                    try AVAudioSession.sharedInstance().setCategory(.playAndRecord, 
                                                                  mode: .default,
                                                                  options: [.defaultToSpeaker])
                    try AVAudioSession.sharedInstance().setActive(true)
                    try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
                }
            } else {
                // Set up for external device output
                try AVAudioSession.sharedInstance().setCategory(.playback, 
                                                              mode: .default, 
                                                              options: [.allowBluetooth, .allowAirPlay])
                try AVAudioSession.sharedInstance().setActive(true)
            }
        } catch {
            print("🚨 Audio session setup error: \(error)")
        }
    }
    
    // Special method to start playing alarm sound in background
    func startBackgroundAlarmSound() {
        setupBackgroundAudio()
        playAlarmSound()
    }
    
    // Handle audio interruptions efficiently
    @objc private func handleAudioInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            // Just pause when interrupted
            audioPlayer?.pause()
            
        case .ended:
            // Check if we should resume
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt,
                  AVAudioSession.InterruptionOptions(rawValue: optionsValue).contains(.shouldResume) else {
                return
            }
            
            // Restore audio session based on speaker preference
            do {
                let useSpeaker = AudioOutputManager.shared.useSpeaker
                
                if useSpeaker {
                    // 3-step speaker enforcement for resume
                    try AVAudioSession.sharedInstance().setActive(false)
                    try AVAudioSession.sharedInstance().setCategory(.soloAmbient)
                    try AVAudioSession.sharedInstance().setActive(true)
                    try AVAudioSession.sharedInstance().setActive(false)
                    try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker])
                    try AVAudioSession.sharedInstance().setActive(true)
                    try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
                } else {
                    // Standard approach for external devices
                    try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowBluetooth, .allowAirPlay])
                    try AVAudioSession.sharedInstance().setActive(true)
                }
                
                // Reset volume and resume playback
                if let player = audioPlayer {
                    player.volume = AudioVolumeManager.shared.getAdjustedPlayerVolume()
                    player.play()
                }
            } catch {
                print("🚨 Failed to restore audio after interruption: \(error)")
            }
            
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

    // Play the selected alarm sound with speaker enforcement
    func playAlarmSound() {
        print("🔊 Playing alarm sound: \(selectedAlarmSound.rawValue)")
        
        isPlayingAlarm = true
        stopAlarmSound()
        
        guard let soundURL = getAlarmSoundURL() else {
            print("🚨 ERROR: Could not get a valid sound URL")
            return
        }
        
        let useSpeaker = AudioOutputManager.shared.useSpeaker
        
        // STEP 1: Set the system volume to match our alarm volume setting
        // (This will now affect both speaker and headphones, and show the system volume UI)
        AudioVolumeManager.shared.setSystemVolume(to: AudioVolumeManager.shared.alarmVolume)
        
        // STEP 2: Set up audio session with speaker enforcement if needed
        do {
            // Always break existing connections first
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            
            if useSpeaker {
                // SPEAKER ENFORCEMENT: 3-step reliable approach
                
                // Step 1: Break Bluetooth with soloAmbient
                try AVAudioSession.sharedInstance().setCategory(.soloAmbient)
                try AVAudioSession.sharedInstance().setActive(true)
                try AVAudioSession.sharedInstance().setActive(false)
                
                // Step 2: Set playAndRecord with defaultToSpeaker (no Bluetooth options)
                try AVAudioSession.sharedInstance().setCategory(.playAndRecord, 
                                                           mode: .spokenAudio,
                                                           options: [.defaultToSpeaker])
                try AVAudioSession.sharedInstance().setActive(true)
                
                // Step 3: Force speaker override
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
                
                // Quick verification
                let isOnSpeaker = AVAudioSession.sharedInstance().currentRoute.outputs.first?.portType == .builtInSpeaker
                print("🔊 Speaker routing status: \(isOnSpeaker ? "Success" : "Failed")")
            } else {
                // Standard approach for headphones/Bluetooth
                try AVAudioSession.sharedInstance().setCategory(.playback, 
                                                             mode: .default, 
                                                             options: [.allowBluetooth, .allowAirPlay])
                try AVAudioSession.sharedInstance().setActive(true)
            }
        } catch {
            print("🚨 Audio session error: \(error)")
        }
        
        // STEP 3: Initialize player and start playback
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            
            // Apply player volume settings and ensure system volume is set
            let playerVolume = AudioVolumeManager.shared.getAdjustedPlayerVolume()
            audioPlayer?.volume = playerVolume
            
            // Log both player and system volume for clarity
            let currentSystemVolume = AVAudioSession.sharedInstance().outputVolume
            print("🔊 Player volume: \(Int(playerVolume * 100))%, System volume: \(Int(currentSystemVolume * 100))%, Target volume: \(Int(AudioVolumeManager.shared.alarmVolume * 100))%")
            
            // Register for interruptions and route changes
            setupAudioNotifications()
            
            // Add slight delay to ensure session is fully configured
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                guard let self = self else { return }
                
                // One final speaker check
                if useSpeaker && AVAudioSession.sharedInstance().currentRoute.outputs.first?.portType != .builtInSpeaker {
                    try? AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
                }
                
                // Double-check system volume one more time
                let finalSystemVolume = AVAudioSession.sharedInstance().outputVolume
                if abs(finalSystemVolume - AudioVolumeManager.shared.alarmVolume) > 0.05 {
                    // If system volume doesn't match our setting, try one more time with force UI
                    AudioVolumeManager.shared.setSystemVolume(to: AudioVolumeManager.shared.alarmVolume)
                }
                
                // Start playback
                self.audioPlayer?.play()
                
                // Trigger vibration
                NotificationManager.shared.triggerImmediateAlarmWithVibration()
            }
        } catch {
            print("🚨 Audio player error: \(error)")
            stopAlarmSound()
        }
    }
    
    // Setup listeners for audio interruptions and route changes
    private func setupAudioNotifications() {
        // Remove any existing observers first
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: nil)
        
        // Register for key audio events
        NotificationCenter.default.addObserver(self, selector: #selector(handleAudioInterruption), 
                                              name: AVAudioSession.interruptionNotification, 
                                              object: AVAudioSession.sharedInstance())
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange), 
                                              name: AVAudioSession.routeChangeNotification, 
                                              object: AVAudioSession.sharedInstance())
    }
    
    // Handle audio route changes efficiently
    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        // Only enforce speaker if alarm is playing AND user wants speaker
        guard isPlayingAlarm && AudioOutputManager.shared.useSpeaker else { return }
        
        // Check if we need to reclaim speaker
        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        let isOnSpeaker = currentRoute.outputs.first?.portType == .builtInSpeaker
        
        // Only act if we're not already on speaker
        if !isOnSpeaker {
            print("🔊 Route change detected - enforcing speaker output")
            
            do {
                // Quick 3-step approach to reclaim speaker
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
                try AVAudioSession.sharedInstance().setCategory(.soloAmbient)
                try AVAudioSession.sharedInstance().setActive(true)
                try AVAudioSession.sharedInstance().setActive(false)
                try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker])
                try AVAudioSession.sharedInstance().setActive(true)
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
            } catch {
                print("🚨 Failed to enforce speaker: \(error)")
            }
        }
    }
    
    // Stop playing alarm sound
    func stopAlarmSound() {
        isPlayingAlarm = false
        
        // Stop playback and clean up player
        audioPlayer?.stop()
        audioPlayer = nil
        
        // Remove audio session observers
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: nil)
        
        // Reset audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            try AVAudioSession.sharedInstance().setCategory(.ambient)
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            // Non-critical error
        }
        
        // Stop any music player if active
        if MPMusicPlayerController.applicationMusicPlayer.playbackState == .playing {
            MPMusicPlayerController.applicationMusicPlayer.stop()
        }
        
        // Stop vibrations
        NotificationManager.shared.stopVibrationAlarm()
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
        defaults.set(holdDuration, forKey: UserDefaultsKeys.holdDuration)
        defaults.set(napDuration, forKey: UserDefaultsKeys.napDuration)
        defaults.set(maxDuration, forKey: UserDefaultsKeys.maxDuration)
        defaults.set(circleSize, forKey: UserDefaultsKeys.circleSize)
        defaults.set(selectedAlarmSound.rawValue, forKey: UserDefaultsKeys.selectedAlarmSound)
        defaults.set(selectedCustomSoundID?.uuidString, forKey: UserDefaultsKeys.selectedCustomSoundID)
        defaults.set(showTimerArcs, forKey: UserDefaultsKeys.showTimerArcs)
        defaults.set(showConnectingLine, forKey: UserDefaultsKeys.showConnectingLine)
        defaults.set(isFullScreenMode, forKey: UserDefaultsKeys.isFullScreenMode)
        
        // Encode and save custom sounds
        if let encodedSounds = try? JSONEncoder().encode(customSounds) {
            defaults.set(encodedSounds, forKey: UserDefaultsKeys.customSounds)
        }
    }
    
    // Load all settings from UserDefaults
    func loadSettings() {
        let defaults = UserDefaults.standard
        
        if defaults.object(forKey: UserDefaultsKeys.holdDuration) != nil {
            holdDuration = defaults.double(forKey: UserDefaultsKeys.holdDuration)
            holdTimer = holdDuration
        }
        
        if defaults.object(forKey: UserDefaultsKeys.napDuration) != nil {
            napDuration = defaults.double(forKey: UserDefaultsKeys.napDuration)
            napTimer = napDuration
        }
        
        if defaults.object(forKey: UserDefaultsKeys.maxDuration) != nil {
            maxDuration = defaults.double(forKey: UserDefaultsKeys.maxDuration)
            maxTimer = maxDuration
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
    
    // Schedule notification for when alarm will go off
    func scheduleAlarmNotification() {
        let timeInterval = isNapTimerRunning ? napTimer : maxTimer
        NotificationManager.shared.scheduleAlarmNotification(after: timeInterval)
    }
    
    // Trigger an immediate notification to use the system's alarm vibration pattern
    func triggerImmediateAlarmNotification() {
        // Use our enhanced method in NotificationManager
        NotificationManager.shared.triggerImmediateAlarmWithVibration()
    }
}
