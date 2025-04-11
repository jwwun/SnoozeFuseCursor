import Foundation

// Available alarm sounds
enum AlarmSound: String, CaseIterable, Identifiable {
    case testAlarm = "Korone, Gura, Amelia, Kureiji - Yobio Mix"
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