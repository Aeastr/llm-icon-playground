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
    @State private var isToolCallExpanded = false
    
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
            
            if case .toolCall(let name, let result) = message.type {
                // Special collapsible UI for tool calls
                VStack(alignment: .leading, spacing: 4) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isToolCallExpanded.toggle()
                        }
                    }) {
                        HStack {
                            Image(systemName: isToolCallExpanded ? "chevron.down" : "chevron.right")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("Called \(name)")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    
                    if isToolCallExpanded {
                        Text(result)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(.leading, 16)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(message.type.color.opacity(0.1))
                )
            } else {
                // Regular message content
                Group {
                    if message.type == .assistant {
                        // Render assistant messages as Markdown
                        Text(LocalizedStringKey(message.content))
                            .font(.system(.caption))
                            .textSelection(.enabled)
                    } else {
                        // Keep other message types as monospaced
                        Text(message.content)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(message.type.color.opacity(0.1))
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    let logger = ChatLogger()
    logger.addUserMessage("What is this icon?")
    logger.addToolCallMessage(name: "readIconConfig", result: "Background: No background fill\nGroups: 2\nTotal Layers: 8")
    logger.addToolCallMessage(name: "readGroups", result: "0: Group 1 (7 layers)\n1: Group 2 (1 layers)")
    logger.addAssistantMessage("This icon has **2 groups** with a total of *8 layers*. The first group contains 7 layers, likely forming the main icon elements, while the second group has 1 layer, probably the background.")
    logger.addErrorMessage("Failed to parse response")
    logger.addDebugMessage("Response length: 1234 characters")
    
    return ChatView(chatLogger: logger, hasActiveConversation: .constant(true))
        .frame(width: 400, height: 600)
}
