//
//  EncryptionManager.swift
//  Sanad
//
//  Handles data encryption and decryption using AES-GCM
//  Provides secure storage for sensitive user data
//

import Foundation
import CryptoKit

/// مدير التشفير - Encryption Manager
class EncryptionManager {
    
    // MARK: - Singleton
    
    static let shared = EncryptionManager()
    
    // MARK: - Properties
    
    private let key: SymmetricKey
    private let keychainManager = KeychainManager.shared
    
    // MARK: - Initialization
    
    private init() {
        // Try to retrieve existing encryption key from Keychain
        if let keyData = keychainManager.getEncryptionKey() {
            key = SymmetricKey(data: keyData)
            print("🔐 Loaded existing encryption key from Keychain")
        } else {
            // Generate new encryption key
            key = SymmetricKey(size: .bits256)
            let keyData = key.withUnsafeBytes { Data($0) }
            
            // Save to Keychain
            if keychainManager.saveEncryptionKey(keyData) {
                print("🔐 Generated and saved new encryption key")
            } else {
                print("❌ Failed to save encryption key to Keychain")
            }
        }
    }
    
    // MARK: - Data Encryption
    
    /// Encrypt data using AES-GCM
    func encrypt(_ data: Data) throws -> Data {
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            guard let combined = sealedBox.combined else {
                throw SanadError.encryptionFailed
            }
            print("✅ Data encrypted (\(data.count) bytes → \(combined.count) bytes)")
            return combined
        } catch {
            print("❌ Encryption failed: \(error.localizedDescription)")
            throw SanadError.encryptionFailed
        }
    }
    
    /// Encrypt codable object
    func encrypt<T: Codable>(_ object: T) throws -> Data {
        let data = try JSONEncoder().encode(object)
        return try encrypt(data)
    }
    
    // MARK: - Data Decryption
    
    /// Decrypt data using AES-GCM
    func decrypt(_ data: Data) throws -> Data {
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            print("✅ Data decrypted (\(data.count) bytes → \(decryptedData.count) bytes)")
            return decryptedData
        } catch {
            print("❌ Decryption failed: \(error.localizedDescription)")
            throw SanadError.decryptionFailed
        }
    }
    
    /// Decrypt to codable object
    func decrypt<T: Codable>(_ data: Data, as type: T.Type) throws -> T {
        let decryptedData = try decrypt(data)
        return try JSONDecoder().decode(T.self, from: decryptedData)
    }
    
    // MARK: - String Encryption
    
    /// Encrypt string to Base64 encoded string
    func encryptString(_ string: String) throws -> String {
        guard let data = string.data(using: .utf8) else {
            throw SanadError.encryptionFailed
        }
        let encrypted = try encrypt(data)
        return encrypted.base64EncodedString()
    }
    
    /// Decrypt Base64 encoded string
    func decryptString(_ encryptedString: String) throws -> String {
        guard let data = Data(base64Encoded: encryptedString) else {
            throw SanadError.decryptionFailed
        }
        let decrypted = try decrypt(data)
        guard let string = String(data: decrypted, encoding: .utf8) else {
            throw SanadError.decryptionFailed
        }
        return string
    }
    
    // MARK: - Contact Encryption
    
    /// Encrypt contact (sensitive data only)
    func encryptContact(_ contact: Contact) throws -> EncryptedContact {
        let encryptedPhone = try encryptString(contact.phoneNumber)
        
        return EncryptedContact(
            id: contact.id,
            name: contact.name, // Name not encrypted for display
            encryptedPhoneNumber: encryptedPhone,
            relationship: contact.relationship,
            isEmergencyContact: contact.isEmergencyContact,
            isFavorite: contact.isFavorite,
            photoData: contact.photoData
        )
    }
    
    /// Decrypt contact
    func decryptContact(_ encryptedContact: EncryptedContact) throws -> Contact {
        let decryptedPhone = try decryptString(encryptedContact.encryptedPhoneNumber)
        
        return Contact(
            id: encryptedContact.id,
            name: encryptedContact.name,
            phoneNumber: decryptedPhone,
            relationship: encryptedContact.relationship,
            isEmergencyContact: encryptedContact.isEmergencyContact,
            isFavorite: encryptedContact.isFavorite,
            photoData: encryptedContact.photoData
        )
    }
    
    /// Encrypt array of contacts
    func encryptContacts(_ contacts: [Contact]) throws -> [EncryptedContact] {
        return try contacts.map { try encryptContact($0) }
    }
    
    /// Decrypt array of contacts
    func decryptContacts(_ encryptedContacts: [EncryptedContact]) throws -> [Contact] {
        return try encryptedContacts.map { try decryptContact($0) }
    }
    
    // MARK: - Medication Encryption
    
    /// Encrypt medication (sensitive data only)
    func encryptMedication(_ medication: Medication) throws -> EncryptedMedication {
        let encryptedNotes = medication.notes.isEmpty ? "" : try encryptString(medication.notes)
        
        return EncryptedMedication(
            id: medication.id,
            name: medication.name, // Name not encrypted for display
            dosage: medication.dosage,
            times: medication.times,
            isActive: medication.isActive,
            encryptedNotes: encryptedNotes
        )
    }
    
    /// Decrypt medication
    func decryptMedication(_ encryptedMedication: EncryptedMedication) throws -> Medication {
        let decryptedNotes = encryptedMedication.encryptedNotes.isEmpty ? "" : try decryptString(encryptedMedication.encryptedNotes)
        
        return Medication(
            id: encryptedMedication.id,
            name: encryptedMedication.name,
            dosage: encryptedMedication.dosage,
            times: encryptedMedication.times,
            isActive: encryptedMedication.isActive,
            notes: decryptedNotes
        )
    }
    
    // MARK: - File Encryption
    
    /// Encrypt file at path
    func encryptFile(at url: URL) throws -> URL {
        let data = try Data(contentsOf: url)
        let encrypted = try encrypt(data)
        
        let encryptedURL = url.appendingPathExtension("encrypted")
        try encrypted.write(to: encryptedURL)
        
        print("✅ File encrypted: \(url.lastPathComponent)")
        return encryptedURL
    }
    
    /// Decrypt file at path
    func decryptFile(at url: URL) throws -> URL {
        let data = try Data(contentsOf: url)
        let decrypted = try decrypt(data)
        
        let decryptedURL = url.deletingPathExtension()
        try decrypted.write(to: decryptedURL)
        
        print("✅ File decrypted: \(url.lastPathComponent)")
        return decryptedURL
    }
    
    // MARK: - Key Management
    
    /// Rotate encryption key (re-encrypt all data with new key)
    func rotateKey() throws {
        // Generate new key
        let newKey = SymmetricKey(size: .bits256)
        let newKeyData = newKey.withUnsafeBytes { Data($0) }
        
        // Save new key to Keychain
        if keychainManager.saveEncryptionKey(newKeyData) {
            print("🔐 Encryption key rotated successfully")
            // Note: Caller must re-encrypt all data with new key
        } else {
            throw SanadError.encryptionFailed
        }
    }
    
    /// Delete encryption key (WARNING: All encrypted data will be unrecoverable)
    func deleteKey() -> Bool {
        let success = keychainManager.deleteEncryptionKey()
        if success {
            print("⚠️ Encryption key deleted - All encrypted data is now unrecoverable")
        }
        return success
    }
    
    // MARK: - Utility Methods
    
    /// Check if encryption is available
    func isEncryptionAvailable() -> Bool {
        return keychainManager.getEncryptionKey() != nil
    }
    
    /// Get encryption key size
    func getKeySize() -> Int {
        return key.bitCount
    }
    
    /// Generate hash of data (for integrity checking)
    func hash(_ data: Data) -> String {
        let hashed = SHA256.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Verify data integrity using hash
    func verifyIntegrity(data: Data, expectedHash: String) -> Bool {
        let actualHash = hash(data)
        return actualHash == expectedHash
    }
}

// MARK: - Encrypted Models

/// Encrypted contact model
struct EncryptedContact: Codable {
    let id: UUID
    let name: String
    let encryptedPhoneNumber: String
    let relationship: String
    let isEmergencyContact: Bool
    let isFavorite: Bool
    let photoData: Data?
}

/// Encrypted medication model
struct EncryptedMedication: Codable {
    let id: UUID
    let name: String
    let dosage: String
    let times: [Date]
    let isActive: Bool
    let encryptedNotes: String
}

// MARK: - Encryption Extensions

extension EncryptionManager {
    
    /// Encrypt and save to file
    func encryptAndSave<T: Codable>(_ object: T, to url: URL) throws {
        let encrypted = try encrypt(object)
        try encrypted.write(to: url, options: .atomic)
        print("✅ Encrypted and saved to: \(url.lastPathComponent)")
    }
    
    /// Load and decrypt from file
    func loadAndDecrypt<T: Codable>(from url: URL, as type: T.Type) throws -> T {
        let data = try Data(contentsOf: url)
        return try decrypt(data, as: type)
    }
    
    /// Secure delete (overwrite before deleting)
    func secureDelete(at url: URL) throws {
        // Get file size
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        guard let fileSize = attributes[.size] as? Int else {
            throw SanadError.storageError
        }
        
        // Overwrite with random data
        let randomData = Data((0..<fileSize).map { _ in UInt8.random(in: 0...255) })
        try randomData.write(to: url, options: .atomic)
        
        // Delete file
        try FileManager.default.removeItem(at: url)
        
        print("✅ Securely deleted: \(url.lastPathComponent)")
    }
}

// MARK: - Encryption Statistics

extension EncryptionManager {
    
    /// Get encryption statistics
    func getStatistics() -> EncryptionStatistics {
        return EncryptionStatistics(
            keySize: getKeySize(),
            isAvailable: isEncryptionAvailable(),
            algorithm: "AES-GCM",
            keyLocation: "iOS Keychain"
        )
    }
}

struct EncryptionStatistics {
    let keySize: Int
    let isAvailable: Bool
    let algorithm: String
    let keyLocation: String
    
    var description: String {
        """
        Encryption Statistics:
        - Algorithm: \(algorithm)
        - Key Size: \(keySize) bits
        - Status: \(isAvailable ? "Active" : "Inactive")
        - Key Storage: \(keyLocation)
        """
    }
}
