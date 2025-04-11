import Foundation
import Combine

class TimerController: ObservableObject {
    // Shared instance
    static let shared = TimerController()
    
    // Current timer values
    @Published var holdTimer: TimeInterval = 5
    @Published var napTimer: TimeInterval = 60
    @Published var maxTimer: TimeInterval = 120
    
    // Timer states
    @Published var isHoldTimerRunning = false
    @Published var isNapTimerRunning = false
    @Published var isMaxTimerRunning = false
    
    // Animation state
    @Published var isLogoAnimating = false
    
    // Snooze functionality
    @Published var snoozeCount = 0
    @Published var isAlarmActive = false
    
    // Timer cancellables
    private var holdCancellable: AnyCancellable?
    private var napCancellable: AnyCancellable?
    private var maxCancellable: AnyCancellable?
    
    // Storage for cancellables
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        resetTimers()
        setupDurationObservers()
    }
    
    private func setupDurationObservers() {
        // When settings change, update our timers
        SettingsManager.shared.$holdDuration
            .sink { [weak self] newDuration in
                guard let self = self, !self.isHoldTimerRunning else { return }
                self.holdTimer = newDuration
            }
            .store(in: &cancellables)
        
        SettingsManager.shared.$napDuration
            .sink { [weak self] newDuration in
                guard let self = self, !self.isNapTimerRunning else { return }
                self.napTimer = newDuration
            }
            .store(in: &cancellables)
        
        SettingsManager.shared.$maxDuration
            .sink { [weak self] newDuration in
                guard let self = self, !self.isMaxTimerRunning else { return }
                self.maxTimer = newDuration
            }
            .store(in: &cancellables)
    }
    
    // Reset timers to their initial values from settings
    func resetTimers() {
        holdTimer = SettingsManager.shared.holdDuration
        napTimer = SettingsManager.shared.napDuration
        maxTimer = SettingsManager.shared.maxDuration
    }
    
    // Computed property to check if any timer is active
    var isAnyTimerActive: Bool {
        return isHoldTimerRunning || isNapTimerRunning || isMaxTimerRunning
    }
    
    // MARK: - Timer Control
    
    // Generic timer start function
    private func startTimer(type: TimerType) {
        switch type {
        case .hold:
            isHoldTimerRunning = true
            holdTimer = SettingsManager.shared.holdDuration
            
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
            napTimer = SettingsManager.shared.napDuration
            
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
            maxTimer = SettingsManager.shared.maxDuration
            
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
            holdTimer = SettingsManager.shared.holdDuration
        case .nap:
            isNapTimerRunning = false
            napCancellable?.cancel()
        case .max:
            isMaxTimerRunning = false
            maxCancellable?.cancel()
        }
    }
    
    // MARK: - Public Timer Control Functions
    
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
    
    // Schedule notification for when alarm will go off
    func scheduleAlarmNotification() {
        let timeInterval = isNapTimerRunning ? napTimer : maxTimer
        NotificationManager.shared.scheduleAlarmNotification(after: timeInterval)
    }
    
    // Trigger an immediate notification to use the system's alarm vibration pattern
    func triggerImmediateAlarmNotification() {
        NotificationManager.shared.triggerImmediateAlarmWithVibration()
    }
} 