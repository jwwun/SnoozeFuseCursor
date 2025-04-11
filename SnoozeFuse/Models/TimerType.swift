import Foundation

// Define notification names
extension Notification.Name {
    static let holdTimerFinished = Notification.Name("holdTimerFinished")
    static let napTimerFinished = Notification.Name("napTimerFinished")
    static let maxTimerFinished = Notification.Name("maxTimerFinished")
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