import Foundation
import AVFoundation
import MediaPlayer
import AudioToolbox
import Combine

class AudioPlayerManager: ObservableObject {
    // Shared instance
    static let shared = AudioPlayerManager()
    
    // Audio players
    private var audioPlayer: AVAudioPlayer?
    private var backupPlayer: AVAudioPlayer?
    
    // State tracking
    @Published private(set) var isPlayingAlarm = false
    
    // MARK: - Audio Session Management
    
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
    
    // MARK: - Audio Playback
    
    // Helper function to get the URL for a selected alarm sound
    func getAlarmSoundURL(selectedAlarmSound: AlarmSound, selectedCustomSoundID: UUID?, customSounds: [CustomSound]) -> URL? {
        // Handle custom sound selection
        if selectedAlarmSound == .custom, let customSoundID = selectedCustomSoundID {
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
    func playAlarmSound(selectedAlarmSound: AlarmSound, selectedCustomSoundID: UUID?, customSounds: [CustomSound]) {
        print("🔊 Playing alarm sound: \(selectedAlarmSound.rawValue)")
        
        isPlayingAlarm = true
        stopAlarmSound()
        
        guard let soundURL = getAlarmSoundURL(selectedAlarmSound: selectedAlarmSound, 
                                             selectedCustomSoundID: selectedCustomSoundID, 
                                             customSounds: customSounds) else {
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
    
    // Special method to start playing alarm sound in background
    func startBackgroundAlarmSound(selectedAlarmSound: AlarmSound, selectedCustomSoundID: UUID?, customSounds: [CustomSound]) {
        setupBackgroundAudio()
        playAlarmSound(selectedAlarmSound: selectedAlarmSound, 
                      selectedCustomSoundID: selectedCustomSoundID, 
                      customSounds: customSounds)
    }
} 