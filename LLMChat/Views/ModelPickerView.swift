import SwiftUI

// MARK: - Model Picker ViewModel

@MainActor
final class ModelPickerViewModel: ObservableObject {
    @Published var models: [LLMModel] = LLMModel.fallbackCatalog
    @Published var installedOllamaModels: [OllamaInstalledModel] = []
    @Published var searchText = ""
    @Published var filterFreeOnly = false
    @Published var isLoading = false

    private let gateway: GatewayService?
    private let ollama: OllamaService?

    init(gateway: GatewayService? = nil, ollama: OllamaService? = nil) {
        self.gateway = gateway
        self.ollama  = ollama
    }

    func load() async {
        isLoading = true
        // Fetch model list from gateway
        if let gateway {
            do {
                let fetched = try await gateway.fetchModels()
                if !fetched.isEmpty { models = fetched }
            } catch {}
        }
        // Fetch installed Ollama models
        if let ollama {
            await ollama.refreshModels()
            installedOllamaModels = ollama.installedModels
        }
        isLoading = false
    }

    /// Installed Ollama models as LLMModel entries (always shown first)
    var installedLocalModels: [LLMModel] {
        installedOllamaModels.map { installed in
            LLMModel(
                id: "ollama/\(installed.name)",
                name: installed.name,
                provider: "ollama",
                free: true,
                contextLength: 128_000,
                description: "Installed locally - \(installed.sizeDisplay)",
                supportsVision: false,
                supportsTools: false,
                tags: ["local"],
                pricingNote: installed.sizeDisplay,
                available: true,
                missingKey: nil
            )
        }
    }

    var groupedModels: [(String, [LLMModel])] {
        let filtered = models.filter { model in
            // Don't double-list ollama models already shown in installed section
            if model.provider == "ollama" { return false }
            let matchesSearch = searchText.isEmpty ||
                model.name.localizedCaseInsensitiveContains(searchText) ||
                model.providerDisplay.localizedCaseInsensitiveContains(searchText) ||
                model.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            let matchesFree = !filterFreeOnly || model.free
            return matchesSearch && matchesFree
        }

        var groups: [(String, [LLMModel])] = []

        // FIRST: installed local models (highest priority)
        let localFiltered = installedLocalModels.filter { model in
            searchText.isEmpty ||
            model.name.localizedCaseInsensitiveContains(searchText)
        }
        if !localFiltered.isEmpty {
            groups.append(("Local (Self-Hosted)", localFiltered))
        }

        // Free cloud providers
        let free = filtered.filter { $0.free }
        let freeByProvider = Dictionary(grouping: free, by: \.providerDisplay)
        for provider in freeByProvider.keys.sorted() {
            groups.append(("Free - \(provider)", freeByProvider[provider] ?? []))
        }

        // Paid cloud providers
        let paid = filtered.filter { !$0.free }
        let paidByProvider = Dictionary(grouping: paid, by: \.providerDisplay)
        for provider in paidByProvider.keys.sorted() {
            groups.append(("Paid - \(provider)", paidByProvider[provider] ?? []))
        }

        return groups
    }
}

// MARK: - Model Picker View

struct ModelPickerView: View {
    @Binding var selectedModel: LLMModel?
    @StateObject private var vm = ModelPickerViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Filters
                Section {
                    Toggle("Free only", isOn: $vm.filterFreeOnly)
                }

                if vm.isLoading {
                    Section {
                        HStack {
                            ProgressView()
                            Text("Loading models…").foregroundStyle(.secondary)
                        }
                    }
                }

                ForEach(vm.groupedModels, id: \.0) { (sectionTitle, models) in
                    Section(sectionTitle) {
                        ForEach(models) { model in
                            modelRow(model)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $vm.searchText, prompt: "Search models, providers, tags…")
            .navigationTitle("Choose Model")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .task { await vm.load() }
    }

    @ViewBuilder
    private func modelRow(_ model: LLMModel) -> some View {
        Button {
            selectedModel = model
            dismiss()
        } label: {
            HStack(spacing: 12) {
                // Provider dot
                Circle()
                    .fill(Color(hex: model.providerColor))
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(model.name)
                            .font(.body)
                            .foregroundStyle(model.available ? .primary : .secondary)

                        if model.free {
                            Text("FREE")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.green)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.12))
                                .clipShape(Capsule())
                        } else if !model.pricingNote.isEmpty {
                            Text(model.pricingNote)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }

                    HStack(spacing: 6) {
                        Text(model.contextDisplay)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        tagsRow(model)
                    }

                    if !model.available, let key = model.missingKey {
                        Text("Add \(key) in Settings")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }

                Spacer()

                if selectedModel?.id == model.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(model.available ? 1 : 0.55)
    }

    @ViewBuilder
    private func tagsRow(_ model: LLMModel) -> some View {
        let displayTags: [(String, String)] = [
            ("reasoning", "🧠"),
            ("coding",    "💻"),
            ("vision",    "👁"),
            ("fast",      "⚡️"),
            ("search",    "🔍"),
            ("local",     "🏠"),
        ]
        HStack(spacing: 3) {
            ForEach(displayTags, id: \.0) { tag, emoji in
                if model.tags.contains(tag) {
                    Text(emoji)
                        .font(.caption2)
                }
            }
        }
    }
}
