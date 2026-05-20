import Foundation

// MARK: - Errors

enum GatewayError: LocalizedError {
    case invalidURL
    case httpError(Int, String)
    case decodingError
    case noModelsAvailable
    case notConnected

    var errorDescription: String? {
        switch self {
        case .invalidURL:              return "Invalid gateway URL."
        case .httpError(let c, let m): return "HTTP \(c): \(m)"
        case .decodingError:           return "Failed to decode response."
        case .noModelsAvailable:       return "No models available from gateway."
        case .notConnected:            return "Cannot reach gateway. Check your URL and network."
        }
    }
}

// MARK: - SSE Chunk decoders

private struct StreamChunk: Decodable {
    struct Choice: Decodable {
        struct Delta: Decodable { var content: String? }
        var delta: Delta
    }
    var choices: [Choice]
}

// MARK: - Gateway Service

@MainActor
final class GatewayService: ObservableObject {

    private let settings: AppSettings

    init(settings: AppSettings) {
        self.settings = settings
    }

    private var baseURL: String { settings.gatewayURL.trimmingCharacters(in: .init(charactersIn: "/")) }

    private func makeRequest(path: String, method: String = "GET", body: Data? = nil) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)\(path)") else { throw GatewayError.invalidURL }
        var req = URLRequest(url: url, timeoutInterval: 120)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let key = settings.gatewayAPIKey.trimmingCharacters(in: .whitespaces)
        if !key.isEmpty {
            req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = body
        return req
    }

    // MARK: - Models

    func fetchModels() async throws -> [LLMModel] {
        let req = try makeRequest(path: "/v1/models")
        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            let msg = String(data: data, encoding: .utf8) ?? ""
            throw GatewayError.httpError(http.statusCode, msg)
        }
        let decoded = try JSONDecoder().decode(ModelsResponse.self, from: data)
        return decoded.data
    }

    // MARK: - Conversations CRUD

    func fetchConversations() async throws -> [Conversation] {
        let req = try makeRequest(path: "/v1/conversations")
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode([Conversation].self, from: data)
    }

    func createConversation(model: String, title: String = "New Chat") async throws -> Conversation {
        let body = try JSONEncoder().encode(["model": model, "title": title])
        let req  = try makeRequest(path: "/v1/conversations", method: "POST", body: body)
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(Conversation.self, from: data)
    }

    func deleteConversation(id: String) async throws {
        let req = try makeRequest(path: "/v1/conversations/\(id)", method: "DELETE")
        _ = try await URLSession.shared.data(for: req)
    }

    func renameConversation(id: String, title: String) async throws {
        let body = try JSONEncoder().encode(["title": title])
        let req  = try makeRequest(path: "/v1/conversations/\(id)", method: "PATCH", body: body)
        _ = try await URLSession.shared.data(for: req)
    }

    // MARK: - Streaming chat

    func streamChat(
        model: String,
        messages: [Message],
        systemPrompt: String? = nil,
        conversationID: String? = nil,
        onToken: @escaping (String) -> Void,
        onComplete: @escaping () -> Void,
        onError: @escaping (Error) -> Void
    ) {
        Task {
            do {
                var apiMessages: [[String: String]] = []
                if let sys = systemPrompt, !sys.isEmpty {
                    apiMessages.append(["role": "system", "content": sys])
                }
                apiMessages += messages.map { ["role": $0.role.rawValue, "content": $0.content] }

                var payload: [String: Any] = [
                    "model": model,
                    "messages": apiMessages,
                    "stream": true,
                ]
                if let cid = conversationID { payload["conversation_id"] = cid }

                let body = try JSONSerialization.data(withJSONObject: payload)
                let req  = try makeRequest(path: "/v1/chat/completions", method: "POST", body: body)

                let (bytes, response) = try await URLSession.shared.bytes(for: req)

                if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                    var errBody = ""
                    for try await byte in bytes { errBody += String(UnicodeScalar(byte)) }
                    throw GatewayError.httpError(http.statusCode, errBody)
                }

                for try await line in bytes.lines {
                    guard line.hasPrefix("data: ") else { continue }
                    let payload = String(line.dropFirst(6))
                    if payload == "[DONE]" { break }
                    guard
                        let data  = payload.data(using: .utf8),
                        let chunk = try? JSONDecoder().decode(StreamChunk.self, from: data),
                        let text  = chunk.choices.first?.delta.content
                    else { continue }
                    await MainActor.run { onToken(text) }
                }
                await MainActor.run { onComplete() }

            } catch {
                await MainActor.run { onError(error) }
            }
        }
    }

    // MARK: - Health check

    func ping() async -> Bool {
        guard let req = try? makeRequest(path: "/health") else { return false }
        let req2 = { () -> URLRequest in
            var r = req; r.timeoutInterval = 5; return r
        }()
        guard let (_, response) = try? await URLSession.shared.data(for: req2) else { return false }
        return (response as? HTTPURLResponse)?.statusCode == 200
    }
}
