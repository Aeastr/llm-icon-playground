//
//  ChatModels.swift
//  llm icon playground
//
//  Chat message models for LLM interaction logging
//

import Foundation
import SwiftUI

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let type: MessageType
    let timestamp: Date
    
    enum MessageType {
        case user
        case assistant
        case system
        case error
        case debug
    }
    
    static func user(_ content: String) -> ChatMessage {
        ChatMessage(content: content, type: .user, timestamp: Date())
    }
    
    static func assistant(_ content: String) -> ChatMessage {
        ChatMessage(content: content, type: .assistant, timestamp: Date())
    }
    
    static func system(_ content: String) -> ChatMessage {
        ChatMessage(content: content, type: .system, timestamp: Date())
    }
    
    static func error(_ content: String) -> ChatMessage {
        ChatMessage(content: content, type: .error, timestamp: Date())
    }
    
    static func debug(_ content: String) -> ChatMessage {
        ChatMessage(content: content, type: .debug, timestamp: Date())
    }
}

@Observable
class ChatLogger {
    var messages: [ChatMessage] = []
    
    func addMessage(_ message: ChatMessage) {
        messages.append(message)
    }
    
    func addUserMessage(_ content: String) {
        addMessage(.user(content))
    }
    
    func addAssistantMessage(_ content: String) {
        addMessage(.assistant(content))
    }
    
    func addSystemMessage(_ content: String) {
        addMessage(.system(content))
    }
    
    func addErrorMessage(_ content: String) {
        addMessage(.error(content))
    }
    
    func addDebugMessage(_ content: String) {
        addMessage(.debug(content))
    }
    
    func clear() {
        messages.removeAll()
    }
}

extension ChatMessage.MessageType {
    var color: Color {
        switch self {
        case .user:
            return .blue
        case .assistant:
            return .green
        case .system:
            return .orange
        case .error:
            return .red
        case .debug:
            return .gray
        }
    }
    
    var displayName: String {
        switch self {
        case .user:
            return "You"
        case .assistant:
            return "Gemini"
        case .system:
            return "System"
        case .error:
            return "Error"
        case .debug:
            return "Debug"
        }
    }
}
