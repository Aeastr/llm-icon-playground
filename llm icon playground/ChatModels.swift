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
        case toolCall(name: String, result: String)
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
    
    static func toolCall(name: String, result: String) -> ChatMessage {
        ChatMessage(content: "Called \(name)", type: .toolCall(name: name, result: result), timestamp: Date())
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
    
    func addToolCallMessage(name: String, result: String) {
        addMessage(.toolCall(name: name, result: result))
    }
    
    func clear() {
        messages.removeAll()
    }
    
    func copyConversationToClipboard() {
        let conversationText = messages
            .filter { 
                switch $0.type {
                case .user, .assistant:
                    return true
                case .toolCall:
                    return true
                default:
                    return false
                }
            }
            .map { message in
                let timestamp = DateFormatter().string(from: message.timestamp)
                let content: String
                if case .toolCall(let name, let result) = message.type {
                    content = "Called \(name)\nResult: \(result)"
                } else {
                    content = message.content
                }
                return "\(message.type.displayName) \(timestamp)\n\n\(content)\n\n"
            }
            .joined(separator: "")
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(conversationText, forType: .string)
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
        case .toolCall:
            return .purple
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
        case .toolCall(let name, _):
            return "🔧 \(name)"
        }
    }
}

extension ChatMessage.MessageType: Equatable {
    static func == (lhs: ChatMessage.MessageType, rhs: ChatMessage.MessageType) -> Bool {
        switch (lhs, rhs) {
        case (.user, .user), (.assistant, .assistant), (.system, .system), (.error, .error), (.debug, .debug):
            return true
        case (.toolCall(let name1, let result1), .toolCall(let name2, let result2)):
            return name1 == name2 && result1 == result2
        default:
            return false
        }
    }
}
