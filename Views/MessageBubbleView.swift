import SwiftUI

struct MessageBubbleView: View {
    let message: Message

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser { Spacer(minLength: 60) }

            if !message.isUser {
                assistantAvatar
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                bubbleContent
                if message.isStreaming {
                    typingIndicator
                }
            }

            if message.isUser {
                userAvatar
            }

            if !message.isUser { Spacer(minLength: 60) }
        }
    }

    // MARK: Bubble

    @ViewBuilder
    private var bubbleContent: some View {
        if message.content.isEmpty && message.isStreaming {
            EmptyView()
        } else {
            Text(message.content)
                .textSelection(.enabled)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(message.isUser ? Color.blue : Color(.systemGray5))
                .foregroundStyle(message.isUser ? .white : .primary)
                .clipShape(BubbleShape(isUser: message.isUser))
        }
    }

    // MARK: Typing dots

    private var typingIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                BouncingDot(delay: Double(i) * 0.2)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // MARK: Avatars

    private var assistantAvatar: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
            Text("AI")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: 28, height: 28)
    }

    private var userAvatar: some View {
        ZStack {
            Circle().fill(Color.blue.opacity(0.15))
            Image(systemName: "person.fill")
                .font(.system(size: 12))
                .foregroundStyle(.blue)
        }
        .frame(width: 28, height: 28)
    }
}

// MARK: - Bubble Shape

struct BubbleShape: Shape {
    let isUser: Bool
    private let radius: CGFloat = 18
    private let tail: CGFloat   = 6

    func path(in rect: CGRect) -> Path {
        var path = Path()
        if isUser {
            path.addRoundedRect(in: CGRect(x: rect.minX, y: rect.minY, width: rect.width - tail, height: rect.height), cornerSize: CGSize(width: radius, height: radius))
        } else {
            path.addRoundedRect(in: CGRect(x: rect.minX + tail, y: rect.minY, width: rect.width - tail, height: rect.height), cornerSize: CGSize(width: radius, height: radius))
        }
        return path
    }
}

// MARK: - Bouncing dot animation

struct BouncingDot: View {
    let delay: Double
    @State private var up = false

    var body: some View {
        Circle()
            .fill(Color.gray.opacity(0.6))
            .frame(width: 6, height: 6)
            .offset(y: up ? -4 : 0)
            .animation(.easeInOut(duration: 0.5).repeatForever().delay(delay), value: up)
            .onAppear { up = true }
    }
}
