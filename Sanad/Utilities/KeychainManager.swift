//
//  KeychainManager.swift
//  Sanad
//
//  Manages secure storage in iOS Keychain
//  Provides secure storage for sensitive data like encryption keys
//

import Foundation
import Security

/// مدير سلسلة المفاتيح - Keychain Manager
class KeychainManager {
    
    // MARK: - Singleton
    
    static let shared = KeychainManager()
    
    // MARK: - Properties
    
    private let service = "com.sanad.app"
    private let accessGroup: String? = nil // Can be set for app groups
    
    // Keychain keys
    enum KeychainKey: String {
        case encryptionKey = "encryption_key"
        case userPin = "user_pin"
        case biometricEnabled = "biometric_enabled"
        case lastBackupDate = "last_backup_date"
    }
    
    // MARK: - Initialization
    
    private init() {
        print("🔐 KeychainManager initialized")
    }
    
    // MARK: - Encryption Key Management
    
    /// Save encryption key to Keychain
    func saveEncryptionKey(_ key: Data) -> Bool {
        return save(key, forKey: KeychainKey.encryptionKey.rawValue)
    }
    
    /// Get encryption key from Keychain
    func getEncryptionKey() -> Data? {
        return get(forKey: KeychainKey.encryptionKey.rawValue)
    }
    
    /// Delete encryption key from Keychain
    func deleteEncryptionKey() -> Bool {
        return delete(forKey: KeychainKey.encryptionKey.rawValue)
    }
    
    // MARK: - Generic Keychain Operations
    
    /// Save data to Keychain
    func save(_ data: Data, forKey key: String) -> Bool {
        // Create query
        var query = createQuery(forKey: key)
        query[kSecValueData as String] = data
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            print("✅ Keychain save success: \(key)")
            return true
        } else {
            print("❌ Keychain save failed: \(key) - Status: \(status)")
            return false
        }
    }
    
    /// Get data from Keychain
    func get(forKey key: String) -> Data? {
        var query = createQuery(forKey: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            print("✅ Keychain get success: \(key)")
            return result as? Data
        } else if status == errSecItemNotFound {
            print("⚠️ Keychain item not found: \(key)")
            return nil
        } else {
            print("❌ Keychain get failed: \(key) - Status: \(status)")
            return nil
        }
    }
    
    /// Delete data from Keychain
    func delete(forKey key: String) -> Bool {
        let query = createQuery(forKey: key)
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess || status == errSecItemNotFound {
            print("✅ Keychain delete success: \(key)")
            return true
        } else {
            print("❌ Keychain delete failed: \(key) - Status: \(status)")
            return false
        }
    }
    
    /// Check if key exists in Keychain
    func exists(forKey key: String) -> Bool {
        return get(forKey: key) != nil
    }
    
    // MARK: - String Operations
    
    /// Save string to Keychain
    func saveString(_ string: String, forKey key: String) -> Bool {
        guard let data = string.data(using: .utf8) else {
            print("❌ Failed to convert string to data")
            return false
        }
        return save(data, forKey: key)
    }
    
    /// Get string from Keychain
    func getString(forKey key: String) -> String? {
        guard let data = get(forKey: key) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    
    // MARK: - Codable Operations
    
    /// Save codable object to Keychain
    func saveCodable<T: Codable>(_ object: T, forKey key: String) -> Bool {
        guard let data = try? JSONEncoder().encode(object) else {
            print("❌ Failed to encode object")
            return false
        }
        return save(data, forKey: key)
    }
    
    /// Get codable object from Keychain
    func getCodable<T: Codable>(forKey key: String, as type: T.Type) -> T? {
        guard let data = get(forKey: key) else {
            return nil
        }
        return try? JSONDecoder().decode(T.self, from: data)
    }
    
    // MARK: - Batch Operations
    
    /// Delete all items for this app
    func deleteAll() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess || status == errSecItemNotFound {
            print("✅ Keychain deleteAll success")
            return true
        } else {
            print("❌ Keychain deleteAll failed - Status: \(status)")
            return false
        }
    }
    
    /// Get all keys stored in Keychain
    func getAllKeys() -> [String] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let items = result as? [[String: Any]] else {
            return []
        }
        
        return items.compactMap { item in
            item[kSecAttrAccount as String] as? String
        }
    }
    
    // MARK: - Helper Methods
    
    /// Create base query for Keychain operations
    private func createQuery(forKey key: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        return query
    }
    
    // MARK: - Biometric Authentication
    
    /// Save data with biometric authentication requirement
    func saveWithBiometric(_ data: Data, forKey key: String) -> Bool {
        var query = createQuery(forKey: key)
        query[kSecValueData as String] = data
        
        // Require biometric authentication
        let access = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .biometryCurrentSet,
            nil
        )
        query[kSecAttrAccessControl as String] = access
        
        // Delete existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            print("✅ Keychain save with biometric success: \(key)")
            return true
        } else {
            print("❌ Keychain save with biometric failed: \(key) - Status: \(status)")
            return false
        }
    }
    
    // MARK: - Migration & Backup
    
    /// Export all Keychain data (for backup)
    func exportData() -> [String: Data]? {
        let keys = getAllKeys()
        var exportData: [String: Data] = [:]
        
        for key in keys {
            if let data = get(forKey: key) {
                exportData[key] = data
            }
        }
        
        return exportData.isEmpty ? nil : exportData
    }
    
    /// Import Keychain data (from backup)
    func importData(_ data: [String: Data]) -> Bool {
        var success = true
        
        for (key, value) in data {
            if !save(value, forKey: key) {
                success = false
                print("❌ Failed to import key: \(key)")
            }
        }
        
        return success
    }
    
    // MARK: - Debugging
    
    /// Print all stored keys (for debugging)
    func printAllKeys() {
        let keys = getAllKeys()
        print("🔐 Keychain stored keys (\(keys.count)):")
        for key in keys {
            print("  - \(key)")
        }
    }
    
    /// Get Keychain statistics
    func getStatistics() -> KeychainStatistics {
        let keys = getAllKeys()
        var totalSize: Int = 0
        
        for key in keys {
            if let data = get(forKey: key) {
                totalSize += data.count
            }
        }
        
        return KeychainStatistics(
            itemCount: keys.count,
            totalSize: totalSize,
            keys: keys
        )
    }
}

// MARK: - Keychain Statistics

struct KeychainStatistics {
    let itemCount: Int
    let totalSize: Int
    let keys: [String]
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(totalSize), countStyle: .memory)
    }
    
    var description: String {
        """
        Keychain Statistics:
        - Items: \(itemCount)
        - Total Size: \(formattedSize)
        - Keys: \(keys.joined(separator: ", "))
        """
    }
}

// MARK: - Error Handling

extension KeychainManager {
    
    /// Get human-readable error message for OSStatus
    func getErrorMessage(for status: OSStatus) -> String {
        switch status {
        case errSecSuccess:
            return "Success"
        case errSecItemNotFound:
            return "Item not found"
        case errSecDuplicateItem:
            return "Duplicate item"
        case errSecAuthFailed:
            return "Authentication failed"
        case errSecUserCanceled:
            return "User canceled"
        case errSecInteractionNotAllowed:
            return "Interaction not allowed"
        default:
            return "Unknown error (\(status))"
        }
    }
}
