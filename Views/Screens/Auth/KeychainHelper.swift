//
//  KeychainHelper.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/31/25.
//


//
//  KeychainHelper.swift
//  BettorOdds
//
//  Created by Claude on 1/31/25.
//  Version: 1.0.0
//

import Foundation
import Security

class KeychainHelper {
    static let shared = KeychainHelper()
    private let service = "com.bettorodds.auth"
    
    private init() {}
    
    // MARK: - Save Credentials
    func saveCredentials(email: String, password: String) throws {
        // Create credentials dictionary
        let credentials = "\(email):\(password)".data(using: .utf8)!
        
        // Create query dictionary
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecValueData as String: credentials,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        // Delete existing credentials
        SecItemDelete(query as CFDictionary)
        
        // Save new credentials
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }
    
    // MARK: - Load Credentials
    func loadCredentials() throws -> (email: String, password: String)? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let credentialsData = result as? Data,
              let credentialsString = String(data: credentialsData, encoding: .utf8),
              let separatorIndex = credentialsString.firstIndex(of: ":")
        else {
            if status == errSecItemNotFound {
                return nil
            }
            throw KeychainError.loadFailed(status)
        }
        
        let email = String(credentialsString[..<separatorIndex])
        let password = String(credentialsString[credentialsString.index(after: separatorIndex)...])
        
        return (email, password)
    }
    
    // MARK: - Delete Credentials
    func deleteCredentials() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}

// MARK: - Keychain Errors
enum KeychainError: Error {
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)
    case deleteFailed(OSStatus)
    
    var localizedDescription: String {
        switch self {
        case .saveFailed(let status):
            return "Failed to save to Keychain: \(status)"
        case .loadFailed(let status):
            return "Failed to load from Keychain: \(status)"
        case .deleteFailed(let status):
            return "Failed to delete from Keychain: \(status)"
        }
    }
}