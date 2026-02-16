//
//  AppPreferences.swift
//  Sanad
//
//  Enhanced app preferences with comprehensive settings
//

import Foundation
import SwiftUI

/// تفضيلات التطبيق المحسّنة - Enhanced App Preferences
struct AppPreferences: Codable {
    
    // MARK: - General Settings
    
    var language: AppLanguage = .arabic
    var fontSize: FontSize = .large
    var theme: AppTheme = .auto
    var hapticFeedbackEnabled: Bool = true
    var soundEffectsEnabled: Bool = true
    var animationsEnabled: Bool = true
    
    // MARK: - Privacy & Security
    
    var dataEncryptionEnabled: Bool = true
    var biometricLockEnabled: Bool = false
    var autoLockTimeout: AutoLockTimeout = .fiveMinutes
    var requirePinForEmergency: Bool = false
    var shareAnalytics: Bool = false
    
    // MARK: - Location & Safety
    
    var locationAccuracy: LocationAccuracy = .balanced
    var geofenceEnabled: Bool = true
    var geofenceRadius: Double = 500 // meters
    var fallDetectionEnabled: Bool = true
    var fallDetectionSensitivity: FallSensitivity = .medium
    var emergencyTimeout: Int = 30 // seconds
    var autoShareLocationOnEmergency: Bool = true
    
    // MARK: - Notifications
    
    var medicationRemindersEnabled: Bool = true
    var emergencyAlertsEnabled: Bool = true
    var locationAlertsEnabled: Bool = true
    var quietHoursEnabled: Bool = false
    var quietHoursStart: Date = Calendar.current.date(from: DateComponents(hour: 22, minute: 0))!
    var quietHoursEnd: Date = Calendar.current.date(from: DateComponents(hour: 7, minute: 0))!
    var notificationSound: NotificationSound = .default
    
    // MARK: - Voice & Accessibility
    
    var voiceCommandsEnabled: Bool = true
    var voiceSpeed: VoiceSpeed = .normal
    var voiceVolume: Float = 0.8
    var highContrastMode: Bool = false
    var reduceMotion: Bool = false
    var largerTouchTargets: Bool = true
    
    // MARK: - Data Management
    
    var autoBackupEnabled: Bool = true
    var backupFrequency: BackupFrequency = .daily
    var lastBackupDate: Date?
    var cacheEnabled: Bool = true
    var maxCacheSize: Int = 100 // MB
    var dataRetentionDays: Int = 90
    
    // MARK: - Emergency Contacts
    
    var emergencyContactsLimit: Int = 5
    var emergencyMessageTemplate: String = "أحتاج مساعدة! موقعي: {location}"
    var sendPhotoOnEmergency: Bool = false
    var sendVoiceMessageOnEmergency: Bool = false
    
    // MARK: - Health Check-in
    
    var dailyCheckInEnabled: Bool = true
    var checkInReminderTime: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0))!
    var trackMood: Bool = true
    var trackSymptoms: Bool = true
    var trackSleep: Bool = true
    var trackPain: Bool = true
    
    // MARK: - Performance
    
    var performanceMonitoringEnabled: Bool = true
    var lowPowerModeOptimizations: Bool = true
    var backgroundRefreshEnabled: Bool = true
    
    // MARK: - Default Configuration
    
    static let `default` = AppPreferences()
    
    // MARK: - Validation
    
    func validate() -> [String] {
        var errors: [String] = []
        
        if geofenceRadius < 100 || geofenceRadius > 2000 {
            errors.append("نطاق السياج الجغرافي يجب أن يكون بين 100-2000 متر")
        }
        
        if emergencyTimeout < 10 || emergencyTimeout > 60 {
            errors.append("مهلة الطوارئ يجب أن تكون بين 10-60 ثانية")
        }
        
        if emergencyContactsLimit < 1 || emergencyContactsLimit > 10 {
            errors.append("عدد جهات الاتصال الطارئة يجب أن يكون بين 1-10")
        }
        
        if maxCacheSize < 10 || maxCacheSize > 500 {
            errors.append("حجم الذاكرة المؤقتة يجب أن يكون بين 10-500 ميجابايت")
        }
        
        if dataRetentionDays < 7 || dataRetentionDays > 365 {
            errors.append("مدة الاحتفاظ بالبيانات يجب أن تكون بين 7-365 يوم")
        }
        
        return errors
    }
}

// MARK: - Enums

enum AppLanguage: String, Codable, CaseIterable {
    case arabic = "ar"
    case english = "en"
    
    var displayName: String {
        switch self {
        case .arabic: return "العربية"
        case .english: return "English"
        }
    }
    
    var icon: String {
        switch self {
        case .arabic: return "🇸🇦"
        case .english: return "🇬🇧"
        }
    }
}

enum AppTheme: String, Codable, CaseIterable {
    case light = "light"
    case dark = "dark"
    case auto = "auto"
    
    var displayName: String {
        switch self {
        case .light: return "فاتح"
        case .dark: return "داكن"
        case .auto: return "تلقائي"
        }
    }
    
    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .auto: return "circle.lefthalf.filled"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .auto: return nil
        }
    }
}

enum AutoLockTimeout: Int, Codable, CaseIterable {
    case oneMinute = 60
    case twoMinutes = 120
    case fiveMinutes = 300
    case tenMinutes = 600
    case never = 0
    
    var displayName: String {
        switch self {
        case .oneMinute: return "دقيقة واحدة"
        case .twoMinutes: return "دقيقتان"
        case .fiveMinutes: return "5 دقائق"
        case .tenMinutes: return "10 دقائق"
        case .never: return "أبداً"
        }
    }
}

enum LocationAccuracy: String, Codable, CaseIterable {
    case high = "high"
    case balanced = "balanced"
    case low = "low"
    
    var displayName: String {
        switch self {
        case .high: return "عالية"
        case .balanced: return "متوازنة"
        case .low: return "منخفضة"
        }
    }
    
    var description: String {
        switch self {
        case .high: return "دقة عالية (استهلاك بطارية أكبر)"
        case .balanced: return "متوازنة (موصى بها)"
        case .low: return "منخفضة (توفير البطارية)"
        }
    }
}

enum FallSensitivity: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var displayName: String {
        switch self {
        case .low: return "منخفضة"
        case .medium: return "متوسطة"
        case .high: return "عالية"
        }
    }
    
    var description: String {
        switch self {
        case .low: return "كشف السقوط الشديد فقط"
        case .medium: return "كشف متوازن (موصى به)"
        case .high: return "كشف حساس (قد يكون هناك إنذارات كاذبة)"
        }
    }
}

enum NotificationSound: String, Codable, CaseIterable {
    case `default` = "default"
    case gentle = "gentle"
    case urgent = "urgent"
    case silent = "silent"
    
    var displayName: String {
        switch self {
        case .default: return "افتراضي"
        case .gentle: return "هادئ"
        case .urgent: return "عاجل"
        case .silent: return "صامت"
        }
    }
}

enum VoiceSpeed: Float, Codable, CaseIterable {
    case slow = 0.5
    case normal = 1.0
    case fast = 1.5
    
    var displayName: String {
        switch self {
        case .slow: return "بطيء"
        case .normal: return "عادي"
        case .fast: return "سريع"
        }
    }
}

enum BackupFrequency: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case manual = "manual"
    
    var displayName: String {
        switch self {
        case .daily: return "يومي"
        case .weekly: return "أسبوعي"
        case .monthly: return "شهري"
        case .manual: return "يدوي"
        }
    }
}

// MARK: - Preferences Manager

class PreferencesManager {
    static let shared = PreferencesManager()
    
    private let storageManager = StorageManager.shared
    private let cacheManager = CacheManager.shared
    
    private init() {}
    
    // MARK: - Load/Save
    
    func loadPreferences() -> AppPreferences {
        // Try cache first
        if let cached: AppPreferences = cacheManager.get(forKey: "app_preferences") {
            return cached
        }
        
        // Load from storage
        let preferences = storageManager.loadSettings().toPreferences()
        
        // Cache for next time
        cacheManager.cache(preferences, forKey: "app_preferences")
        
        return preferences
    }
    
    func savePreferences(_ preferences: AppPreferences) {
        // Validate first
        let errors = preferences.validate()
        guard errors.isEmpty else {
            print("❌ Preferences validation failed: \(errors)")
            return
        }
        
        // Save to storage
        storageManager.saveSettings(preferences.toAppSettings())
        
        // Update cache
        cacheManager.cache(preferences, forKey: "app_preferences")
        
        // Post notification
        NotificationCenter.default.post(name: .preferencesChanged, object: preferences)
        
        print("✅ Preferences saved successfully")
    }
    
    // MARK: - Export/Import
    
    func exportPreferences() throws -> Data {
        let preferences = loadPreferences()
        return try JSONEncoder().encode(preferences)
    }
    
    func importPreferences(from data: Data) throws {
        let preferences = try JSONDecoder().decode(AppPreferences.self, from: data)
        
        // Validate
        let errors = preferences.validate()
        guard errors.isEmpty else {
            throw SanadError.invalidInput("إعدادات غير صالحة: \(errors.joined(separator: ", "))")
        }
        
        savePreferences(preferences)
    }
    
    // MARK: - Reset
    
    func resetToDefaults() {
        savePreferences(.default)
        print("✅ Preferences reset to defaults")
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let preferencesChanged = Notification.Name("preferencesChanged")
}

// MARK: - AppSettings Extension

extension AppSettings {
    func toPreferences() -> AppPreferences {
        var prefs = AppPreferences()
        prefs.fontSize = self.fontSize
        prefs.fallDetectionEnabled = self.fallDetectionEnabled
        prefs.voiceCommandsEnabled = self.voiceCommandsEnabled
        prefs.geofenceRadius = self.geofenceRadius
        return prefs
    }
}

extension AppPreferences {
    func toAppSettings() -> AppSettings {
        return AppSettings(
            fontSize: self.fontSize,
            homeLocation: nil,
            geofenceRadius: self.geofenceRadius,
            fallDetectionEnabled: self.fallDetectionEnabled,
            voiceCommandsEnabled: self.voiceCommandsEnabled
        )
    }
}
