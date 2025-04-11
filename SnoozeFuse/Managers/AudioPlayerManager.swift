import Foundation
import AVFoundation
import MediaPlayer
import AudioToolbox
import Combine
import UIKit
import UserNotifications

class AudioPlayerManager: ObservableObject {
    // Shared instance
    static let shared = AudioPlayerManager()
    
    // Audio players
    private var audioPlayer: AVAudioPlayer?
    private var backupPlayer: AVAudioPlayer?
    
    // State tracking
    @Published private(set) var isPlayingAlarm = false
    private var alarmSource: AlarmSource = .none
    private var vibrationTimer: Timer?
    
    // Enum to track alarm source
    enum AlarmSource {
        case none
        case regularAlarm
        case maxTimer
        case backgroundAlarm
    }
    
    // Player state enum to track interruptions
    private enum PlayerState {
        case playing
        case paused
        case wasPlaying
    }
    
    // Current player state
    private var playerState: PlayerState = .paused
    
    // Initialize with app lifecycle observers
    init() {
        setupAppLifecycleObservers()
    }
    
    // Setup observers for app lifecycle
    private func setupAppLifecycleObservers() {
        NotificationCenter.default.addObserver(self, 
                                               selector: #selector(handleAppTermination), 
                                               name: UIApplication.willTerminateNotification, 
                                               object: nil)
        
        NotificationCenter.default.addObserver(self, 
                                               selector: #selector(handleAppBackground), 
                                               name: UIApplication.didEnterBackgroundNotification, 
                                               object: nil)
        
        // Add more observers for different app states
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(forceStopAllSounds),
                                               name: UIApplication.willResignActiveNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(forceStopAllSounds),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
    }
    
    // Force stop all sounds and vibrations when app state changes
    @objc private func forceStopAllSounds() {
        print("🚨 App state changing - emergency stopping all sounds and vibrations")
        nukeSoundAndVibration()
    }
    
    // Handle app termination
    @objc private func handleAppTermination() {
        print("🚨 App terminating - stopping all alarms and vibrations")
        nukeSoundAndVibration()
    }
    
    // Handle app going to background
    @objc private func handleAppBackground() {
        // Only if we're exiting the app but not playing a background alarm
        if isPlayingAlarm && UIApplication.shared.applicationState == .background {
            print("📱 App entering background with active alarm")
            // Make sure vibration continues properly in background
            NotificationManager.shared.stopVibrationAlarm()
            NotificationManager.shared.triggerImmediateAlarmWithVibration()
        } else {
            // If not playing intentional alarm, kill everything
            nukeSoundAndVibration()
        }
    }
    
    // Nuclear option - kill ALL sounds and vibrations at system level
    func nukeSoundAndVibration(preserveSession: Bool = false) {
        print("💣 NUCLEAR OPTION: Killing AudioPlayerManager state. Preserve session: \(preserveSession)")
        
        // 1. Clear audio flags
        isPlayingAlarm = false
        alarmSource = .none
        print("💣 Nuclear cleanup - clearing audio flags")
        
        // 2. Stop audio player
        audioPlayer?.stop()
        audioPlayer = nil
        
        // 3. Kill any active vibration timer (ONLY internal to this manager)
        vibrationTimer?.invalidate()
        vibrationTimer = nil
        
        // 4. Stop audio session ONLY IF NOT preserving
        if !preserveSession {
            print("💣 Nuking Audio Session")
            do {
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            } catch {
                print("💣 Error deactivating session: \(error)")
            }
        } else {
            print("💣 Preserving Audio Session state")
        }
        
        // REMOVED: Calls to NotificationManager and HapticManager cleanup
        // REMOVED: System sound cleanup calls
        
        // Also run cleanup on the main thread
        DispatchQueue.main.async {
            // Stop any music player if active
            if MPMusicPlayerController.applicationMusicPlayer.playbackState == .playing {
                MPMusicPlayerController.applicationMusicPlayer.stop()
            }
            
            // Final reset of audio session on main thread ONLY IF NOT preserving
            if !preserveSession {
                print("💣 Final Session Reset")
                do {
                    try AVAudioSession.sharedInstance().setActive(false)
                    try AVAudioSession.sharedInstance().setCategory(.ambient)
                    try AVAudioSession.sharedInstance().setActive(false)
                } catch {
                    print("💣 Error resetting session: \(error)")
                }
            }
        }
    }
    
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
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), 
                                              name: AVAudioSession.interruptionNotification, 
                                              object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange), 
                                              name: AVAudioSession.routeChangeNotification, 
                                              object: nil)
    }
    
    // Handle audio session interruptions (e.g., phone calls)
    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeInt = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeInt) else {
            return
        }
        
        if type == .began {
            // Interruption began, pause audio
            playerState = audioPlayer?.isPlaying == true ? .wasPlaying : .paused
            audioPlayer?.pause()
            print("🔊 Audio interrupted, pausing playback")
        } else if type == .ended {
            // Interruption ended, resume audio if it was playing before
            guard let optionsInt = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsInt)
            
            // Check if we should resume
            if options.contains(.shouldResume) && playerState == .wasPlaying {
                // Try to resume our session
                do {
                    try AVAudioSession.sharedInstance().setActive(true)
                    audioPlayer?.play()
                    print("🔊 Interruption ended, resuming playback")
                } catch {
                    print("🚨 Failed to resume audio session after interruption: \(error)")
                }
            }
        }
    }
    
    // Handle audio route changes (e.g., headphones connected/disconnected)
    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonInt = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let _ = AVAudioSession.RouteChangeReason(rawValue: reasonInt) else {
            return
        }
        
        // Get current route
        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        let outputs = currentRoute.outputs
        
        // Only enforce speaker if alarm is playing AND user wants speaker
        guard isPlayingAlarm && AudioOutputManager.shared.useSpeaker else { return }
        
        // Check if we need to reclaim speaker
        let isOnSpeaker = outputs.first?.portType == .builtInSpeaker
        
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
    func playAlarmSound(selectedAlarmSound: AlarmSound, selectedCustomSoundID: UUID?, customSounds: [CustomSound], source: AlarmSource = .regularAlarm) {
        print("🔊 Playing alarm sound: \(selectedAlarmSound.rawValue) from source: \(source)")
        
        // Only stop existing alarm if necessary - don't cancel ourselves
        if isPlayingAlarm && source != alarmSource {
            print("🔊 Already playing alarm, stopping before starting new one")
            
            // Don't use nuclear option here - just stop the player cleanly
            audioPlayer?.stop()
            audioPlayer = nil
            
            // Stop vibrations but don't affect audio session
            NotificationManager.shared.stopVibrationAlarm()
            HapticManager.shared.stopAlarmVibration() 
        }
        
        isPlayingAlarm = true
        alarmSource = source
        
        guard let soundURL = getAlarmSoundURL(selectedAlarmSound: selectedAlarmSound, 
                                             selectedCustomSoundID: selectedCustomSoundID, 
                                             customSounds: customSounds) else {
            print("🚨 ERROR: Could not get a valid sound URL")
            return
        }
        
        let useSpeaker = AudioOutputManager.shared.useSpeaker
        
        // STEP 1: Set the system volume to match our alarm volume setting
        // (This will now affect both speaker and headphones, and show the system volume UI)
        // Only update system volume if significantly different from current
        let currentVolume = AVAudioSession.sharedInstance().outputVolume
        if abs(currentVolume - AudioVolumeManager.shared.alarmVolume) > 0.1 {
            AudioVolumeManager.shared.setSystemVolume(to: AudioVolumeManager.shared.alarmVolume)
        }
        
        // STEP 2: Set up audio session with speaker enforcement if needed
        do {
            // Only deactivate if session isn't already active
            let isSessionActive = AVAudioSession.sharedInstance().isOtherAudioPlaying
            if !isSessionActive {
                // Always break existing connections first
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            }
            
            if useSpeaker {
                // SPEAKER ENFORCEMENT: 3-step reliable approach
                
                // Step 1: Break Bluetooth with soloAmbient
                try AVAudioSession.sharedInstance().setCategory(.soloAmbient)
                try AVAudioSession.sharedInstance().setActive(true)
                
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
            // Create a fresh player
            let freshPlayer = try AVAudioPlayer(contentsOf: soundURL)
            
            // Configure it before assigning to ensure we don't lose settings
            freshPlayer.prepareToPlay()
            freshPlayer.numberOfLoops = -1 // Loop indefinitely
            
            // Set volume BEFORE assigning to property
            let playerVolume = AudioVolumeManager.shared.getAdjustedPlayerVolume()
            freshPlayer.volume = playerVolume
            
            // Now safely assign to property
            audioPlayer = freshPlayer
            
            // Log both player and system volume for clarity
            let currentSystemVolume = AVAudioSession.sharedInstance().outputVolume
            print("🔊 Player volume: \(Int(playerVolume * 100))%, System volume: \(Int(currentSystemVolume * 100))%, Target volume: \(Int(AudioVolumeManager.shared.alarmVolume * 100))%")
            
            // Register for interruptions and route changes
            setupAudioNotifications()
            
            // CRITICAL CHANGE: Start playing immediately again
            print("🔊 Attempting immediate audio playback...")
            if audioPlayer!.play() {
                print("✅ Immediate playback started successfully.")
            } else {
                print("🚨 Immediate playback FAILED to start. Trying prepare/play again...")
                audioPlayer?.prepareToPlay()
                if audioPlayer!.play() {
                     print("✅ Immediate playback started successfully on second attempt.")
                } else {
                    print("🚨🚨 Immediate playback FAILED even on second attempt!")
                    stopAlarmSound() // Give up and clean up
                    return // Don't proceed
                }
            }
            
            // Trigger Vibration immediately as well
            print("📳 Triggering vibration for source: \(source)")
            NotificationManager.shared.triggerImmediateAlarmWithVibration()

        } catch {
            print("🚨 Audio player initialization error: \(error)")
            stopAlarmSound()
        }
    }
    
    // Special method for max timer alarm
    func playMaxTimerAlarm(selectedAlarmSound: AlarmSound, selectedCustomSoundID: UUID?, customSounds: [CustomSound]) {
        print("⏰ Max timer triggered alarm")

        // Gentle stop of previous sound/vibration IF playing
        if isPlayingAlarm {
            print("⏰ Gently stopping previous alarm/vibration for max timer")
            // Stop audio player directly
            audioPlayer?.stop()
            // Don't nil out audioPlayer here, let playAlarmSound handle replacement

            // Stop vibration sources directly
            NotificationManager.shared.stopVibrationAlarm()
            HapticManager.shared.stopAlarmVibration() // Ensure HapticManager timer stops too

            // Don't clear isPlayingAlarm flag here, let playAlarmSound manage it
        } else {
             print("⏰ No previous alarm playing, starting max timer fresh")
             // If nothing was playing, ensure flags are clear (no-op if already clear)
             isPlayingAlarm = false
             alarmSource = .none
        }


        // Small delay to ensure stops complete before starting new audio
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self else { return }

            // isPlayingAlarm should be true OR false depending on above block
            // Let playAlarmSound handle setting it true consistently
            print("📳 Starting fresh max timer alarm. Current isPlayingAlarm=\(self.isPlayingAlarm)")
            self.playAlarmSound(selectedAlarmSound: selectedAlarmSound,
                           selectedCustomSoundID: selectedCustomSoundID,
                           customSounds: customSounds,
                           source: .maxTimer)
        }
    }
    
    // Stop playing alarm sound
    func stopAlarmSound(force: Bool = false) {
        // If already stopped, don't do anything to prevent duplicate stops
        if !force && !isPlayingAlarm {
            print("🔊 No alarm playing - nothing to stop")
            return
        }
        
        print("🔊 Stopping alarm sound from source: \(alarmSource)")
        
        // Nuclear option to ensure everything stops - DO NOT preserve session here
        nukeSoundAndVibration(preserveSession: false)
    }
    
    // Special method to start playing alarm sound in background
    func startBackgroundAlarmSound(selectedAlarmSound: AlarmSound, selectedCustomSoundID: UUID?, customSounds: [CustomSound]) {
        setupBackgroundAudio()
        playAlarmSound(selectedAlarmSound: selectedAlarmSound, 
                       selectedCustomSoundID: selectedCustomSoundID, 
                       customSounds: customSounds,
                       source: .backgroundAlarm)
    }
    
    // Call when app is being closed or exited
    func cleanupOnExit() {
        print("🧹 Cleaning up audio on exit")
        nukeSoundAndVibration(preserveSession: false)
    }
    
    // MARK: - Global app termination handling
    
    // This can be called from AppDelegate to ensure vibration cleanup
    class func emergencyStopAllVibrations() {
        print("🚨 EMERGENCY: Stopping all vibrations on application termination")
        
        // Use all available methods to absolutely ensure vibrations stop
        NotificationManager.shared.stopVibrationAlarm()
        HapticManager.shared.killAllSystemSounds()
        
        // Direct system calls as last resort
        AudioServicesDisposeSystemSoundID(kSystemSoundID_Vibrate)
        AudioServicesRemoveSystemSoundCompletion(kSystemSoundID_Vibrate)
        
        for soundID in 1000...1016 {
            AudioServicesDisposeSystemSoundID(SystemSoundID(soundID))
            AudioServicesRemoveSystemSoundCompletion(SystemSoundID(soundID))
        }
    }
} 