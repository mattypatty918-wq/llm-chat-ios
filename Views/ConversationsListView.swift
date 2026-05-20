import SwiftUI

// MARK: - Conversations ViewModel

@MainActor
final class ConversationsViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var gatewayOnline: Bool? = nil

    let gateway: GatewayService
    let settings: AppSettings

    init(gateway: GatewayService, settings: AppSettings) {
        self.gateway  = gateway
        self.settings = settings
    }

    func load() async {
        isLoading = true
        do {
            conversations = try await gateway.fetchConversations()
            gatewayOnline = true
        } catch {
            errorMessage  = error.localizedDescription
            gatewayOnline = false
        }
        isLoading = false
    }

    func newConversation(model: String) async -> Conversation? {
        do {
            let conv = try await gateway.createConversation(model: model)
            conversations.insert(conv, at: 0)
            return conv
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func delete(at offsets: IndexSet) {
        let ids = offsets.map { conversations[$0].id }
        conversations.remove(atOffsets: offsets)
        Task {
            for id in ids {
                try? await gateway.deleteConversation(id: id)
            }
        }
    }

    func rename(conv: Conversation, title: String) {
        guard let idx = conversations.firstIndex(where: { $0.id == conv.id }) else { return }
        conversations[idx].title = title
        Task { try? await gateway.renameConversation(id: conv.id, title: title) }
    }
}

// MARK: - Conversations List View

struct ConversationsListView: View {
    @StateObject private var vm: ConversationsViewModel
    @EnvironmentObject var settings: AppSettings
    @State private var showSettings = false
    @State private var showNewModel  = false
    @State private var newConvModel: LLMModel? = nil
    @State private var activeConversation: Conversation? = nil

    init(gateway: GatewayService, settings: AppSettings) {
        _vm = StateObject(wrappedValue: ConversationsViewModel(gateway: gateway, settings: settings))
    }

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView("Loading…")
                } else if vm.conversations.isEmpty {
                    emptyState
                } else {
                    conversationList
                }
            }
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    gatewayStatusDot
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gear")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showNewModel = true } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(settings)
            }
            .sheet(isPresented: $showNewModel) {
                ModelPickerView(selectedModel: $newConvModel)
            }
            .onChange(of: newConvModel) { model in
                guard let model else { return }
                Task {
                    if let conv = await vm.newConversation(model: model.id) {
                        activeConversation = conv
                    }
                    newConvModel = nil
                }
            }
            .navigationDestination(item: $activeConversation) { conv in
                ChatView(vm: ChatViewModel(conversation: conv, gateway: vm.gateway, settings: settings))
            }
        }
        .task { await vm.load() }
    }

    // MARK: List

    private var conversationList: some View {
        List {
            ForEach(vm.conversations) { conv in
                Button {
                    activeConversation = conv
                } label: {
                    conversationRow(conv)
                }
                .buttonStyle(.plain)
            }
            .onDelete(perform: vm.delete)
        }
        .listStyle(.insetGrouped)
        .refreshable { await vm.load() }
    }

    @ViewBuilder
    private func conversationRow(_ conv: Conversation) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray5))
                    .frame(width: 44, height: 44)
                Image(systemName: "bubble.left.and.bubble.right")
                    .foregroundStyle(.secondary)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(conv.title)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                Text(conv.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            Text(relativeDateString(conv.updatedDate))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 60))
                .foregroundStyle(.quaternary)
            Text("No chats yet")
                .font(.title3.weight(.semibold))
            Text("Tap the compose button to start a conversation with any LLM.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("New Chat") { showNewModel = true }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Gateway status dot

    private var gatewayStatusDot: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(dotColor)
                .frame(width: 8, height: 8)
            Text(dotLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var dotColor: Color {
        switch vm.gatewayOnline {
        case true:  return .green
        case false: return .red
        case nil:   return .yellow
        }
    }

    private var dotLabel: String {
        switch vm.gatewayOnline {
        case true:  return "Online"
        case false: return "Offline"
        case nil:   return "…"
        }
    }

    // MARK: Date helper

    private func relativeDateString(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
