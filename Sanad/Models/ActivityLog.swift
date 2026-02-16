//
//  ActivityLog.swift
//  Sanad
//
//  Comprehensive activity logging system
//  Tracks all important events for review and analysis
//

import Foundation
import CoreLocation

/// سجل النشاط - Activity Log
struct ActivityLog: Codable, Identifiable {
    
    let id: UUID
    let timestamp: Date
    let type: ActivityType
    let title: String
    let description: String
    let severity: LogSeverity
    let metadata: [String: String]
    let location: LocationData?
    let relatedContactId: UUID?
    let relatedMedicationId: UUID?
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        type: ActivityType,
        title: String,
        description: String,
        severity: LogSeverity,
        metadata: [String: String] = [:],
        location: LocationData? = nil,
        relatedContactId: UUID? = nil,
        relatedMedicationId: UUID? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.title = title
        self.description = description
        self.severity = severity
        self.metadata = metadata
        self.location = location
        self.relatedContactId = relatedContactId
        self.relatedMedicationId = relatedMedicationId
    }
    
    // MARK: - Computed Properties
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.locale = Locale(identifier: "ar")
        return formatter.string(from: timestamp)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ar")
        return formatter.string(from: timestamp)
    }
    
    var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ar")
        return formatter.string(from: timestamp)
    }
    
    var icon: String {
        type.icon
    }
    
    var color: String {
        severity.colorName
    }
}

// MARK: - Activity Type

enum ActivityType: String, Codable, CaseIterable {
    case emergency
    case fallDetection
    case medicationTaken
    case medicationMissed
    case locationShared
    case phoneCall
    case geofenceExit
    case geofenceEntry
    case voiceCommand
    case settingsChanged
    case dataExported
    case dataImported
    case contactAdded
    case contactDeleted
    case medicationAdded
    case medicationDeleted
    case appLaunched
    case appClosed
    case error
    case warning
    case info
    
    var displayName: String {
        switch self {
        case .emergency: return "طوارئ"
        case .fallDetection: return "كشف سقوط"
        case .medicationTaken: return "تناول دواء"
        case .medicationMissed: return "تفويت دواء"
        case .locationShared: return "مشاركة موقع"
        case .phoneCall: return "مكالمة هاتفية"
        case .geofenceExit: return "خروج من المنطقة"
        case .geofenceEntry: return "دخول المنطقة"
        case .voiceCommand: return "أمر صوتي"
        case .settingsChanged: return "تغيير إعدادات"
        case .dataExported: return "تصدير بيانات"
        case .dataImported: return "استيراد بيانات"
        case .contactAdded: return "إضافة جهة اتصال"
        case .contactDeleted: return "حذف جهة اتصال"
        case .medicationAdded: return "إضافة دواء"
        case .medicationDeleted: return "حذف دواء"
        case .appLaunched: return "فتح التطبيق"
        case .appClosed: return "إغلاق التطبيق"
        case .error: return "خطأ"
        case .warning: return "تحذير"
        case .info: return "معلومة"
        }
    }
    
    var icon: String {
        switch self {
        case .emergency: return "exclamationmark.triangle.fill"
        case .fallDetection: return "figure.fall"
        case .medicationTaken: return "checkmark.circle.fill"
        case .medicationMissed: return "xmark.circle.fill"
        case .locationShared: return "location.fill"
        case .phoneCall: return "phone.fill"
        case .geofenceExit: return "arrow.up.right.circle.fill"
        case .geofenceEntry: return "arrow.down.left.circle.fill"
        case .voiceCommand: return "mic.fill"
        case .settingsChanged: return "gearshape.fill"
        case .dataExported: return "square.and.arrow.up.fill"
        case .dataImported: return "square.and.arrow.down.fill"
        case .contactAdded: return "person.badge.plus.fill"
        case .contactDeleted: return "person.badge.minus.fill"
        case .medicationAdded: return "pills.fill"
        case .medicationDeleted: return "trash.fill"
        case .appLaunched: return "app.badge.fill"
        case .appClosed: return "power"
        case .error: return "xmark.octagon.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    var defaultSeverity: LogSeverity {
        switch self {
        case .emergency, .fallDetection, .error:
            return .critical
        case .medicationMissed, .geofenceExit, .warning:
            return .high
        case .locationShared, .phoneCall, .voiceCommand:
            return .medium
        case .medicationTaken, .geofenceEntry:
            return .low
        default:
            return .info
        }
    }
}

// MARK: - Log Severity

enum LogSeverity: String, Codable, CaseIterable {
    case critical  // Red - Requires immediate attention
    case high      // Orange - Important
    case medium    // Yellow - Notable
    case low       // Blue - Normal
    case info      // Gray - Informational
    
    var displayName: String {
        switch self {
        case .critical: return "حرج"
        case .high: return "عالي"
        case .medium: return "متوسط"
        case .low: return "منخفض"
        case .info: return "معلومة"
        }
    }
    
    var colorName: String {
        switch self {
        case .critical: return "red"
        case .high: return "orange"
        case .medium: return "yellow"
        case .low: return "blue"
        case .info: return "gray"
        }
    }
    
    var icon: String {
        switch self {
        case .critical: return "exclamationmark.3"
        case .high: return "exclamationmark.2"
        case .medium: return "exclamationmark"
        case .low: return "info.circle"
        case .info: return "info"
        }
    }
}

// MARK: - Location Data

struct LocationData: Codable {
    let latitude: Double
    let longitude: Double
    let accuracy: Double
    let timestamp: Date
    
    init(from location: CLLocation) {
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.accuracy = location.horizontalAccuracy
        self.timestamp = location.timestamp
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var formattedCoordinates: String {
        String(format: "%.6f, %.6f", latitude, longitude)
    }
    
    var googleMapsLink: String {
        "https://www.google.com/maps?q=\(latitude),\(longitude)"
    }
}

// MARK: - Activity Statistics

struct ActivityStatistics: Codable {
    let totalLogs: Int
    let criticalCount: Int
    let highCount: Int
    let mediumCount: Int
    let lowCount: Int
    let infoCount: Int
    let emergencyCount: Int
    let fallDetectionCount: Int
    let medicationTakenCount: Int
    let medicationMissedCount: Int
    let locationSharedCount: Int
    let phoneCallCount: Int
    
    var mostCommonType: ActivityType? {
        let counts: [(ActivityType, Int)] = [
            (.emergency, emergencyCount),
            (.fallDetection, fallDetectionCount),
            (.medicationTaken, medicationTakenCount),
            (.medicationMissed, medicationMissedCount),
            (.locationShared, locationSharedCount),
            (.phoneCall, phoneCallCount)
        ]
        return counts.max(by: { $0.1 < $1.1 })?.0
    }
    
    var criticalPercentage: Double {
        guard totalLogs > 0 else { return 0 }
        return Double(criticalCount) / Double(totalLogs) * 100
    }
    
    var medicationAdherence: Double {
        let total = medicationTakenCount + medicationMissedCount
        guard total > 0 else { return 0 }
        return Double(medicationTakenCount) / Double(total) * 100
    }
}

// MARK: - Log Filter

struct LogFilter {
    var types: Set<ActivityType> = Set(ActivityType.allCases)
    var severities: Set<LogSeverity> = Set(LogSeverity.allCases)
    var startDate: Date?
    var endDate: Date?
    var searchText: String = ""
    
    func matches(_ log: ActivityLog) -> Bool {
        // Check type
        guard types.contains(log.type) else { return false }
        
        // Check severity
        guard severities.contains(log.severity) else { return false }
        
        // Check date range
        if let start = startDate, log.timestamp < start {
            return false
        }
        if let end = endDate, log.timestamp > end {
            return false
        }
        
        // Check search text
        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            return log.title.lowercased().contains(searchLower) ||
                   log.description.lowercased().contains(searchLower)
        }
        
        return true
    }
    
    static let all = LogFilter()
    
    static let criticalOnly = LogFilter(
        types: Set(ActivityType.allCases),
        severities: [.critical]
    )
    
    static let emergenciesOnly = LogFilter(
        types: [.emergency, .fallDetection],
        severities: Set(LogSeverity.allCases)
    )
    
    static let medicationsOnly = LogFilter(
        types: [.medicationTaken, .medicationMissed],
        severities: Set(LogSeverity.allCases)
    )
    
    static let today = LogFilter(
        types: Set(ActivityType.allCases),
        severities: Set(LogSeverity.allCases),
        startDate: Calendar.current.startOfDay(for: Date()),
        endDate: nil
    )
    
    static let thisWeek = LogFilter(
        types: Set(ActivityType.allCases),
        severities: Set(LogSeverity.allCases),
        startDate: Calendar.current.date(byAdding: .day, value: -7, to: Date()),
        endDate: nil
    )
}

// MARK: - Log Export Format

enum LogExportFormat {
    case json
    case csv
    case pdf
    case text
    
    var fileExtension: String {
        switch self {
        case .json: return "json"
        case .csv: return "csv"
        case .pdf: return "pdf"
        case .text: return "txt"
        }
    }
    
    var mimeType: String {
        switch self {
        case .json: return "application/json"
        case .csv: return "text/csv"
        case .pdf: return "application/pdf"
        case .text: return "text/plain"
        }
    }
}
