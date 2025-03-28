import Foundation
import Combine

// Define notification names
extension Notification.Name {
    static let holdTimerFinished = Notification.Name("holdTimerFinished")
    static let napTimerFinished = Notification.Name("napTimerFinished")
    static let maxTimerFinished = Notification.Name("maxTimerFinished")
}

class TimerManager: ObservableObject {
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
    @Published var circleSize: CGFloat = 300
    
    // Timer cancellables
    private var holdCancellable: AnyCancellable?
    private var napCancellable: AnyCancellable?
    private var maxCancellable: AnyCancellable?
    
    init() {
        // Initialize timers with default values
        resetTimers()
        
        // Subscribe to changes in duration settings
        setupDurationObservers()
    }
    
    private func setupDurationObservers() {
        // When holdDuration changes, reset holdTimer if not running
        $holdDuration
            .sink { [weak self] newDuration in
                guard let self = self else { return }
                if !self.isHoldTimerRunning {
                    self.holdTimer = newDuration
                }
            }
            .store(in: &cancellables)
        
        // When napDuration changes, reset napTimer if not running
        $napDuration
            .sink { [weak self] newDuration in
                guard let self = self else { return }
                if !self.isNapTimerRunning {
                    self.napTimer = newDuration
                }
            }
            .store(in: &cancellables)
        
        // When maxDuration changes, reset maxTimer if not running
        $maxDuration
            .sink { [weak self] newDuration in
                guard let self = self else { return }
                if !self.isMaxTimerRunning {
                    self.maxTimer = newDuration
                }
            }
            .store(in: &cancellables)
    }
    
    // Storage for cancellables
    private var cancellables = Set<AnyCancellable>()
    
    func resetTimers() {
        holdTimer = holdDuration
        napTimer = napDuration
        maxTimer = maxDuration
    }
    
    func startHoldTimer() {
        isHoldTimerRunning = true
        holdTimer = holdDuration // Reset to full duration
        
        holdCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.holdTimer > 0 {
                    self.holdTimer -= 0.1
                } else {
                    self.stopHoldTimer()
                    // Post notification when hold timer reaches zero
                    NotificationCenter.default.post(name: .holdTimerFinished, object: nil)
                }
            }
    }
    
    func stopHoldTimer() {
        isHoldTimerRunning = false
        holdCancellable?.cancel()
    }
    
    func startNapTimer() {
        isNapTimerRunning = true
        napTimer = napDuration // Reset to full duration
        
        napCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.napTimer > 0 {
                    self.napTimer -= 0.1
                } else {
                    self.stopNapTimer()
                    // Post notification when nap timer reaches zero
                    NotificationCenter.default.post(name: .napTimerFinished, object: nil)
                }
            }
    }
    
    func stopNapTimer() {
        isNapTimerRunning = false
        napCancellable?.cancel()
    }
    
    func startMaxTimer() {
        isMaxTimerRunning = true
        maxTimer = maxDuration // Reset to full duration
        
        maxCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.maxTimer > 0 {
                    self.maxTimer -= 0.1
                } else {
                    self.stopMaxTimer()
                    // Post notification when max timer reaches zero
                    NotificationCenter.default.post(name: .maxTimerFinished, object: nil)
                }
            }
    }
    
    func stopMaxTimer() {
        isMaxTimerRunning = false
        maxCancellable?.cancel()
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
        return String(format: "%02d:%02d.%d", minutes, seconds, decimal)
    }
}
