import Foundation

// MARK: - Ollama model types

struct OllamaInstalledModel: Identifiable, Codable {
    let name: String
    let size: Int64
    let digest: String
    let modifiedAt: String

    var id: String { name }

    enum CodingKeys: String, CodingKey {
        case name, size, digest
        case modifiedAt = "modified_at"
    }

    var sizeDisplay: String {
        let gb = Double(size) / 1_073_741_824
        if gb >= 1 { return String(format: "%.1f GB", gb) }
        let mb = Double(size) / 1_048_576
        return String(format: "%.0f MB", mb)
    }

    // Gateway model ID for chat
    var gatewayModelID: String { "ollama/\(name)" }
}

struct OllamaTagsResponse: Codable {
    let models: [OllamaInstalledModel]
}

struct OllamaPullProgress: Identifiable {
    var id = UUID()
    var status: String
    var completed: Int64?
    var total: Int64?
    var digest: String?

    var fraction: Double {
        guard let c = completed, let t = total, t > 0 else { return 0 }
        return Double(c) / Double(t)
    }

    var isDownloading: Bool {
        status.lowercased().contains("pulling") || status.lowercased().contains("downloading")
    }
}

struct OllamaRunningModel: Identifiable, Codable {
    let name: String
    let sizeVram: Int64?

    var id: String { name }

    enum CodingKeys: String, CodingKey {
        case name
        case sizeVram = "size_vram"
    }
}

struct OllamaRunningResponse: Codable {
    let models: [OllamaRunningModel]
}

// MARK: - Recommended models to pull

struct RecommendedModel: Identifiable {
    let id: String          // Ollama pull name  e.g. "llama3.1:8b"
    let displayName: String
    let description: String
    let sizeEstimate: String  // approximate download size
    let tags: [String]
    let ramRequired: String   // minimum RAM on the host
}

extension RecommendedModel {
    static let all: [RecommendedModel] = [
        // ── Fast & small ──────────────────────────────────────────────────
        RecommendedModel(id: "llama3.2:3b",          displayName: "Llama 3.2 3B",          description: "Smallest capable Llama. Fastest option on low RAM.",        sizeEstimate: "2.0 GB",  tags: ["fast","small","general"],    ramRequired: "4 GB"),
        RecommendedModel(id: "phi4-mini",             displayName: "Phi-4 Mini",             description: "Microsoft's compact powerhouse. Punches above its size.",    sizeEstimate: "2.5 GB",  tags: ["fast","small","coding"],     ramRequired: "4 GB"),
        RecommendedModel(id: "qwen2.5:3b",            displayName: "Qwen 2.5 3B",            description: "Strong multilingual small model.",                           sizeEstimate: "2.0 GB",  tags: ["fast","small","coding"],     ramRequired: "4 GB"),

        // ── Best balance (Oracle 24GB fits these easily) ──────────────────
        RecommendedModel(id: "llama3.1:8b",           displayName: "Llama 3.1 8B",           description: "The go-to open model. Great all-rounder.",                   sizeEstimate: "4.7 GB",  tags: ["general","fast"],            ramRequired: "8 GB"),
        RecommendedModel(id: "mistral:7b",            displayName: "Mistral 7B",             description: "Fast, smart, great at following instructions.",              sizeEstimate: "4.1 GB",  tags: ["fast","general"],            ramRequired: "8 GB"),
        RecommendedModel(id: "gemma3:9b",             displayName: "Gemma 3 9B",             description: "Google's open model. Strong reasoning.",                     sizeEstimate: "5.5 GB",  tags: ["general","reasoning"],       ramRequired: "8 GB"),
        RecommendedModel(id: "phi4",                  displayName: "Phi-4 14B",              description: "Microsoft's best open model. Exceptional for its size.",     sizeEstimate: "8.9 GB",  tags: ["general","coding","fast"],   ramRequired: "12 GB"),
        RecommendedModel(id: "qwen2.5:14b",           displayName: "Qwen 2.5 14B",           description: "Strong coding and reasoning.",                               sizeEstimate: "9.0 GB",  tags: ["general","coding"],          ramRequired: "12 GB"),

        // ── Reasoning ─────────────────────────────────────────────────────
        RecommendedModel(id: "deepseek-r1:7b",        displayName: "DeepSeek R1 7B",         description: "Reasoning model. Shows its thinking. Impressive at 7B.",    sizeEstimate: "4.7 GB",  tags: ["reasoning","general"],       ramRequired: "8 GB"),
        RecommendedModel(id: "deepseek-r1:14b",       displayName: "DeepSeek R1 14B",        description: "Better reasoning than the 7B. Fits Oracle free tier.",       sizeEstimate: "9.0 GB",  tags: ["reasoning","general"],       ramRequired: "12 GB"),
        RecommendedModel(id: "qwq:32b",               displayName: "Qwen QwQ 32B",           description: "Strong reasoning. Slow on CPU but thorough.",                sizeEstimate: "20 GB",   tags: ["reasoning"],                 ramRequired: "24 GB"),

        // ── Coding ────────────────────────────────────────────────────────
        RecommendedModel(id: "qwen2.5-coder:7b",      displayName: "Qwen 2.5 Coder 7B",     description: "Best small coding model. Knows 90+ languages.",             sizeEstimate: "4.7 GB",  tags: ["coding","fast"],             ramRequired: "8 GB"),
        RecommendedModel(id: "qwen2.5-coder:14b",     displayName: "Qwen 2.5 Coder 14B",    description: "Better coding quality. Fits Oracle free tier.",              sizeEstimate: "9.0 GB",  tags: ["coding"],                    ramRequired: "12 GB"),
        RecommendedModel(id: "devstral",              displayName: "Devstral",               description: "Mistral's agentic coding model. Built for code agents.",     sizeEstimate: "14 GB",   tags: ["coding","agents"],           ramRequired: "16 GB"),
        RecommendedModel(id: "codellama:13b",         displayName: "Code Llama 13B",         description: "Meta's dedicated code model.",                               sizeEstimate: "7.4 GB",  tags: ["coding"],                    ramRequired: "10 GB"),

        // ── Large (needs full 24GB Oracle or better) ──────────────────────
        RecommendedModel(id: "llama3.1:70b-instruct-q2_K", displayName: "Llama 3.1 70B Q2", description: "Huge model, heavily compressed. Needs 24GB+. Slow on CPU.", sizeEstimate: "26 GB",   tags: ["large","general"],           ramRequired: "28 GB"),
        RecommendedModel(id: "mixtral:8x7b",          displayName: "Mixtral 8x7B MoE",       description: "Mixture-of-experts. 47B params but only activates 13B.",    sizeEstimate: "26 GB",   tags: ["large","general"],           ramRequired: "28 GB"),
    ]
}

// MARK: - Ollama Service

@MainActor
final class OllamaService: ObservableObject {
    @Published var installedModels: [OllamaInstalledModel] = []
    @Published var runningModels: [OllamaRunningModel] = []
    @Published var pullProgresses: [String: OllamaPullProgress] = [:]
    @Published var isOnline: Bool = false
    @Published var isLoading = false

    private let settings: AppSettings

    init(settings: AppSettings) {
        self.settings = settings
    }

    private var base: String { settings.gatewayURL.trimmingCharacters(in: .init(charactersIn: "/")) }

    private func authHeader() -> [String: String] {
        let key = settings.gatewayAPIKey.trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty else { return [:] }
        return ["Authorization": "Bearer \(key)"]
    }

    private func get(_ path: String) async throws -> Data {
        guard let url = URL(string: "\(base)\(path)") else { throw GatewayError.invalidURL }
        var req = URLRequest(url: url, timeoutInterval: 10)
        authHeader().forEach { req.setValue($1, forHTTPHeaderField: $0) }
        let (data, _) = try await URLSession.shared.data(for: req)
        return data
    }

    // MARK: Fetch installed models

    func refreshModels() async {
        isLoading = true
        do {
            let data = try await get("/ollama/tags")
            let resp = try JSONDecoder().decode(OllamaTagsResponse.self, from: data)
            installedModels = resp.models
            isOnline = true
        } catch {
            isOnline = false
        }
        do {
            let data = try await get("/ollama/running")
            let resp = try JSONDecoder().decode(OllamaRunningResponse.self, from: data)
            runningModels = resp.models
        } catch {}
        isLoading = false
    }

    // MARK: Pull a model

    func pull(name: String) {
        guard let url = URL(string: "\(base)/ollama/pull") else { return }
        var progress = OllamaPullProgress(status: "Queued")
        pullProgresses[name] = progress

        Task {
            do {
                var req = URLRequest(url: url, timeoutInterval: 3600)
                req.httpMethod = "POST"
                req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                authHeader().forEach { req.setValue($1, forHTTPHeaderField: $0) }
                req.httpBody = try JSONEncoder().encode(["name": name, "stream": true])

                let (bytes, _) = try await URLSession.shared.bytes(for: req)
                for try await line in bytes.lines {
                    guard !line.isEmpty,
                          let data = line.data(using: .utf8),
                          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                    else { continue }

                    progress.status    = json["status"]    as? String ?? progress.status
                    progress.digest    = json["digest"]    as? String
                    progress.total     = (json["total"]    as? NSNumber)?.int64Value
                    progress.completed = (json["completed"] as? NSNumber)?.int64Value
                    pullProgresses[name] = progress
                }

                progress.status = "Done"
                pullProgresses[name] = progress
                await refreshModels()

            } catch {
                progress.status = "Error: \(error.localizedDescription)"
                pullProgresses[name] = progress
            }
        }
    }

    // MARK: Delete a model

    func delete(name: String) async throws {
        guard let url = URL(string: "\(base)/ollama/delete") else { throw GatewayError.invalidURL }
        var req = URLRequest(url: url, timeoutInterval: 30)
        req.httpMethod = "DELETE"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        authHeader().forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.httpBody = try JSONEncoder().encode(["name": name])
        _ = try await URLSession.shared.data(for: req)
        installedModels.removeAll { $0.name == name }
    }

    // MARK: Helpers

    func isInstalled(_ name: String) -> Bool {
        installedModels.contains { $0.name == name || $0.name.hasPrefix(name) }
    }

    func pullProgress(for name: String) -> OllamaPullProgress? {
        pullProgresses[name]
    }

    func isRunning(_ name: String) -> Bool {
        runningModels.contains { $0.name == name }
    }
}
