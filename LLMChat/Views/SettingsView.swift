import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @State private var pingResult: String? = nil
    @State private var isPinging = false
    @State private var showModelPicker = false
    @State private var defaultModel: LLMModel? = nil

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Gateway
                Section {
                    LabeledContent("Gateway URL") {
                        TextField("http://localhost:8000", text: $settings.gatewayURL)
                            .multilineTextAlignment(.trailing)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                    }
                    LabeledContent("API Key") {
                        SecureField("Optional", text: $settings.gatewayAPIKey)
                            .multilineTextAlignment(.trailing)
                    }
                    Button {
                        Task { await pingGateway() }
                    } label: {
                        HStack {
                            Text(isPinging ? "Testing…" : "Test Connection")
                            Spacer()
                            if let result = pingResult {
                                Text(result)
                                    .foregroundStyle(result.contains("✓") ? .green : .red)
                            }
                            if isPinging { ProgressView().scaleEffect(0.8) }
                        }
                    }
                } header: {
                    Text("Gateway Server")
                } footer: {
                    Text("Run the gateway on Oracle Cloud free tier or any Linux machine. Then enter its public IP here.")
                }

                // MARK: Default model
                Section("Defaults") {
                    Button {
                        showModelPicker = true
                    } label: {
                        LabeledContent("Default Model") {
                            Text(defaultModel?.name ?? modelNameFromID(settings.defaultModelID))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .foregroundStyle(.primary)
                    .sheet(isPresented: $showModelPicker) {
                        ModelPickerView(selectedModel: $defaultModel)
                    }
                    .onChange(of: defaultModel) { model in
                        if let model { settings.defaultModelID = model.id }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("System Prompt")
                            .font(.subheadline)
                        TextEditor(text: $settings.defaultSystemPrompt)
                            .frame(minHeight: 80)
                            .font(.body)
                    }
                    .padding(.vertical, 4)
                }

                // MARK: UI
                Section("Interface") {
                    Toggle("Streaming", isOn: $settings.streamingEnabled)
                    Toggle("Haptic Feedback", isOn: $settings.hapticFeedback)
                    Toggle("Show Model Badge", isOn: $settings.showModelBadge)
                }

                // MARK: API Keys info
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API keys are stored on your gateway server in the .env file, not on this device. Free providers (Groq, Cerebras, Gemini, OpenRouter) need no payment — just sign up and paste the key.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("About API Keys")
                }

                // MARK: Free provider quick-links
                Section("Get Free API Keys") {
                    providerLink("Groq (fastest free)",   url: "https://console.groq.com/keys")
                    providerLink("Cerebras",              url: "https://cloud.cerebras.ai")
                    providerLink("Google Gemini",         url: "https://aistudio.google.com/app/apikey")
                    providerLink("OpenRouter (30+ free)", url: "https://openrouter.ai/keys")
                    providerLink("Cloudflare Workers AI", url: "https://dash.cloudflare.com")
                    providerLink("HuggingFace",           url: "https://huggingface.co/settings/tokens")
                }

                // MARK: Deploy links
                Section("Deploy Gateway") {
                    providerLink("Oracle Cloud (always-free Linux VM)", url: "https://cloud.oracle.com/free")
                    providerLink("Fly.io free tier",    url: "https://fly.io")
                    providerLink("Tailscale (remote access)", url: "https://tailscale.com")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: Helpers

    @ViewBuilder
    private func providerLink(_ title: String, url: String) -> some View {
        Link(destination: URL(string: url)!) {
            HStack {
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func pingGateway() async {
        isPinging   = true
        pingResult  = nil
        // Build a temporary service to ping
        let svc = GatewayService(settings: settings)
        let ok  = await svc.ping()
        pingResult  = ok ? "✓ Connected" : "✗ Unreachable"
        isPinging   = false
    }

    private func modelNameFromID(_ id: String) -> String {
        LLMModel.fallbackCatalog.first(where: { $0.id == id })?.name ?? id
    }
}
