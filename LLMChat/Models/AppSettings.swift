import Foundation
import Combine

final class AppSettings: ObservableObject {

    // Gateway
    @Published var gatewayURL: String {
        didSet { UserDefaults.standard.set(gatewayURL, forKey: "gatewayURL") }
    }
    @Published var gatewayAPIKey: String {
        didSet { UserDefaults.standard.set(gatewayAPIKey, forKey: "gatewayAPIKey") }
    }

    // Default model
    @Published var defaultModelID: String {
        didSet { UserDefaults.standard.set(defaultModelID, forKey: "defaultModelID") }
    }

    // Default system prompt
    @Published var defaultSystemPrompt: String {
        didSet { UserDefaults.standard.set(defaultSystemPrompt, forKey: "defaultSystemPrompt") }
    }

    // UI preferences
    @Published var streamingEnabled: Bool {
        didSet { UserDefaults.standard.set(streamingEnabled, forKey: "streamingEnabled") }
    }
    @Published var hapticFeedback: Bool {
        didSet { UserDefaults.standard.set(hapticFeedback, forKey: "hapticFeedback") }
    }
    @Published var showModelBadge: Bool {
        didSet { UserDefaults.standard.set(showModelBadge, forKey: "showModelBadge") }
    }

    init() {
        gatewayURL         = UserDefaults.standard.string(forKey: "gatewayURL")         ?? "http://localhost:8000"
        gatewayAPIKey      = UserDefaults.standard.string(forKey: "gatewayAPIKey")      ?? ""
        defaultModelID     = UserDefaults.standard.string(forKey: "defaultModelID")     ?? "groq/llama-3.3-70b-versatile"
        defaultSystemPrompt = UserDefaults.standard.string(forKey: "defaultSystemPrompt") ?? ""
        streamingEnabled   = UserDefaults.standard.object(forKey: "streamingEnabled")   as? Bool ?? true
        hapticFeedback     = UserDefaults.standard.object(forKey: "hapticFeedback")     as? Bool ?? true
        showModelBadge     = UserDefaults.standard.object(forKey: "showModelBadge")     as? Bool ?? true
    }
}
