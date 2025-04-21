import Foundation
import AVFoundation
import MediaPlayer
import Combine
import AudioToolbox

// Define notification name for volume UI state changes
extension Notification.Name {
    static let audioVolumeUIStateChanged = Notification.Name("audioVolumeUIStateChanged")
}

// Audio volume manager singleton that conforms to ObservableObject for SwiftUI
class AudioVolumeManager: ObservableObject {
    static let shared = AudioVolumeManager()
    
    // MARK: - Observable Properties
    
    // Alarm volume (0.0-1.0) - this will control system volume when alarm plays
    @Published var alarmVolume: Float = 0.7  // Default is 70%
    
    // Force system volume toggle
    @Published var forceSystemVolume: Bool = true  // Default is true
    
    // UI state property - controls if volume UI is shown in main or advanced settings
    @Published var isHiddenFromMainSettings: Bool = false
    
    // MARK: - Private Properties
    
    // Volume view for direct control - HIDDEN off-screen
    private let volumeView = MPVolumeView(frame: CGRect(x: -2000, y: -2000, width: 1, height: 1))
    
    // MARK: - Initialization
    
    private init() {
        // Load saved settings
        loadSavedSettings()
    }
    
    // MARK: - Volume Control Methods
    
    /// Gets the volume slider from the volume view for direct manipulation
    func getVolumeSlider() -> UISlider? {
        return volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
    }
    
    /// Sets the device system volume to the specified value AND shows the system volume UI
    func setSystemVolume(to volume: Float) {
        // Method 1: Use the MPVolumeView's slider (this is reliable)
        if let volumeSlider = getVolumeSlider() {
            DispatchQueue.main.async {
                // Update slider value to change volume
                volumeSlider.value = volume
                
                // This will affect both speaker and headphones since it's the system volume
                print("🔊 System volume set to \(Int(volume * 100))%")
                
                // Only play a sound if needed to trigger volume UI
                if volume > 0 {
                    // Use a safer approach with a delayed tiny sound
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        AudioServicesPlaySystemSound(1519) // Small sound
                    }
                }
            }
        }
        
        // Method 2 removed - avoid using private API approach that can cause errors
    }
    
    /// Gets the current system volume
    func getCurrentSystemVolume() -> Float {
        return AVAudioSession.sharedInstance().outputVolume
    }
    
    /// Returns a player-specific volume adjusted for better playback
    /// This is used for the AVAudioPlayer volume property
    func getAdjustedPlayerVolume() -> Float {
        // Use a non-linear scale for player volume to better match perceived loudness
        let scaledVolume = pow(alarmVolume, 0.5) // Square root scaling for more linear perception
        return scaledVolume
    }
    
    /// Apply volume settings to an audio player and system volume
    /// This will affect both internal speaker and external devices
    func applyVolumeSettings(to audioPlayer: AVAudioPlayer?) {
        // Set audio player volume first
        audioPlayer?.volume = getAdjustedPlayerVolume()
        
        // Only update system volume if forceSystemVolume is enabled
        if forceSystemVolume {
            // Safer approach - only update system volume if we need to
            let currentVolume = getCurrentSystemVolume()
            if abs(currentVolume - alarmVolume) > 0.05 {  // Only update if difference is significant
                // Also set system volume to match our desired volume 
                // (This affects both speaker and external devices like headphones)
                setSystemVolume(to: alarmVolume)
            }
        }
    }
    
    // MARK: - UI Control Methods
    
    /// Toggle whether the volume UI is shown in main settings or advanced settings
    func toggleHiddenState() {
        isHiddenFromMainSettings.toggle()
        saveSettings()
        
        // Notify UI to update
        NotificationCenter.default.post(name: .audioVolumeUIStateChanged, object: nil)
    }
    
    // MARK: - Media Player Setup
    
    /// Prepares the media volume view for controlling system volume
    func prepareVolumeControl() {
        // Add our hidden volume view to the main window (but keep it off-screen)
        DispatchQueue.main.async {
            // Use the modern approach to get the window
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let keyWindow = windowScene.windows.first {
                self.volumeView.isHidden = true // Make sure it's hidden
                keyWindow.addSubview(self.volumeView)
            }
        }
    }
    
    // MARK: - Settings Management
    
    private func loadSavedSettings() {
        let defaults = UserDefaults.standard
        
        // Load volume setting
        alarmVolume = defaults.float(forKey: "alarmVolume")
        if alarmVolume <= 0.0 || alarmVolume > 1.0 {
            alarmVolume = 0.7 // 70% is a good default
        }
        
        // Load force system volume setting
        if defaults.object(forKey: "forceSystemVolume") != nil {
            forceSystemVolume = defaults.bool(forKey: "forceSystemVolume")
        } else {
            // Default to true (enabled by default)
            forceSystemVolume = true
            defaults.set(true, forKey: "forceSystemVolume")
        }
        
        // Load UI state
        if defaults.object(forKey: "volumeUIHidden") != nil {
            isHiddenFromMainSettings = defaults.bool(forKey: "volumeUIHidden")
        } else {
            // Default to showing in main settings (not hidden)
            isHiddenFromMainSettings = false
            defaults.set(false, forKey: "volumeUIHidden")
        }
        
        // Prepare volume control
        prepareVolumeControl()
        
        print("🔊 AudioVolumeManager initialized: volume = \(Int(alarmVolume * 100))%, isHidden = \(isHiddenFromMainSettings)")
    }
    
    func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(alarmVolume, forKey: "alarmVolume")
        defaults.set(forceSystemVolume, forKey: "forceSystemVolume")
        defaults.set(isHiddenFromMainSettings, forKey: "volumeUIHidden")
    }
} 