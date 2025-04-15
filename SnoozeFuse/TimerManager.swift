import Foundation
import Combine
import AVFoundation
import UserNotifications
import MediaPlayer
import SwiftUI
import AudioToolbox

// The main TimerManager class that coordinates all timer-related functionality
class TimerManager: ObservableObject {
    // Shared instance for use throughout the app
    static let shared = TimerManager()
    
    // MARK: - Properties
    
    // Timer-related properties (forwarded from TimerController)
    @Published var holdTimer: TimeInterval = 5
    @Published var napTimer: TimeInterval = 60
    @Published var maxTimer: TimeInterval = 120
    
    @Published var isHoldTimerRunning = false
    @Published var isNapTimerRunning = false
    @Published var isMaxTimerRunning = false
    
    @Published var isLogoAnimating = false
    @Published var snoozeCount = 0
    @Published var isAlarmActive = false
    @Published var isPlayingAlarm = false
    
    // Settings-related properties (forwarded from SettingsManager)
    @Published var holdDuration: TimeInterval = 5
    @Published var napDuration: TimeInterval = 60
    @Published var maxDuration: TimeInterval = 120
    
    // Forward from CircleSizeManager
    @Published var circleSize: CGFloat = 250
    @Published var isFullScreenMode: Bool = false
    
    // Forward from other UI managers
    @Published var showTimerArcs: Bool = true
    @Published var showConnectingLine: Bool = true
    
    // Animation settings
    @Published var showRippleEffects: Bool = true
    @Published var showMiniAnimations: Bool = true
    @Published var showTouchFeedback: Bool = true
    
    // Sound-related properties (forwarded from managers)
    @Published var selectedAlarmSound: AlarmSound = .firecracker
    @Published var customSounds: [CustomSound] = []
    @Published var selectedCustomSoundID: UUID?
    @Published var isExportingMusic: Bool = false
    
    // Private cancellables for forwarding @Published properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        // First, we need to set initial values
        setupInitialValues()
        
        // Delay binding setup to avoid circular dependencies
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Now set up all the bindings
            self.setupBindings()
        }
    }
    
    // Just set initial values, no bindings yet
    private func setupInitialValues() {
        // Get initial values from SettingsManager
        holdDuration = SettingsManager.shared.holdDuration
        napDuration = SettingsManager.shared.napDuration
        maxDuration = SettingsManager.shared.maxDuration
        
        circleSize = SettingsManager.shared.circleSize
        isFullScreenMode = SettingsManager.shared.isFullScreenMode
        showTimerArcs = SettingsManager.shared.showTimerArcs
        showConnectingLine = SettingsManager.shared.showConnectingLine
        
        // Initialize animation settings
        showRippleEffects = SettingsManager.shared.showRippleEffects
        showMiniAnimations = SettingsManager.shared.showMiniAnimations
        showTouchFeedback = SettingsManager.shared.showTouchFeedback
        
        selectedAlarmSound = SettingsManager.shared.selectedAlarmSound
        selectedCustomSoundID = SettingsManager.shared.selectedCustomSoundID
        
        // Initialize timer values
        holdTimer = holdDuration
        napTimer = napDuration
        maxTimer = maxDuration
    }
    
    // MARK: - Property Forwarding
    
    private func setupBindings() {
        setupSettingsBindings()
        setupTimerControllerBindings()
        setupSoundManagerBindings()
        setupCircleSizeBindings()
        print("📱 TimerManager bindings initialized successfully")
    }
    
    private func setupTimerControllerBindings() {
        // Set initial values
        holdTimer = TimerController.shared.holdTimer
        napTimer = TimerController.shared.napTimer
        maxTimer = TimerController.shared.maxTimer
        
        isHoldTimerRunning = TimerController.shared.isHoldTimerRunning
        isNapTimerRunning = TimerController.shared.isNapTimerRunning
        isMaxTimerRunning = TimerController.shared.isMaxTimerRunning
        
        isLogoAnimating = TimerController.shared.isLogoAnimating
        snoozeCount = TimerController.shared.snoozeCount
        isAlarmActive = TimerController.shared.isAlarmActive
        
        // Forward timer values
        TimerController.shared.$holdTimer
            .assign(to: \.holdTimer, on: self)
            .store(in: &cancellables)
            
        TimerController.shared.$napTimer
            .assign(to: \.napTimer, on: self)
            .store(in: &cancellables)
            
        TimerController.shared.$maxTimer
            .assign(to: \.maxTimer, on: self)
            .store(in: &cancellables)
        
        // Forward timer states  
        TimerController.shared.$isHoldTimerRunning
            .assign(to: \.isHoldTimerRunning, on: self)
            .store(in: &cancellables)
            
        TimerController.shared.$isNapTimerRunning
            .assign(to: \.isNapTimerRunning, on: self)
            .store(in: &cancellables)
            
        TimerController.shared.$isMaxTimerRunning
            .assign(to: \.isMaxTimerRunning, on: self)
            .store(in: &cancellables)
            
        // Forward other timer controller properties
        TimerController.shared.$isLogoAnimating
            .assign(to: \.isLogoAnimating, on: self)
            .store(in: &cancellables)
            
        TimerController.shared.$snoozeCount
            .assign(to: \.snoozeCount, on: self)
            .store(in: &cancellables)
            
        TimerController.shared.$isAlarmActive
            .assign(to: \.isAlarmActive, on: self)
            .store(in: &cancellables)
    }
    
    private func setupSettingsBindings() {
        // Forward timer durations
        SettingsManager.shared.$holdDuration
            .assign(to: \.holdDuration, on: self)
            .store(in: &cancellables)
            
        SettingsManager.shared.$napDuration
            .assign(to: \.napDuration, on: self)
            .store(in: &cancellables)
            
        SettingsManager.shared.$maxDuration
            .assign(to: \.maxDuration, on: self)
            .store(in: &cancellables)
            
        // Forward UI settings
        SettingsManager.shared.$showTimerArcs
            .assign(to: \.showTimerArcs, on: self)
            .store(in: &cancellables)
            
        SettingsManager.shared.$showConnectingLine
            .assign(to: \.showConnectingLine, on: self)
            .store(in: &cancellables)
        
        // Forward animation settings
        SettingsManager.shared.$showRippleEffects
            .assign(to: \.showRippleEffects, on: self)
            .store(in: &cancellables)
            
        SettingsManager.shared.$showMiniAnimations
            .assign(to: \.showMiniAnimations, on: self)
            .store(in: &cancellables)
            
        SettingsManager.shared.$showTouchFeedback
            .assign(to: \.showTouchFeedback, on: self)
            .store(in: &cancellables)
        
        // Forward selected sound
        SettingsManager.shared.$selectedAlarmSound
            .assign(to: \.selectedAlarmSound, on: self)
            .store(in: &cancellables)
            
        SettingsManager.shared.$selectedCustomSoundID
            .assign(to: \.selectedCustomSoundID, on: self)
            .store(in: &cancellables)
    }
    
    private func setupSoundManagerBindings() {
        // Set initial values
        customSounds = CustomSoundManager.shared.customSounds
        isExportingMusic = CustomSoundManager.shared.isExportingMusic
        isPlayingAlarm = AudioPlayerManager.shared.isPlayingAlarm
        
        // Forward custom sounds properties
        CustomSoundManager.shared.$customSounds
            .assign(to: \.customSounds, on: self)
            .store(in: &cancellables)
            
        CustomSoundManager.shared.$isExportingMusic
            .assign(to: \.isExportingMusic, on: self)
            .store(in: &cancellables)
            
        // Manually observe isPlayingAlarm from AudioPlayerManager
        AudioPlayerManager.shared.$isPlayingAlarm
            .sink { [weak self] newValue in
                self?.isPlayingAlarm = newValue
            }
            .store(in: &cancellables)
    }
    
    // Forward all CircleSizeManager settings
    private func setupCircleSizeBindings() {
        // Set initial values
        circleSize = CircleSizeManager.shared.circleSize
        isFullScreenMode = CircleSizeManager.shared.isFullScreenMode
        
        // Forward circle size properties
        CircleSizeManager.shared.$circleSize
            .assign(to: \.circleSize, on: self)
            .store(in: &cancellables)
            
        CircleSizeManager.shared.$isFullScreenMode
            .assign(to: \.isFullScreenMode, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Public API
    
    // Timer control
    func startHoldTimer() {
        TimerController.shared.startHoldTimer()
    }
    
    func stopHoldTimer() {
        TimerController.shared.stopHoldTimer()
    }
    
    func startNapTimer() {
        TimerController.shared.startNapTimer()
    }
    
    func stopNapTimer() {
        TimerController.shared.stopNapTimer()
    }
    
    func startMaxTimer() {
        TimerController.shared.startMaxTimer()
    }
    
    func stopMaxTimer() {
        TimerController.shared.stopMaxTimer()
    }
    
    func resetTimers() {
        TimerController.shared.resetTimers()
    }
    
    // Audio control
    func playAlarmSound() {
        AudioPlayerManager.shared.playAlarmSound(
            selectedAlarmSound: selectedAlarmSound,
            selectedCustomSoundID: selectedCustomSoundID,
            customSounds: customSounds
        )
    }
    
    func stopAlarmSound() {
        // Stop audio playback
        AudioPlayerManager.shared.stopAlarmSound()
        isPlayingAlarm = false
        
        // Important: Make sure we also stop ALL vibration sources
        // This fixes the bug where vibration continues after stopping the alarm
        HapticManager.shared.stopAlarmVibration()
        NotificationManager.shared.stopVibrationAlarm()
        
        // Clear any pending notifications
        NotificationManager.shared.cancelPendingNotifications()
    }
    
    func startBackgroundAlarmSound() {
        AudioPlayerManager.shared.startBackgroundAlarmSound(
            selectedAlarmSound: selectedAlarmSound,
            selectedCustomSoundID: selectedCustomSoundID,
            customSounds: customSounds
        )
    }
    
    func previewAlarmSound() {
        playAlarmSound() // Just calls the normal play method
    }
    
    // Custom sound management
    func addCustomSound(name: String, fileURL: URL) {
        if let newSound = CustomSoundManager.shared.addCustomSound(name: name, fileURL: fileURL) {
            // Auto-select the new sound
            selectedAlarmSound = .custom
            selectedCustomSoundID = newSound.id
            
            // Sync changes to SettingsManager and save
            syncToSettingsManager()
            SettingsManager.shared.saveSettings()
        }
    }
    
    func addMusicSound(item: MPMediaItem) {
        if let newSound = CustomSoundManager.shared.addMusicSound(item: item) {
            // Auto-select the new sound
            selectedAlarmSound = .custom
            selectedCustomSoundID = newSound.id
            
            // Sync changes to SettingsManager and save
            syncToSettingsManager()
            SettingsManager.shared.saveSettings()
        }
    }
    
    func removeCustomSound(id: UUID) {
        // If it's the selected sound, deselect it
        if selectedCustomSoundID == id {
            selectedCustomSoundID = nil
            selectedAlarmSound = .firecracker // Fallback to default
        }
        
        CustomSoundManager.shared.removeCustomSound(id: id)
        
        // Sync changes to SettingsManager and save
        syncToSettingsManager()
        SettingsManager.shared.saveSettings()
    }
    
    // Settings
    func saveSettings() {
        SettingsManager.shared.saveSettings()
    }
    
    // Manually sync values from TimerManager to SettingsManager
    private func syncToSettingsManager() {
        SettingsManager.shared.holdDuration = holdDuration
        SettingsManager.shared.napDuration = napDuration
        SettingsManager.shared.maxDuration = maxDuration
        SettingsManager.shared.circleSize = circleSize
        SettingsManager.shared.isFullScreenMode = isFullScreenMode
        SettingsManager.shared.showTimerArcs = showTimerArcs
        SettingsManager.shared.showConnectingLine = showConnectingLine
        SettingsManager.shared.selectedAlarmSound = selectedAlarmSound
        SettingsManager.shared.selectedCustomSoundID = selectedCustomSoundID
    }
    
    func loadSettings() {
        SettingsManager.shared.loadSettings()
        CustomSoundManager.shared.loadCustomSounds()
    }
    
    func loadCustomSounds(skipMusicCheck: Bool = false) {
        CustomSoundManager.shared.loadCustomSounds(skipMusicCheck: skipMusicCheck)
    }
    
    func validateTimerSettings() -> Bool {
        return SettingsManager.shared.validateTimerSettings()
    }
    
    // Time formatting helper
    func formatTime(_ timeInterval: TimeInterval) -> String {
        return SettingsManager.shared.formatTime(timeInterval)
    }
    
    // Computed property
    var isAnyTimerActive: Bool {
        return TimerController.shared.isAnyTimerActive
    }
    
    // Notification helpers
    func registerBuiltInSoundsForNotifications() {
        // This is now just a placeholder method for compatibility
        print("Note: iOS requires notification sounds to be in the app bundle with .caf extension")
    }
    
    func scheduleAlarmNotification() {
        TimerController.shared.scheduleAlarmNotification()
    }
    
    func triggerImmediateAlarmNotification() {
        TimerController.shared.triggerImmediateAlarmNotification()
    }
    
    // Audio setup forwarding method
    func setupBackgroundAudio() {
        AudioPlayerManager.shared.setupBackgroundAudio()
    }
    
    // MARK: - Direct Setting Update Methods
    
    // Timer duration settings
    func setHoldDuration(_ value: TimeInterval) {
        holdDuration = value
        SettingsManager.shared.holdDuration = value
    }
    
    func setNapDuration(_ value: TimeInterval) {
        napDuration = value
        SettingsManager.shared.napDuration = value
    }
    
    func setMaxDuration(_ value: TimeInterval) {
        maxDuration = value
        SettingsManager.shared.maxDuration = value
    }
    
    // UI settings - now forward to CircleSizeManager
    func setCircleSize(_ value: CGFloat) {
        circleSize = value
        CircleSizeManager.shared.circleSize = value
    }
    
    func setFullScreenMode(_ value: Bool) {
        isFullScreenMode = value
        CircleSizeManager.shared.isFullScreenMode = value
    }
    
    func setShowTimerArcs(_ value: Bool) {
        showTimerArcs = value
        SettingsManager.shared.showTimerArcs = value
    }
    
    func setShowConnectingLine(_ value: Bool) {
        showConnectingLine = value
        SettingsManager.shared.showConnectingLine = value
    }
    
    // Sound settings
    func setSelectedAlarmSound(_ value: AlarmSound) {
        selectedAlarmSound = value
        SettingsManager.shared.selectedAlarmSound = value
    }
    
    func setSelectedCustomSoundID(_ value: UUID?) {
        selectedCustomSoundID = value
        SettingsManager.shared.selectedCustomSoundID = value
    }
} 