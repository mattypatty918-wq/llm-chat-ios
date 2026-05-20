import Foundation

struct Message: Identifiable, Codable, Equatable {
    let id: UUID
    var role: MessageRole
    var content: String
    let timestamp: Date
    var isStreaming: Bool

    init(id: UUID = UUID(), role: MessageRole, content: String, timestamp: Date = Date(), isStreaming: Bool = false) {
        self.id        = id
        self.role      = role
        self.content   = content
        self.timestamp = timestamp
        self.isStreaming = isStreaming
    }

    var isUser:      Bool { role == .user }
    var isAssistant: Bool { role == .assistant }
}

enum MessageRole: String, Codable {
    case user, assistant, system
}
