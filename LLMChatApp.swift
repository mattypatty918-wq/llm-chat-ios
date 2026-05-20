import SwiftUI

@main
struct LLMChatApp: App {
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        let gateway = GatewayService(settings: settings)
        TabView {
            ConversationsListView(gateway: gateway, settings: settings)
                .tabItem {
                    Label("Chats", systemImage: "bubble.left.and.bubble.right")
                }

            OllamaModelsView(settings: settings)
                .tabItem {
                    Label("Models", systemImage: "cpu")
                }

            SettingsView()
                .environmentObject(settings)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}
