import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isFromPom: Bool
}

/// A keyword-matched, entirely local responder — **not real AI**. Building an actual
/// conversational assistant needs an LLM API key and a provider decision this project
/// doesn't have; this exists so the chat screen from the reference isn't a dead end, and
/// says so on the very first message rather than pretending otherwise.
enum ChatbotResponder {
    static func reply(to message: String) -> String {
        let lowered = message.lowercased()

        if lowered.contains("frog") || lowered.contains("priorit") {
            return "Pick the one task you're most tempted to avoid — that's your Frog. Do it first."
        }
        if lowered.contains("distract") || lowered.contains("focus") {
            return "Start a Pomodoro from the Home tab and lean your phone up out of reach — that's the whole trick."
        }
        if lowered.contains("break") || lowered.contains("tired") {
            return "Take the full 5-minute cooldown. Water, a stretch, or 20 seconds looking at something far away all help."
        }
        if lowered.contains("flight") || lowered.contains("focusflight") {
            return "FocusFlight sessions are timed to a real short-haul route — pick two different cities and check in."
        }
        if lowered.contains("hello") || lowered.contains("hi") || lowered.contains("hey") {
            return "Hey! I'm just a simple canned-response helper for now, not a real AI — but I can point you at how Sprint's features work."
        }
        return "I'm a placeholder for now — simple keyword matching, not a real AI. Try asking about focus, breaks, priorities, or FocusFlight."
    }
}

struct ChatbotView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var messages: [ChatMessage] = [
        ChatMessage(text: "Hi, I'm Pom! Heads up — I'm a simple built-in helper, not a real AI assistant. Ask me about focus, breaks, or FocusFlight.", isFromPom: true)
    ]
    @State private var draft = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.charcoal.ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 14) {
                                ForEach(messages) { message in
                                    bubble(message)
                                }
                            }
                            .padding(20)
                            .id("bottom")
                        }
                        .onChange(of: messages.count) { _, _ in
                            withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                        }
                    }

                    inputBar
                }
            }
            .navigationTitle("Chatbot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .tint(Color.theme.cream)
                }
            }
        }
    }

    private func bubble(_ message: ChatMessage) -> some View {
        HStack {
            if message.isFromPom {
                PomMascotView(pose: .idle, size: 28)
            } else {
                Spacer(minLength: 40)
            }

            Text(message.text)
                .font(.theme.bodyMedium2())
                .foregroundStyle(message.isFromPom ? Color.theme.cream : Color.theme.espresso)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(message.isFromPom ? Color.white.opacity(0.1) : Color.theme.orange)
                )

            if !message.isFromPom {
                Spacer(minLength: 40)
            }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask something\u{2026}", text: $draft)
                .font(.theme.bodyLarge())
                .foregroundStyle(Color.theme.espresso)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Capsule().fill(Color.white))
                .submitLabel(.send)
                .onSubmit(send)

            Button(action: send) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.theme.cream)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.theme.orange))
            }
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(16)
    }

    private func send() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        messages.append(ChatMessage(text: trimmed, isFromPom: false))
        draft = ""

        let reply = ChatbotResponder.reply(to: trimmed)
        messages.append(ChatMessage(text: reply, isFromPom: true))
    }
}
