//
//  GeminiClient.swift
//  llm icon playground
//
//  Gemini API client for icon generation
//

import Foundation

// MARK: - Helper Types
struct AnyCodable: Codable {
    let value: Any
    
    init<T: Codable>(_ value: T) {
        self.value = value
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let intValue = value as? Int {
            try container.encode(intValue)
        } else if let stringValue = value as? String {
            try container.encode(stringValue)
        } else if let doubleValue = value as? Double {
            try container.encode(doubleValue)
        } else if let boolValue = value as? Bool {
            try container.encode(boolValue)
        } else if let arrayValue = value as? [String] {
            try container.encode(arrayValue)
        } else if let dictValue = value as? [String: AnyCodable] {
            try container.encode(dictValue)
        } else if let schemaValue = value as? SchemaProperty {
            try container.encode(schemaValue)
        } else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Cannot encode value"))
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let arrayValue = try? container.decode([String].self) {
            value = arrayValue
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue
        } else if let schemaValue = try? container.decode(SchemaProperty.self) {
            value = schemaValue
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Cannot decode value"))
        }
    }
}

// MARK: - LLM API Models  
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
        let stopSequences: [String]?
        let responseMimeType: String?
        let responseSchema: ResponseSchema?
    }
}

// MARK: - JSON Schema Models
struct ResponseSchema: Codable {
    let type: String
    let properties: [String: AnyCodable]
    let required: [String]?
}

struct SchemaProperty: Codable {
    let type: String
    let properties: [String: AnyCodable]?
    let items: AnyCodable?
    let required: [String]?
    let enumValues: [String]?
    
    enum CodingKeys: String, CodingKey {
        case type, properties, items, required
        case enumValues = "enum"
    }
}

struct GeminiResponse: Codable {
    let candidates: [Candidate]
    
    struct Candidate: Codable {
        let content: Content
        let finishReason: String?
        let safetyRatings: [SafetyRating]?
        
        struct Content: Codable {
            let parts: [Part]
            
            struct Part: Codable {
                let text: String
            }
        }
        
        struct SafetyRating: Codable {
            let category: String
            let probability: String
        }
    }
}

// MARK: - Errors
enum GeminiError: Error, LocalizedError {
    case invalidAPIKey
    case invalidURL
    case networkError(String)
    case invalidResponse
    case apiError(String)
    case noContent
    case jsonParsingError(String)
    case structuredOutputFailed(String, fallbackAttempted: Bool)
    
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
        case .jsonParsingError(let message):
            return "JSON parsing error: \(message)"
        case .structuredOutputFailed(let reason, let fallbackAttempted):
            if fallbackAttempted {
                return "Structured output failed, fell back to unstructured mode: \(reason)"
            } else {
                return "Structured output failed: \(reason)"
            }
        }
    }
    
    var isStructuredOutputIssue: Bool {
        switch self {
        case .structuredOutputFailed:
            return true
        default:
            return false
        }
    }
    
    var fallbackDetails: String? {
        switch self {
        case .structuredOutputFailed(let reason, let fallbackAttempted):
            return """
            Structured Output Issue:
            • Reason: \(reason)
            • Fallback attempted: \(fallbackAttempted ? "Yes" : "No")
            • Model may not fully support JSON Schema constraints
            • Icon generation will use unstructured parsing instead
            """
        default:
            return nil
        }
    }
}

// MARK: - LLM Client (Gemini Implementation)
class GeminiClient {
    private let apiKey: String
    private let selectedModel: String
    
    init(apiKey: String, model: String = "gemini-2.5-flash") {
        self.apiKey = apiKey
        self.selectedModel = model
    }
    
    private var baseURL: String {
        return "https://generativelanguage.googleapis.com/v1beta/models/\(selectedModel):generateContent"
    }
    
    /// Generates an icon based on a text description using structured output
    func generateIcon(description: String, systemPrompt: String, completion: @escaping (Result<IconFile, Error>) -> Void) {
        generateStructuredIcon(description: description, systemPrompt: systemPrompt, completion: completion)
    }
    
    /// Generates an icon using structured output (JSON Schema) with fallback
    func generateStructuredIcon(description: String, systemPrompt: String, completion: @escaping (Result<IconFile, Error>) -> Void) {
        let prompt = buildPrompt(description: description, systemPrompt: systemPrompt)
        
        print("🔧 Attempting structured output generation...")
        generateStructuredText(prompt: prompt, schema: IconFile.responseSchema()) { result in
            switch result {
            case .success(let response):
                do {
                    let iconFile = try self.parseIconResponse(response)
                    print("✅ Structured output successful")
                    completion(.success(iconFile))
                } catch {
                    print("❌ Structured output parsing failed: \(error.localizedDescription)")
                    // Fallback to unstructured
                    self.fallbackToUnstructured(description: description, systemPrompt: systemPrompt, 
                                               originalError: error, completion: completion)
                }
            case .failure(let error):
                print("❌ Structured output API call failed: \(error.localizedDescription)")
                // Fallback to unstructured
                self.fallbackToUnstructured(description: description, systemPrompt: systemPrompt, 
                                           originalError: error, completion: completion)
            }
        }
    }
    
    /// Fallback to unstructured generation with detailed error reporting
    private func fallbackToUnstructured(description: String, systemPrompt: String, 
                                      originalError: Error, completion: @escaping (Result<IconFile, Error>) -> Void) {
        print("🔄 Falling back to unstructured generation...")
        
        generateUnstructuredIcon(description: description, systemPrompt: systemPrompt) { fallbackResult in
            switch fallbackResult {
            case .success(let iconFile):
                print("✅ Fallback to unstructured successful")
                // Create a detailed error for the UI but still return success
                let fallbackError = GeminiError.structuredOutputFailed(
                    originalError.localizedDescription, 
                    fallbackAttempted: true
                )
                
                // For now, we'll complete with success but could add a notification mechanism
                completion(.success(iconFile))
                
                // TODO: Add notification mechanism for UI alerts
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: Notification.Name("StructuredOutputFallback"), 
                        object: fallbackError
                    )
                }
                
            case .failure(let fallbackError):
                print("❌ Both structured and unstructured generation failed")
                let detailedError = GeminiError.structuredOutputFailed(
                    "Structured: \(originalError.localizedDescription), Unstructured: \(fallbackError.localizedDescription)",
                    fallbackAttempted: true
                )
                completion(.failure(detailedError))
            }
        }
    }
    
    /// Fallback to unstructured generation
    func generateUnstructuredIcon(description: String, systemPrompt: String, completion: @escaping (Result<IconFile, Error>) -> Void) {
        let prompt = buildPrompt(description: description, systemPrompt: systemPrompt)
        
        generateText(prompt: prompt) { result in
            switch result {
            case .success(let response):
                print("🔍 Raw LLM Response Length: \(response.count)")
                print("🔍 Raw LLM Response: '\(response)'")
                
                do {
                    let iconFile = try self.parseIconResponse(response)
                    completion(.success(iconFile))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Raw text generation (for debugging)
    func generateText(prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard !apiKey.isEmpty else {
            completion(.failure(GeminiError.invalidAPIKey))
            return
        }
        
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            completion(.failure(GeminiError.invalidURL))
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
                maxOutputTokens: 8192,
                stopSequences: nil,
                responseMimeType: nil,
                responseSchema: nil
            )
        )
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            completion(.failure(GeminiError.networkError("Failed to encode request: \(error.localizedDescription)")))
            return
        }
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    let sanitizedError = self.sanitizeErrorMessage(error.localizedDescription)
                    completion(.failure(GeminiError.networkError(sanitizedError)))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(GeminiError.invalidResponse))
                    return
                }
                
                do {
                    let llmResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
                    
                    guard let candidate = llmResponse.candidates.first,
                          let part = candidate.content.parts.first else {
                        completion(.failure(GeminiError.noContent))
                        return
                    }
                    
                    completion(.success(part.text))
                } catch {
                    // Try to parse as error response but NEVER log API keys
                    if let errorString = String(data: data, encoding: .utf8) {
                        let sanitizedError = self.sanitizeErrorMessage(errorString)
                        completion(.failure(GeminiError.apiError(sanitizedError)))
                    } else {
                        completion(.failure(GeminiError.invalidResponse))
                    }
                }
            }
        }.resume()
    }
    
    /// Structured text generation with JSON Schema
    func generateStructuredText(prompt: String, schema: ResponseSchema, completion: @escaping (Result<String, Error>) -> Void) {
        guard !apiKey.isEmpty else {
            completion(.failure(GeminiError.invalidAPIKey))
            return
        }
        
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            completion(.failure(GeminiError.invalidURL))
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
                temperature: 0.3, // Lower temperature for more consistent structured output
                topK: 40,
                topP: 0.95,
                maxOutputTokens: 8192,
                stopSequences: nil,
                responseMimeType: "application/json",
                responseSchema: schema
            )
        )
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            completion(.failure(GeminiError.networkError("Failed to encode request: \(error.localizedDescription)")))
            return
        }
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    let sanitizedError = self.sanitizeErrorMessage(error.localizedDescription)
                    completion(.failure(GeminiError.networkError(sanitizedError)))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(GeminiError.invalidResponse))
                    return
                }
                
                do {
                    let llmResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
                    
                    guard let candidate = llmResponse.candidates.first,
                          let part = candidate.content.parts.first else {
                        completion(.failure(GeminiError.noContent))
                        return
                    }
                    
                    completion(.success(part.text))
                } catch {
                    // Try to parse as error response but NEVER log API keys
                    if let errorString = String(data: data, encoding: .utf8) {
                        let sanitizedError = self.sanitizeErrorMessage(errorString)
                        completion(.failure(GeminiError.apiError(sanitizedError)))
                    } else {
                        completion(.failure(GeminiError.invalidResponse))
                    }
                }
            }
        }.resume()
    }
    
    /// Builds the complete prompt with system instructions and user description
    private func buildPrompt(description: String, systemPrompt: String) -> String {
        return """
        \(systemPrompt)
        
        User Request: \(description)
        
        Please generate a complete .icon JSON structure for this request. Respond with ONLY the JSON, no other text.
        """
    }
    
    /// Parses the LLM response into an IconFile
    private func parseIconResponse(_ response: String) throws -> IconFile {
        // Extract JSON from response (in case there's extra text)
        let jsonString = extractJSON(from: response)
        
        // Debug: Print what we're trying to parse (first 500 chars)
        let preview = String(jsonString.prefix(500))
        print("📝 LLM Response Preview: \(preview)")
        if jsonString.count > 500 {
            print("... (truncated, total length: \(jsonString.count) chars)")
        }
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw GeminiError.jsonParsingError("Could not convert response to data")
        }
        
        do {
            let iconFile = try JSONDecoder().decode(IconFile.self, from: jsonData)
            return iconFile
        } catch {
            // Enhanced error with more details
            print("❌ JSON Decode Error: \(error)")
            if let decodingError = error as? DecodingError {
                print("❌ Decoding Error Details: \(decodingError)")
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("❌ Missing key: \(key.stringValue) at path: \(context.codingPath)")
                case .typeMismatch(let type, let context):
                    print("❌ Type mismatch: expected \(type) at path: \(context.codingPath)")
                case .valueNotFound(let type, let context):
                    print("❌ Value not found: \(type) at path: \(context.codingPath)")
                case .dataCorrupted(let context):
                    print("❌ Data corrupted at path: \(context.codingPath)")
                @unknown default:
                    print("❌ Unknown decoding error")
                }
            }
            throw GeminiError.jsonParsingError("Failed to decode IconFile: \(error.localizedDescription)")
        }
    }
    
    /// Extracts JSON from potentially messy LLM response
    private func extractJSON(from response: String) -> String {
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Look for JSON between triple backticks with multiline support
        if let start = trimmed.range(of: "```json")?.upperBound,
           let end = trimmed.range(of: "```", options: [], range: start..<trimmed.endIndex)?.lowerBound {
            let jsonPart = String(trimmed[start..<end])
            return jsonPart.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Look for JSON between triple backticks without "json" label
        if let start = trimmed.range(of: "```")?.upperBound,
           let end = trimmed.range(of: "```", options: [], range: start..<trimmed.endIndex)?.lowerBound {
            let jsonPart = String(trimmed[start..<end])
            return jsonPart.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Look for JSON between single backticks
        if let start = trimmed.range(of: "`")?.upperBound,
           let end = trimmed.range(of: "`", options: [], range: start..<trimmed.endIndex)?.lowerBound {
            let jsonPart = String(trimmed[start..<end])
            return jsonPart.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Assume the entire response is JSON
        return trimmed
    }
    
    /// Removes API keys and sensitive data from error messages
    private func sanitizeErrorMessage(_ message: String) -> String {
        var sanitized = message
        
        // Remove API keys (pattern: AIza followed by alphanumeric)
        sanitized = sanitized.replacingOccurrences(
            of: "AIza[A-Za-z0-9_-]+", 
            with: "[API_KEY_REDACTED]", 
            options: .regularExpression
        )
        
        // Remove key= parameters from URLs
        sanitized = sanitized.replacingOccurrences(
            of: "key=[^&\\s]+", 
            with: "key=[REDACTED]", 
            options: .regularExpression
        )
        
        return sanitized
    }
}

// MARK: - API Key Management
extension GeminiClient {
    static func client(model: String = "gemini-2.5-flash") -> GeminiClient? {
        guard let apiKey = KeychainManager.getAPIKey(),
              !apiKey.isEmpty else {
            return nil
        }
        return GeminiClient(apiKey: apiKey, model: model)
    }
    
    static var shared: GeminiClient? {
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
            completion(.failure(GeminiError.invalidAPIKey))
            return
        }
        
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models?key=\(apiKey)") else {
            completion(.failure(GeminiError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(GeminiError.networkError(error.localizedDescription)))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(GeminiError.invalidResponse))
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let models = json["models"] as? [[String: Any]] {
                        
                        let modelNames = models.compactMap { model -> String? in
                            guard let name = model["name"] as? String else { return nil }
                            // Extract model name from "models/gemini-1.5-flash" format
                            return name.replacingOccurrences(of: "models/", with: "")
                        }.filter { name in
                            // Only include models that support generateContent
                            name.contains("gemini") && !name.contains("embedding")
                        }
                        
                        completion(.success(modelNames))
                    } else {
                        completion(.failure(GeminiError.invalidResponse))
                    }
                } catch {
                    completion(.failure(GeminiError.jsonParsingError(error.localizedDescription)))
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
