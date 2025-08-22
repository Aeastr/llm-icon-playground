//
//  SimpleLLMClient.swift
//  llm icon playground
//
//  Simplified LLM client for text generation and icon analysis only
//

import Foundation

// MARK: - Basic API Models  
struct LLMRequest: Codable {
    let contents: [Content]
    let generationConfig: GenerationConfig?
    
    struct Content: Codable {
        let parts: [Part]
        let role: String?
        
        struct Part: Codable {
            let text: String
        }
    }
    
    struct GenerationConfig: Codable {
        let temperature: Double?
        let topK: Int?
        let topP: Double?
        let maxOutputTokens: Int?
    }
}

struct LLMResponse: Codable {
    let candidates: [Candidate]
    
    struct Candidate: Codable {
        let content: Content
        let finishReason: String?
        
        struct Content: Codable {
            let parts: [Part]
            
            struct Part: Codable {
                let text: String
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
    
    /// Analyzes an icon file and generates suggestions for modifications
    func analyzeIcon(iconFileURL: URL, userRequest: String, chatLogger: ChatLogger? = nil, completion: @escaping (Result<String, Error>) -> Void) {
        let toolsManager = IconToolsManager(iconFileURL: iconFileURL, chatLogger: chatLogger)
        
        chatLogger?.addUserMessage(userRequest)
        chatLogger?.addSystemMessage("🔍 Starting icon analysis...")
        
        // Get basic icon structure
        let configResult = toolsManager.executeToolCall(ToolCall(name: "readIconConfig", parameters: [:]))
        
        switch configResult {
        case .success(let configInfo):
            let systemPrompt = """
            \(PromptBuilder.buildAnalysisPrompt())
            
            Current Icon Configuration:
            \(configInfo)
            
            Based on this information and the user's request, provide specific recommendations for modifications.
            """
            
            let prompt = """
            \(systemPrompt)
            
            User Request: \(userRequest)
            
            Please analyze this and provide recommendations.
            """
            
            generateText(prompt: prompt, chatLogger: chatLogger, completion: completion)
            
        case .error(let error):
            chatLogger?.addErrorMessage("Failed to read icon config: \(error)")
            completion(.failure(LLMError.apiError("Failed to analyze icon: \(error)")))
        }
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
                    parts: [LLMRequest.Content.Part(text: prompt)],
                    role: "user"
                )
            ],
            generationConfig: LLMRequest.GenerationConfig(
                temperature: 0.7,
                topK: 40,
                topP: 0.95,
                maxOutputTokens: 4096
            )
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
                          let part = candidate.content.parts.first else {
                        completion(.failure(LLMError.noContent))
                        return
                    }
                    
                    chatLogger?.addAssistantMessage(part.text)
                    completion(.success(part.text))
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