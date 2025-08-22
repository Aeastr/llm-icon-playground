//
//  KeychainManager.swift
//  llm icon playground
//
//  Secure storage for API keys using Keychain
//

import Foundation
import Security

class KeychainManager {
    
    private static let service = "llm-icon-playground"
    private static let apiKeyAccount = "gemini-api-key"
    
    // MARK: - API Key Storage
    
    static func saveAPIKey(_ key: String) -> Bool {
        let data = key.data(using: .utf8)!
        
        // Create query for keychain item
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyAccount,
            kSecValueData as String: data
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    static func getAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return key
    }
    
    static func deleteAPIKey() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyAccount
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    static func hasAPIKey() -> Bool {
        return getAPIKey() != nil
    }
}

// MARK: - Keychain Error Handling
extension KeychainManager {
    
    enum KeychainError: Error, LocalizedError {
        case saveFailed
        case loadFailed
        case deleteFailed
        case invalidData
        
        var errorDescription: String? {
            switch self {
            case .saveFailed:
                return "Failed to save API key to Keychain"
            case .loadFailed:
                return "Failed to load API key from Keychain"
            case .deleteFailed:
                return "Failed to delete API key from Keychain"
            case .invalidData:
                return "Invalid API key data"
            }
        }
    }
}