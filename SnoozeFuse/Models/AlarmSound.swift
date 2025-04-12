import Foundation

// Available alarm sounds
enum AlarmSound: String, CaseIterable, Identifiable {
    case vtuber = "Ohio_Ohayō's Edit of Korone, Gawr Gura, Watson Amelia"
    case firecracker = "Firecracker"
    case beep = "Computer Beep"
    case warAmbience = "War Ambience"
    case custom = "Custom Sound"
    
    var id: String { self.rawValue }
    
    var filename: String {
        switch self {
        case .vtuber: return "vtuber"
        case .firecracker: return "firecracker"
        case .beep: return "beep"
        case .warAmbience: return "war ambience"
        case .custom: return "customSound"
        }
    }
    
    var fileExtension: String {
        switch self {
        case .vtuber, .beep, .firecracker: return "caf"
        case .warAmbience: return "wav"
        case .custom: return "mp3"
        }
    }
} 