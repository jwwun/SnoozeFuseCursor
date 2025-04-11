import Foundation

// Custom sound struct for persistence and management
struct CustomSound: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var fileURL: URL
    
    static func == (lhs: CustomSound, rhs: CustomSound) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Only encode the last path component for storage
    enum CodingKeys: String, CodingKey {
        case id, name, fileURLPath
    }
    
    init(id: UUID = UUID(), name: String, fileURL: URL) {
        self.id = id
        self.name = name
        self.fileURL = fileURL
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        
        // Recreate the URL from the stored path
        let path = try container.decode(String.self, forKey: .fileURLPath)
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = documentsDirectory.appendingPathComponent(path)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        
        // Only store the last path component
        try container.encode(fileURL.lastPathComponent, forKey: .fileURLPath)
    }
} 