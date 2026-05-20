import Foundation

struct Conversation: Identifiable, Codable {
    let id: String
    var title: String
    var model: String
    let createdAt: Double
    var updatedAt: Double
    var messages: [Message]

    init(id: String = UUID().uuidString, title: String = "New Chat", model: String, createdAt: Double = Date().timeIntervalSince1970, updatedAt: Double = Date().timeIntervalSince1970, messages: [Message] = []) {
        self.id        = id
        self.title     = title
        self.model     = model
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.messages  = messages
    }

    enum CodingKeys: String, CodingKey {
        case id, title, model, messages
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var lastMessage: Message? { messages.last }
    var subtitle: String {
        lastMessage?.content.prefix(60).description ?? "No messages yet"
    }
    var updatedDate: Date { Date(timeIntervalSince1970: updatedAt) }
}
