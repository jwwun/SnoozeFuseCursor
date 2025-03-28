import Foundation
import Combine

class TimerManager: ObservableObject {
    // Timer durations (defaults)
    @Published var holdDuration: TimeInterval = 30    // Timer A: 30 seconds default
    @Published var napDuration: TimeInterval = 1200   // Timer B: 20 minutes default
    @Published var maxDuration: TimeInterval = 1800   // Timer C: 30 minutes default
    
    // Current timer values
    @Published var holdTimer: TimeInterval = 30
    @Published var napTimer: TimeInterval = 1200
    @Published var maxTimer: TimeInterval = 1800
    
    // Timer states
    @Published var isHoldTimerRunning = false
    @Published var isNapTimerRunning = false
    @Published var isMaxTimerRunning = false
    
    // Timer cancellables
    private var holdCancellable: AnyCancellable?
    private var napCancellable: AnyCancellable?
    private var maxCancellable: AnyCancellable?
    
    init() {
        // Initialize timers with default values
        resetTimers()
    }
    
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
                    self.startNapTimer()
                }
            }
    }
    
    func stopHoldTimer() {
        isHoldTimerRunning = false
        holdCancellable?.cancel()
    }
    
    func startNapTimer() {
        isNapTimerRunning = true
        
        napCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.napTimer > 0 {
                    self.napTimer -= 0.1
                } else {
                    self.stopNapTimer()
                    // We'll add alarm logic here
                }
            }
    }
    
    func stopNapTimer() {
        isNapTimerRunning = false
        napCancellable?.cancel()
    }
    
    func startMaxTimer() {
        isMaxTimerRunning = true
        
        maxCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.maxTimer > 0 {
                    self.maxTimer -= 0.1
                } else {
                    self.stopMaxTimer()
                    // We'll add force wake logic here
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
