//
//  ChatView.swift
//  llm icon playground
//
//  Chat interface for viewing LLM interactions
//

import SwiftUI

struct ChatView: View {
    @Bindable var chatLogger: ChatLogger
    @Binding var hasActiveConversation: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Chat Log")
                    .font(.headline)
                Spacer()
                if hasActiveConversation {
                    Button("New Chat") {
                        hasActiveConversation = false
                        chatLogger.clear()
                    }
                    .font(.caption)
                    .buttonStyle(.borderless)
                }
                Button("Copy") {
                    chatLogger.copyConversationToClipboard()
                }
                .font(.caption)
                .buttonStyle(.borderless)
                Button("Clear") {
                    chatLogger.clear()
                }
                .font(.caption)
                .buttonStyle(.borderless)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            Divider()
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(chatLogger.messages) { message in
                            ChatMessageView(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: chatLogger.messages.count) { _ in
                    // Auto-scroll to the bottom when new messages arrive
                    if let lastMessage = chatLogger.messages.last {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .frame(minWidth: 300)
    }
}

struct ChatMessageView: View {
    let message: ChatMessage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(message.type.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(message.type.color)
                
                Spacer()
                
                Text(message.timestamp, format: .dateTime.hour().minute().second())
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(message.content)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(message.type.color.opacity(0.1))
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    let logger = ChatLogger()
    logger.addUserMessage("Generate a music app icon")
    logger.addSystemMessage("🔧 Attempting structured output generation...")
    logger.addAssistantMessage("Here's the generated icon structure...")
    logger.addErrorMessage("Failed to parse response")
    logger.addDebugMessage("Response length: 1234 characters")
    
    return ChatView(chatLogger: logger, hasActiveConversation: .constant(true))
        .frame(width: 400, height: 600)
}