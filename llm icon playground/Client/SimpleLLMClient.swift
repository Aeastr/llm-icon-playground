//
//  SimpleLLMClient.swift
//  llm icon playground
//
//  Simplified LLM client for text generation and icon analysis only
//

import Foundation

// MARK: - Function Calling Models
struct LLMRequest: Codable {
    let contents: [Content]
    let generationConfig: GenerationConfig?
    let tools: [Tool]?
    
    struct Content: Codable {
        let parts: [Part]
        let role: String?
        
        struct Part: Codable {
            let text: String?
            let functionCall: FunctionCall?
            let functionResponse: FunctionResponse?
            
            enum CodingKeys: String, CodingKey {
                case text
                case functionCall = "functionCall"
                case functionResponse = "functionResponse"
            }
        }
    }
    
    struct GenerationConfig: Codable {
        let temperature: Double?
        let topK: Int?
        let topP: Double?
        let maxOutputTokens: Int?
    }
    
    struct Tool: Codable {
        let functionDeclarations: [FunctionDeclaration]
    }
    
    struct FunctionDeclaration: Codable {
        let name: String
        let description: String
        let parameters: FunctionParameters
    }
    
    struct FunctionParameters: Codable {
        let type: String
        let properties: [String: PropertyDefinition]
        let required: [String]?
    }
    
    struct PropertyDefinition: Codable {
        let type: String
        let description: String
    }
}

struct FunctionCall: Codable {
    let name: String
    let args: [String: String]
}

struct FunctionResponse: Codable {
    let name: String
    let response: [String: String]
}

struct LLMResponse: Codable {
    let candidates: [Candidate]
    
    struct Candidate: Codable {
        let content: Content
        let finishReason: String?
        
        struct Content: Codable {
            let parts: [Part]
            
            struct Part: Codable {
                let text: String?
                let functionCall: FunctionCall?
                
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
    
    init(apiKey: String, model: String = "gemini-2.5-flash") {
        self.apiKey = apiKey
        self.selectedModel = model
    }
    
    private var baseURL: String {
        return "https://generativelanguage.googleapis.com/v1beta/models/\(selectedModel):generateContent"
    }
    
    /// Starts a conversation about an icon file with function calling
    func analyzeIcon(iconFileURL: URL, userRequest: String, chatLogger: ChatLogger? = nil, completion: @escaping (Result<String, Error>) -> Void) {
        chatLogger?.addUserMessage(userRequest)
        chatLogger?.addSystemMessage("🔍 Starting interactive icon analysis...")
        
        let systemPrompt = """
        \(PromptBuilder.buildStartingPrompt())
        
        You have access to these tools to examine the icon:
        - readIconConfig: Get overview of the icon (background, group count, etc.)
        - readGroups: List all groups in the icon
        - readLayers(groupIndex): List layers in a specific group
        - getGroupDetails(groupIndex): Get detailed info about a group
        - getLayerDetails(groupIndex, layerIndex): Get detailed info about a layer
        
        Start by calling readIconConfig to understand the current structure, then explore as needed based on the user's request.
        """
        
        startFunctionCallingConversation(
            iconFileURL: iconFileURL,
            systemPrompt: systemPrompt,
            userMessage: userRequest,
            chatLogger: chatLogger,
            completion: completion
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
        let toolsManager = IconToolsManager(iconFileURL: iconFileURL, chatLogger: chatLogger)
        let tools = createToolDefinitions()
        
        var conversationHistory: [LLMRequest.Content] = [
            LLMRequest.Content(parts: [
                LLMRequest.Content.Part(text: systemPrompt, functionCall: nil, functionResponse: nil)
            ], role: "user"),
            LLMRequest.Content(parts: [
                LLMRequest.Content.Part(text: userMessage, functionCall: nil, functionResponse: nil)
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
                
                var updatedHistory = conversationHistory
                // Convert response content to request content format
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
                
                // Check if there are function calls to execute
                let functionCalls = candidate.content.parts.compactMap { $0.functionCall }
                
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
                    
                    // Add function responses and continue
                    updatedHistory.append(LLMRequest.Content(parts: functionResponses, role: "function"))
                    
                    self.continueConversation(
                        conversationHistory: updatedHistory,
                        tools: tools,
                        toolsManager: toolsManager,
                        chatLogger: chatLogger,
                        completion: completion
                    )
                } else {
                    // No more function calls, return final response
                    let finalText = candidate.content.parts.compactMap { $0.text }.joined(separator: " ")
                    chatLogger?.addAssistantMessage(finalText)
                    completion(.success(finalText))
                }
                
            case .failure(let error):
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
                    name: "readGroups",
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
                    name: "getGroupDetails",
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
                maxOutputTokens: 4096
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
                maxOutputTokens: 4096
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
        "gemini-2.5-flash",
        "gemini-2.0-flash-exp",
        "gemini-1.5-flash",
        "gemini-1.5-pro"
    ]
}