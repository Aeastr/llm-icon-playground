//
//  SimpleLLMClient.swift
//  llm icon playground
//
//  Simplified LLM client for text generation and icon analysis only
//

import Foundation

// MARK: - Function Calling Models

/*
 HOW FUNCTION CALLING WORKS:
 
 1. We send LLMRequest with:
    - Conversation history (user messages, AI responses, function results)
    - Available tools/functions the AI can call
    - Generation settings (creativity, max length, etc.)
 
 2. AI responds with LLMResponse containing either:
    - Text response (normal chat)
    - Function calls (AI wants to get more info)
    - Both (AI calls functions then responds with text)
 
 3. If AI made function calls, we:
    - Execute those functions in our app
    - Send results back as FunctionResponse
    - Continue the conversation
 
 4. This repeats until AI gives final text response
 
 EXAMPLE FLOW:
 User: "What is this icon?"
 → AI calls: readIconConfig()
 → We return: "2 groups, 8 layers"
 → AI calls: readIconGroups()  
 → We return: "Group 1 (7 layers), Group 2 (1 layer)"
 → AI responds: "This icon has 2 groups with 8 total layers..."
*/

/// The main request structure sent to the Gemini API
/// This tells the API what we want it to do and what tools it can use
struct LLMRequest: Codable {
    /// The conversation history - array of messages between user, assistant, and function results
    let contents: [Content]
    /// Settings that control how the AI generates responses (creativity, length, etc.)
    let generationConfig: GenerationConfig?
    /// Optional list of tools/functions the AI can call to get information
    let tools: [Tool]?
    
    /// Represents a single message in the conversation
    /// Could be from user, assistant (model), or function call results
    struct Content: Codable {
        /// The actual content pieces - can be text, function calls, or function responses
        let parts: [Part]
        /// Who sent this message: "user", "model", or "function"
        let role: String?
        
        /// A single piece of content within a message
        /// Only ONE of these will be set at a time
        struct Part: Codable {
            /// Regular text content (what humans type or AI responds with)
            let text: String?
            /// When AI wants to call a tool/function (AI → Tool)
            let functionCall: FunctionCall?
            /// The result coming back from a tool/function (Tool → AI)
            let functionResponse: FunctionResponse?
            
            /// Maps the API's camelCase to our Swift naming
            enum CodingKeys: String, CodingKey {
                case text
                case functionCall = "functionCall"
                case functionResponse = "functionResponse"
            }
        }
    }
    
    /// Controls how creative/focused the AI's responses are
    struct GenerationConfig: Codable {
        /// 0.0 = very focused, 1.0 = very creative/random
        let temperature: Double?
        /// How many top candidates to consider (higher = more diverse)
        let topK: Int?
        /// Cumulative probability cutoff (0.0-1.0, higher = more diverse)
        let topP: Double?
        /// Maximum number of tokens (words/pieces) in the response
        let maxOutputTokens: Int?
    }
    
    /// Describes what tools/functions are available to the AI
    struct Tool: Codable {
        /// List of all the functions the AI can call
        let functionDeclarations: [FunctionDeclaration]
    }
    
    /// Describes a single function the AI can call
    struct FunctionDeclaration: Codable {
        /// Function name (like "readIconConfig")
        let name: String
        /// Human-readable description of what this function does
        let description: String
        /// Describes what parameters this function accepts
        let parameters: FunctionParameters
    }
    
    /// Describes the parameters a function accepts (JSON Schema format)
    struct FunctionParameters: Codable {
        /// Always "object" for function parameters
        let type: String
        /// Map of parameter name → parameter definition
        let properties: [String: PropertyDefinition]
        /// Array of required parameter names
        let required: [String]?
    }
    
    /// Describes a single parameter for a function
    struct PropertyDefinition: Codable {
        /// Data type: "string", "integer", "boolean", etc.
        let type: String
        /// Human-readable description of this parameter
        let description: String
    }
}

/// When the AI wants to call one of our functions
/// This gets sent from AI → our app
struct FunctionCall: Codable {
    /// Name of the function to call (e.g., "readIconConfig")
    let name: String
    /// Arguments to pass to the function (always strings from Gemini)
    let args: [String: String]
}

/// The result of calling a function
/// This gets sent from our app → AI
struct FunctionResponse: Codable {
    /// Name of the function that was called
    let name: String
    /// The result data (we put actual result in "result" key)
    let response: [String: String]
}

/// The response we get back from the Gemini API
/// Contains the AI's response and any function calls it wants to make
struct LLMResponse: Codable {
    /// Array of possible responses (usually just one)
    let candidates: [Candidate]
    
    /// A single response candidate from the AI
    struct Candidate: Codable {
        /// The actual content of the response
        let content: Content
        /// Why the AI stopped generating ("STOP", "MAX_TOKENS", etc.)
        let finishReason: String?
        
        /// The content within a candidate response
        struct Content: Codable {
            /// Array of content parts (text and/or function calls)
            let parts: [Part]
            
            /// A single piece of content in the response
            struct Part: Codable {
                /// Text response from the AI (what the user sees)
                let text: String?
                /// Function call the AI wants to make (to get more info)
                let functionCall: FunctionCall?
                
                /// Maps API's camelCase to Swift naming
                enum CodingKeys: String, CodingKey {
                    case text
                    case functionCall = "functionCall"
                }
            }
        }
    }
}

// MARK: - Errors
enum LLMError: Error, LocalizedError {
    case invalidAPIKey
    case invalidURL
    case networkError(String)
    case invalidResponse
    case apiError(String)
    case noContent
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid API key"
        case .invalidURL:
            return "Invalid API URL"
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidResponse:
            return "Invalid response from API"
        case .apiError(let message):
            return "API error: \(message)"
        case .noContent:
            return "No content in response"
        }
    }
}

// MARK: - Simplified LLM Client
class SimpleLLMClient {
    private let apiKey: String
    private let selectedModel: String
    
    // Ongoing conversation state
    private var currentConversationHistory: [LLMRequest.Content] = []
    private var currentTools: [LLMRequest.Tool] = []
    private var currentToolsManager: IconToolsManager?
    private var currentChatLogger: ChatLogger?
    
    init(apiKey: String, model: String = "gemini-2.5-flash") {
        self.apiKey = apiKey
        self.selectedModel = model
    }
    
    private var baseURL: String {
        return "https://generativelanguage.googleapis.com/v1beta/models/\(selectedModel):generateContent"
    }
    
    /// Starts a new chat conversation with access to icon analysis tools
    func startChatWithIcon(iconFileURL: URL, userMessage: String, chatLogger: ChatLogger? = nil, previewManager: IconPreviewManager? = nil, completion: @escaping (Result<String, Error>) -> Void) {
        // Initialize conversation state
        currentChatLogger = chatLogger
        currentToolsManager = IconToolsManager(iconFileURL: iconFileURL, chatLogger: chatLogger, previewManager: previewManager)
        currentTools = createToolDefinitions()
        
        // ALWAYS add user message to chat log first, before any API calls
        chatLogger?.addUserMessage(userMessage)
        print("💬 Chat started")
        
        let systemPrompt = PromptBuilder.buildStartingPrompt()
        
        // Initialize conversation history immediately
        let combinedPrompt = """
        \(systemPrompt)
        
        User Request: \(userMessage)
        """
        
        currentConversationHistory = [
            LLMRequest.Content(parts: [
                LLMRequest.Content.Part(text: combinedPrompt, functionCall: nil, functionResponse: nil)
            ], role: "user")
        ]
        
        continueCurrentConversation(completion: completion)
    }
    
    /// Continues the current conversation with a new user message
    func continueChat(userMessage: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard currentToolsManager != nil else {
            completion(.failure(LLMError.apiError("No active conversation. Start a new chat first.")))
            return
        }
        
        // ALWAYS add user message to chat log and history first, before any API calls
        currentChatLogger?.addUserMessage(userMessage)
        currentConversationHistory.append(
            LLMRequest.Content(parts: [
                LLMRequest.Content.Part(text: userMessage, functionCall: nil, functionResponse: nil)
            ], role: "user")
        )
        
        continueCurrentConversation(completion: completion)
    }
    
    /// Continues the current conversation
    private func continueCurrentConversation(completion: @escaping (Result<String, Error>) -> Void) {
        guard let toolsManager = currentToolsManager else {
            completion(.failure(LLMError.apiError("No active conversation")))
            return
        }
        
        print("🔄 Continuing conversation with \(currentConversationHistory.count) messages in history")
        
        continueConversation(
            conversationHistory: currentConversationHistory,
            tools: currentTools,
            toolsManager: toolsManager,
            chatLogger: currentChatLogger,
            completion: { result in
                switch result {
                case .success(let text):
                    print("✅ Conversation completed successfully. Final text: '\(text.prefix(100))'")
                    completion(result)
                case .failure(let error):
                    print("❌ Conversation failed: \(error.localizedDescription)")
                    completion(result)
                }
            }
        )
    }
    
    /// Handles function calling conversation with the LLM
    private func startFunctionCallingConversation(
        iconFileURL: URL,
        systemPrompt: String,
        userMessage: String,
        chatLogger: ChatLogger? = nil,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let toolsManager = IconToolsManager(iconFileURL: iconFileURL, chatLogger: chatLogger, previewManager: nil)
        let tools = createToolDefinitions()
        
        // Combine system prompt and user message into one message for Gemini
        let combinedPrompt = """
        \(systemPrompt)
        
        User Request: \(userMessage)
        """
        
        var conversationHistory: [LLMRequest.Content] = [
            LLMRequest.Content(parts: [
                LLMRequest.Content.Part(text: combinedPrompt, functionCall: nil, functionResponse: nil)
            ], role: "user")
        ]
        
        continueConversation(
            conversationHistory: conversationHistory,
            tools: tools,
            toolsManager: toolsManager,
            chatLogger: chatLogger,
            completion: completion
        )
    }
    
    /// Continues the conversation, handling function calls
    private func continueConversation(
        conversationHistory: [LLMRequest.Content],
        tools: [LLMRequest.Tool],
        toolsManager: IconToolsManager,
        chatLogger: ChatLogger?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        makeAPICall(contents: conversationHistory, tools: tools) { result in
            switch result {
            case .success(let response):
                guard let candidate = response.candidates.first else {
                    completion(.failure(LLMError.noContent))
                    return
                }
                
                // IMMEDIATELY update conversation history with the response
                var updatedHistory = conversationHistory
                let responseContent = LLMRequest.Content(
                    parts: candidate.content.parts.map { responsePart in
                        LLMRequest.Content.Part(
                            text: responsePart.text,
                            functionCall: responsePart.functionCall,
                            functionResponse: nil
                        )
                    },
                    role: "model"
                )
                updatedHistory.append(responseContent)
                self.currentConversationHistory = updatedHistory
                
                // Check if there are function calls to execute
                let functionCalls = candidate.content.parts.compactMap { $0.functionCall }
                let textParts = candidate.content.parts.compactMap { $0.text }
                
                print("📋 LLM response: \(functionCalls.count) function calls, \(textParts.count) text parts")
                
                if !functionCalls.isEmpty {
                    // Execute function calls and continue conversation
                    var functionResponses: [LLMRequest.Content.Part] = []
                    
                    for functionCall in functionCalls {
                        let toolCall = ToolCall(name: functionCall.name, parameters: functionCall.args)
                        let result = toolsManager.executeToolCall(toolCall)
                        
                        switch result {
                        case .success(let resultText):
                            functionResponses.append(LLMRequest.Content.Part(
                                text: nil,
                                functionCall: nil,
                                functionResponse: FunctionResponse(
                                    name: functionCall.name,
                                    response: ["result": resultText]
                                )
                            ))
                        case .error(let error):
                            functionResponses.append(LLMRequest.Content.Part(
                                text: nil,
                                functionCall: nil,
                                functionResponse: FunctionResponse(
                                    name: functionCall.name,
                                    response: ["error": error]
                                )
                            ))
                        }
                    }
                    
                    // IMMEDIATELY add function responses to history
                    updatedHistory.append(LLMRequest.Content(parts: functionResponses, role: "function"))
                    self.currentConversationHistory = updatedHistory
                    
                    self.continueConversation(
                        conversationHistory: updatedHistory,
                        tools: tools,
                        toolsManager: toolsManager,
                        chatLogger: chatLogger,
                        completion: completion
                    )
                } else {
                    // No more function calls, add final response to chat log
                    let finalText = candidate.content.parts.compactMap { $0.text }.joined(separator: " ")
                    print("🏁 LLM finished with final text (\(finalText.count) chars): '\(finalText.prefix(100))...'")
                    
                    if !finalText.isEmpty {
                        chatLogger?.addAssistantMessage(finalText)
                        completion(.success(finalText))
                    } else {
                        print("⚠️ LLM returned empty final text - treating as conversation completion")
                        completion(.success(""))
                    }
                }
                
            case .failure(let error):
                // Even on failure, conversation history is preserved
                completion(.failure(error))
            }
        }
    }
    
    /// Creates tool definitions for the API
    private func createToolDefinitions() -> [LLMRequest.Tool] {
        return [
            LLMRequest.Tool(functionDeclarations: [
                LLMRequest.FunctionDeclaration(
                    name: "readIconConfig",
                    description: "Get overview of the icon including background fill, group count, and specializations",
                    parameters: LLMRequest.FunctionParameters(
                        type: "object",
                        properties: [:],
                        required: nil
                    )
                ),
                LLMRequest.FunctionDeclaration(
                    name: "readIconGroups",
                    description: "List all groups in the icon with their indices and layer counts",
                    parameters: LLMRequest.FunctionParameters(
                        type: "object",
                        properties: [:],
                        required: nil
                    )
                ),
                LLMRequest.FunctionDeclaration(
                    name: "readLayers",
                    description: "List all layers in a specific group",
                    parameters: LLMRequest.FunctionParameters(
                        type: "object",
                        properties: [
                            "groupIndex": LLMRequest.PropertyDefinition(
                                type: "string",
                                description: "The index of the group to read layers from"
                            )
                        ],
                        required: ["groupIndex"]
                    )
                ),
                LLMRequest.FunctionDeclaration(
                    name: "getIconGroupDetails",
                    description: "Get detailed information about a specific group",
                    parameters: LLMRequest.FunctionParameters(
                        type: "object",
                        properties: [
                            "groupIndex": LLMRequest.PropertyDefinition(
                                type: "string",
                                description: "The index of the group to examine"
                            )
                        ],
                        required: ["groupIndex"]
                    )
                ),
                LLMRequest.FunctionDeclaration(
                    name: "getLayerDetails",
                    description: "Get detailed information about a specific layer",
                    parameters: LLMRequest.FunctionParameters(
                        type: "object",
                        properties: [
                            "groupIndex": LLMRequest.PropertyDefinition(
                                type: "string",
                                description: "The index of the group containing the layer"
                            ),
                            "layerIndex": LLMRequest.PropertyDefinition(
                                type: "string",
                                description: "The index of the layer to examine"
                            )
                        ],
                        required: ["groupIndex", "layerIndex"]
                    )
                ),
                // MARK: - Icon Editing Tools
                LLMRequest.FunctionDeclaration(
                    name: "updateIconBackground",
                    description: "Change the main background fill of the icon",
                    parameters: LLMRequest.FunctionParameters(
                        type: "object",
                        properties: [
                            "fillType": LLMRequest.PropertyDefinition(
                                type: "string",
                                description: "Type of fill: 'color' or 'gradient'"
                            ),
                            "color": LLMRequest.PropertyDefinition(
                                type: "string",
                                description: "Hex color code (required for color fills)"
                            )
                        ],
                        required: ["fillType"]
                    )
                ),
                LLMRequest.FunctionDeclaration(
                    name: "addIconFillSpecialization",
                    description: "Add a background appearance variant for light/dark mode",
                    parameters: LLMRequest.FunctionParameters(
                        type: "object",
                        properties: [
                            "appearance": LLMRequest.PropertyDefinition(
                                type: "string",
                                description: "Appearance mode: 'light' or 'dark'"
                            ),
                            "fillType": LLMRequest.PropertyDefinition(
                                type: "string",
                                description: "Type of fill: 'color' or 'gradient'"
                            ),
                            "color": LLMRequest.PropertyDefinition(
                                type: "string",
                                description: "Hex color code (required for color fills)"
                            )
                        ],
                        required: ["appearance", "fillType"]
                    )
                ),
                LLMRequest.FunctionDeclaration(
                    name: "removeIconFillSpecialization",
                    description: "Remove a background appearance variant",
                    parameters: LLMRequest.FunctionParameters(
                        type: "object",
                        properties: [
                            "appearance": LLMRequest.PropertyDefinition(
                                type: "string",
                                description: "Appearance mode to remove: 'light' or 'dark'"
                            )
                        ],
                        required: ["appearance"]
                    )
                )
            ])
        ]
    }
    
    /// Makes an API call with function calling support
    private func makeAPICall(
        contents: [LLMRequest.Content],
        tools: [LLMRequest.Tool],
        completion: @escaping (Result<LLMResponse, Error>) -> Void
    ) {
        makeAPICallWithRetry(contents: contents, tools: tools, retryCount: 0, completion: completion)
    }
    
    /// Makes an API call with retry logic
    private func makeAPICallWithRetry(
        contents: [LLMRequest.Content],
        tools: [LLMRequest.Tool],
        retryCount: Int,
        completion: @escaping (Result<LLMResponse, Error>) -> Void
    ) {
        guard !apiKey.isEmpty else {
            completion(.failure(LLMError.invalidAPIKey))
            return
        }
        
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            completion(.failure(LLMError.invalidURL))
            return
        }
        
        let request = LLMRequest(
            contents: contents,
            generationConfig: LLMRequest.GenerationConfig(
                temperature: 0.7,
                topK: 40,
                topP: 0.95,
                maxOutputTokens: 8192
            ),
            tools: tools
        )
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            completion(.failure(LLMError.networkError("Failed to encode request: \(error.localizedDescription)")))
            return
        }
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    // Retry on network errors
                    if retryCount < 2 {
                        print("🔄 Network error, retrying (\(retryCount + 1)/3): \(error.localizedDescription)")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.makeAPICallWithRetry(contents: contents, tools: tools, retryCount: retryCount + 1, completion: completion)
                        }
                        return
                    }
                    completion(.failure(LLMError.networkError(self.sanitizeErrorMessage(error.localizedDescription))))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(LLMError.invalidResponse))
                    return
                }
                
                do {
                    let llmResponse = try JSONDecoder().decode(LLMResponse.self, from: data)
                    completion(.success(llmResponse))
                } catch {
                    if let errorString = String(data: data, encoding: .utf8) {
                        let sanitizedError = self.sanitizeErrorMessage(errorString)
                        
                        // Check if it's a 500 internal error - retry those
                        if sanitizedError.contains("\"code\": 500") || sanitizedError.contains("INTERNAL") {
                            if retryCount < 2 {
                                print("🔄 API 500 error, retrying (\(retryCount + 1)/3)")
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    self.makeAPICallWithRetry(contents: contents, tools: tools, retryCount: retryCount + 1, completion: completion)
                                }
                                return
                            }
                        }
                        
                        completion(.failure(LLMError.apiError(sanitizedError)))
                    } else {
                        completion(.failure(LLMError.invalidResponse))
                    }
                }
            }
        }.resume()
    }
    
    /// Basic text generation
    func generateText(prompt: String, chatLogger: ChatLogger? = nil, completion: @escaping (Result<String, Error>) -> Void) {
        guard !apiKey.isEmpty else {
            completion(.failure(LLMError.invalidAPIKey))
            return
        }
        
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            completion(.failure(LLMError.invalidURL))
            return
        }
        
        let request = LLMRequest(
            contents: [
                LLMRequest.Content(
                    parts: [LLMRequest.Content.Part(text: prompt, functionCall: nil, functionResponse: nil)],
                    role: "user"
                )
            ],
            generationConfig: LLMRequest.GenerationConfig(
                temperature: 0.7,
                topK: 40,
                topP: 0.95,
                maxOutputTokens: 8192
            ),
            tools: nil
        )
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            completion(.failure(LLMError.networkError("Failed to encode request: \(error.localizedDescription)")))
            return
        }
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    let sanitizedError = self.sanitizeErrorMessage(error.localizedDescription)
                    completion(.failure(LLMError.networkError(sanitizedError)))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(LLMError.invalidResponse))
                    return
                }
                
                do {
                    let llmResponse = try JSONDecoder().decode(LLMResponse.self, from: data)
                    
                    guard let candidate = llmResponse.candidates.first,
                          let part = candidate.content.parts.first,
                          let text = part.text else {
                        completion(.failure(LLMError.noContent))
                        return
                    }
                    
                    chatLogger?.addAssistantMessage(text)
                    completion(.success(text))
                } catch {
                    if let errorString = String(data: data, encoding: .utf8) {
                        let sanitizedError = self.sanitizeErrorMessage(errorString)
                        completion(.failure(LLMError.apiError(sanitizedError)))
                    } else {
                        completion(.failure(LLMError.invalidResponse))
                    }
                }
            }
        }.resume()
    }
    
    /// Removes API keys and sensitive data from error messages
    private func sanitizeErrorMessage(_ message: String) -> String {
        var sanitized = message
        
        sanitized = sanitized.replacingOccurrences(
            of: "AIza[A-Za-z0-9_-]+", 
            with: "[API_KEY_REDACTED]", 
            options: .regularExpression
        )
        
        sanitized = sanitized.replacingOccurrences(
            of: "key=[^&\\s]+", 
            with: "key=[REDACTED]", 
            options: .regularExpression
        )
        
        return sanitized
    }
}

// MARK: - API Key Management
extension SimpleLLMClient {
    static func client(model: String = "gemini-2.5-flash") -> SimpleLLMClient? {
        guard let apiKey = KeychainManager.getAPIKey(),
              !apiKey.isEmpty else {
            return nil
        }
        return SimpleLLMClient(apiKey: apiKey, model: model)
    }
    
    static var shared: SimpleLLMClient? {
        return client()
    }
    
    static func setAPIKey(_ key: String) -> Bool {
        return KeychainManager.saveAPIKey(key)
    }
    
    static func hasValidAPIKey() -> Bool {
        return KeychainManager.hasAPIKey()
    }
    
    static func removeAPIKey() -> Bool {
        return KeychainManager.deleteAPIKey()
    }
    
    /// Fetches available models from Gemini API
    static func getAvailableModels(completion: @escaping (Result<[String], Error>) -> Void) {
        guard let apiKey = KeychainManager.getAPIKey(), !apiKey.isEmpty else {
            completion(.failure(LLMError.invalidAPIKey))
            return
        }
        
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models?key=\(apiKey)") else {
            completion(.failure(LLMError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(LLMError.networkError(error.localizedDescription)))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(LLMError.invalidResponse))
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let models = json["models"] as? [[String: Any]] {
                        
                        let modelNames = models.compactMap { model -> String? in
                            guard let name = model["name"] as? String else { return nil }
                            return name.replacingOccurrences(of: "models/", with: "")
                        }.filter { name in
                            name.contains("gemini") && !name.contains("embedding")
                        }
                        
                        completion(.success(modelNames))
                    } else {
                        completion(.failure(LLMError.invalidResponse))
                    }
                } catch {
                    completion(.failure(LLMError.networkError(error.localizedDescription)))
                }
            }
        }.resume()
    }
    
    /// Commonly available models (fallback if API call fails)
    static let commonModels = [
        "gemini-2.5-flash"
    ]
}
