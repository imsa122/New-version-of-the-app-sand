//
//  Validators.swift
//  Sanad
//
//  Input validation utilities for the app
//

import Foundation
import CoreLocation

/// مدقق المدخلات - Input Validators
struct Validators {
    
    // MARK: - Phone Number Validation
    
    /// Validate Saudi phone number
    /// Accepts formats: 05XXXXXXXX, +966XXXXXXXXX, 00966XXXXXXXXX
    static func isValidSaudiPhone(_ phone: String) -> Bool {
        // Remove spaces and special characters
        let cleaned = phone.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        
        // Saudi phone patterns
        let patterns = [
            "^05[0-9]{8}$",                    // 05XXXXXXXX
            "^\\+9665[0-9]{8}$",               // +9665XXXXXXXX
            "^009665[0-9]{8}$",                // 009665XXXXXXXX
            "^9665[0-9]{8}$"                   // 9665XXXXXXXX
        ]
        
        for pattern in patterns {
            if cleaned.range(of: pattern, options: .regularExpression) != nil {
                return true
            }
        }
        
        return false
    }
    
    /// Format Saudi phone number to standard format (05XXXXXXXX)
    static func formatSaudiPhone(_ phone: String) -> String {
        let cleaned = phone.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        
        // Convert to 05XXXXXXXX format
        if cleaned.hasPrefix("+966") {
            return "0" + cleaned.dropFirst(4)
        } else if cleaned.hasPrefix("00966") {
            return "0" + cleaned.dropFirst(5)
        } else if cleaned.hasPrefix("966") {
            return "0" + cleaned.dropFirst(3)
        }
        
        return cleaned
    }
    
    /// Get phone validation error message
    static func phoneValidationError(for phone: String) -> String? {
        if phone.isEmpty {
            return "رقم الهاتف مطلوب"
        }
        
        if !isValidSaudiPhone(phone) {
            return "رقم الهاتف غير صحيح. أدخل رقم سعودي (05XXXXXXXX)"
        }
        
        return nil
    }
    
    // MARK: - Contact Name Validation
    
    /// Validate contact name
    static func isValidContactName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 2 && trimmed.count <= 50
    }
    
    /// Get contact name validation error
    static func contactNameValidationError(for name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return "الاسم مطلوب"
        }
        
        if trimmed.count < 2 {
            return "الاسم قصير جداً (الحد الأدنى حرفان)"
        }
        
        if trimmed.count > 50 {
            return "الاسم طويل جداً (الحد الأقصى 50 حرف)"
        }
        
        return nil
    }
    
    // MARK: - Medication Validation
    
    /// Validate medication name
    static func isValidMedicationName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 2 && trimmed.count <= 100
    }
    
    /// Get medication name validation error
    static func medicationNameValidationError(for name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return "اسم الدواء مطلوب"
        }
        
        if trimmed.count < 2 {
            return "اسم الدواء قصير جداً (الحد الأدنى حرفان)"
        }
        
        if trimmed.count > 100 {
            return "اسم الدواء طويل جداً (الحد الأقصى 100 حرف)"
        }
        
        return nil
    }
    
    /// Validate medication dosage
    static func isValidDosage(_ dosage: String) -> Bool {
        let trimmed = dosage.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= 50
    }
    
    /// Get dosage validation error
    static func dosageValidationError(for dosage: String) -> String? {
        let trimmed = dosage.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return "الجرعة مطلوبة"
        }
        
        if trimmed.count > 50 {
            return "الجرعة طويلة جداً (الحد الأقصى 50 حرف)"
        }
        
        return nil
    }
    
    /// Validate medication notes
    static func isValidNotes(_ notes: String) -> Bool {
        return notes.count <= 500
    }
    
    /// Get notes validation error
    static func notesValidationError(for notes: String) -> String? {
        if notes.count > 500 {
            return "الملاحظات طويلة جداً (الحد الأقصى 500 حرف)"
        }
        return nil
    }
    
    // MARK: - Location Validation
    
    /// Validate coordinates
    static func isValidCoordinate(_ coordinate: CLLocationCoordinate2D) -> Bool {
        return coordinate.latitude >= -90 && coordinate.latitude <= 90 &&
               coordinate.longitude >= -180 && coordinate.longitude <= 180
    }
    
    /// Validate geofence radius
    static func isValidGeofenceRadius(_ radius: Double) -> Bool {
        return radius >= 100 && radius <= 2000
    }
    
    /// Get geofence radius validation error
    static func geofenceRadiusValidationError(for radius: Double) -> String? {
        if radius < 100 {
            return "النطاق صغير جداً (الحد الأدنى 100 متر)"
        }
        
        if radius > 2000 {
            return "النطاق كبير جداً (الحد الأقصى 2000 متر)"
        }
        
        return nil
    }
    
    // MARK: - Time Validation
    
    /// Validate that time is not in the past
    static func isValidFutureTime(_ date: Date) -> Bool {
        return date > Date()
    }
    
    /// Validate time interval
    static func isValidTimeInterval(_ interval: TimeInterval) -> Bool {
        return interval > 0 && interval <= 86400 // Max 24 hours
    }
    
    // MARK: - Emergency Timeout Validation
    
    /// Validate emergency timeout (10-60 seconds)
    static func isValidEmergencyTimeout(_ timeout: Int) -> Bool {
        return timeout >= 10 && timeout <= 60
    }
    
    /// Get emergency timeout validation error
    static func emergencyTimeoutValidationError(for timeout: Int) -> String? {
        if timeout < 10 {
            return "المهلة قصيرة جداً (الحد الأدنى 10 ثواني)"
        }
        
        if timeout > 60 {
            return "المهلة طويلة جداً (الحد الأقصى 60 ثانية)"
        }
        
        return nil
    }
    
    // MARK: - General Validation
    
    /// Validate string is not empty
    static func isNotEmpty(_ string: String) -> Bool {
        return !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Validate string length
    static func isValidLength(_ string: String, min: Int, max: Int) -> Bool {
        let length = string.trimmingCharacters(in: .whitespacesAndNewlines).count
        return length >= min && length <= max
    }
    
    /// Sanitize string (remove extra spaces, trim)
    static func sanitize(_ string: String) -> String {
        return string
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
}

// MARK: - Validation Result

struct ValidationResult {
    let isValid: Bool
    let errorMessage: String?
    
    static func success() -> ValidationResult {
        return ValidationResult(isValid: true, errorMessage: nil)
    }
    
    static func failure(_ message: String) -> ValidationResult {
        return ValidationResult(isValid: false, errorMessage: message)
    }
}

// MARK: - Contact Validator

struct ContactValidator {
    static func validate(name: String, phone: String, relationship: String) -> ValidationResult {
        // Validate name
        if let nameError = Validators.contactNameValidationError(for: name) {
            return .failure(nameError)
        }
        
        // Validate phone
        if let phoneError = Validators.phoneValidationError(for: phone) {
            return .failure(phoneError)
        }
        
        // Validate relationship
        if !Validators.isNotEmpty(relationship) {
            return .failure("العلاقة مطلوبة")
        }
        
        return .success()
    }
}

// MARK: - Medication Validator

struct MedicationValidator {
    static func validate(name: String, dosage: String, times: [Date], notes: String) -> ValidationResult {
        // Validate name
        if let nameError = Validators.medicationNameValidationError(for: name) {
            return .failure(nameError)
        }
        
        // Validate dosage
        if let dosageError = Validators.dosageValidationError(for: dosage) {
            return .failure(dosageError)
        }
        
        // Validate times
        if times.isEmpty {
            return .failure("يجب تحديد وقت واحد على الأقل")
        }
        
        // Validate notes
        if let notesError = Validators.notesValidationError(for: notes) {
            return .failure(notesError)
        }
        
        return .success()
    }
}

// MARK: - Settings Validator

struct SettingsValidator {
    static func validateGeofenceRadius(_ radius: Double) -> ValidationResult {
        if let error = Validators.geofenceRadiusValidationError(for: radius) {
            return .failure(error)
        }
        return .success()
    }
    
    static func validateEmergencyTimeout(_ timeout: Int) -> ValidationResult {
        if let error = Validators.emergencyTimeoutValidationError(for: timeout) {
            return .failure(error)
        }
        return .success()
    }
}
