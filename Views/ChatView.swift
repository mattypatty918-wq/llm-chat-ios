import SwiftUI

// MARK: - Chat ViewModel

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var inputText: String = ""
    @Published var isStreaming: Bool = false
    @Published var errorMessage: String? = nil
    @Published var selectedModel: LLMModel?
    @Published var showModelPicker = false

    var conversation: Conversation
    let gateway: GatewayService
    let settings: AppSettings

    init(conversation: Conversation, gateway: GatewayService, settings: AppSettings) {
        self.conversation  = conversation
        self.gateway       = gateway
        self.settings      = settings
        self.messages      = conversation.messages
    }

    func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isStreaming else { return }
        inputText = ""

        let userMsg = Message(role: .user, content: text)
        messages.append(userMsg)

        let modelID = selectedModel?.id ?? settings.defaultModelID
        let systemPrompt = settings.defaultSystemPrompt.isEmpty ? nil : settings.defaultSystemPrompt

        var assistantMsg = Message(role: .assistant, content: "", isStreaming: true)
        messages.append(assistantMsg)
        let assistantIndex = messages.count - 1
        isStreaming = true
        errorMessage = nil

        gateway.streamChat(
            model: modelID,
            messages: messages.dropLast(),  // exclude the empty assistant msg
            systemPrompt: systemPrompt,
            conversationID: conversation.id,
            onToken: { [weak self] token in
                guard let self else { return }
                self.messages[assistantIndex].content += token
            },
            onComplete: { [weak self] in
                guard let self else { return }
                self.messages[assistantIndex].isStreaming = false
                self.isStreaming = false
            },
            onError: { [weak self] error in
                guard let self else { return }
                self.messages[assistantIndex].content = "Error: \(error.localizedDescription)"
                self.messages[assistantIndex].isStreaming = false
                self.isStreaming = false
                self.errorMessage = error.localizedDescription
            }
        )
    }

    func deleteMessage(at offsets: IndexSet) {
        messages.remove(atOffsets: offsets)
    }

    func clearMessages() {
        messages = []
    }
}

// MARK: - Chat View

struct ChatView: View {
    @StateObject var vm: ChatViewModel
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(vm.messages) { msg in
                            MessageBubbleView(message: msg)
                                .id(msg.id)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .onChange(of: vm.messages.count) { _ in
                    if let last = vm.messages.last {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: vm.messages.last?.content) { _ in
                    if let last = vm.messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }

            Divider()

            // Input bar
            inputBar
        }
        .navigationTitle(vm.conversation.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                modelButton
            }
        }
        .sheet(isPresented: $vm.showModelPicker) {
            ModelPickerView(selectedModel: $vm.selectedModel)
        }
    }

    // MARK: Input bar

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Message", text: $vm.inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...6)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .focused($inputFocused)
                .onSubmit {
                    if !vm.inputText.contains("\n") { vm.send() }
                }

            Button(action: vm.send) {
                Image(systemName: vm.isStreaming ? "stop.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(vm.inputText.isEmpty && !vm.isStreaming ? Color.gray : Color.blue)
            }
            .disabled(vm.inputText.isEmpty && !vm.isStreaming)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    // MARK: Model button in nav bar

    private var modelButton: some View {
        Button {
            vm.showModelPicker = true
        } label: {
            HStack(spacing: 4) {
                Circle()
                    .fill(Color(hex: vm.selectedModel?.providerColor ?? "#10A37F"))
                    .frame(width: 8, height: 8)
                Text(vm.selectedModel?.name ?? "Pick model")
                    .font(.caption)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color(.systemGray6))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Hex color helper

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
