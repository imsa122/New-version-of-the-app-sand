//
//  ActivityLogger.swift
//  Sanad
//
//  Service for logging and managing activity logs
//  Provides comprehensive activity tracking and analysis
//
import Foundation
import CoreLocation
import UIKit

/// مسجل النشاط - Activity Logger
class ActivityLogger {
    
    // MARK: - Singleton
    
    static let shared = ActivityLogger()
    
    // MARK: - Properties
    
    private let storageKey = "activity_logs"
    private let maxLogsInMemory = 1000
    private let maxLogsOnDisk = 10000
    private var logs: [ActivityLog] = []
    
    private let fileManager = FileManager.default
    private let logsDirectory: URL
    
    // MARK: - Initialization
    
    private init() {
        // Setup logs directory
        let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        logsDirectory = documentsDir.appendingPathComponent("ActivityLogs")
        
        // Create directory if needed
        try? fileManager.createDirectory(at: logsDirectory, withIntermediateDirectories: true)
        
        // Load existing logs
        loadLogs()
        
        // Setup auto-save
        setupAutoSave()
        
        print("📝 ActivityLogger initialized with \(logs.count) logs")
    }
    
    // MARK: - Logging Methods
    
    /// Log an activity
    func log(
        type: ActivityType,
        title: String,
        description: String,
        severity: LogSeverity? = nil,
        metadata: [String: String] = [:],
        location: CLLocation? = nil,
        relatedContactId: UUID? = nil,
        relatedMedicationId: UUID? = nil
    ) {
        let log = ActivityLog(
            type: type,
            title: title,
            description: description,
            severity: severity ?? type.defaultSeverity,
            metadata: metadata,
            location: location.map { LocationData(from: $0) },
            relatedContactId: relatedContactId,
            relatedMedicationId: relatedMedicationId
        )
        
        addLog(log)
    }
    
    /// Add a pre-created log
    func addLog(_ log: ActivityLog) {
        logs.insert(log, at: 0) // Insert at beginning for chronological order
        
        // Trim if needed
        if logs.count > maxLogsInMemory {
            logs = Array(logs.prefix(maxLogsInMemory))
        }
        
        // Save to disk
        saveLogs()
        
        // Post notification
        NotificationCenter.default.post(name: .activityLogged, object: log)
        
        print("📝 Logged: [\(log.type.displayName)] \(log.title)")
    }
    
    // MARK: - Convenience Logging Methods
    
    func logEmergency(description: String, location: CLLocation? = nil, contactIds: [UUID] = []) {
        log(
            type: .emergency,
            title: "تفعيل الطوارئ",
            description: description,
            severity: .critical,
            metadata: [
                "contacts_notified": "\(contactIds.count)",
                "has_location": location != nil ? "true" : "false"
            ],
            location: location
        )
    }
    
    func logFallDetection(location: CLLocation? = nil, wasConfirmed: Bool) {
        log(
            type: .fallDetection,
            title: "كشف سقوط",
            description: wasConfirmed ? "تم تأكيد السقوط" : "تم إلغاء تنبيه السقوط",
            severity: wasConfirmed ? .critical : .medium,
            metadata: [
                "confirmed": wasConfirmed ? "true" : "false",
                "has_location": location != nil ? "true" : "false"
            ],
            location: location
        )
    }
    
    func logMedicationTaken(medicationId: UUID, medicationName: String) {
        log(
            type: .medicationTaken,
            title: "تناول دواء",
            description: "تم تناول \(medicationName)",
            severity: .low,
            metadata: ["medication_name": medicationName],
            relatedMedicationId: medicationId
        )
    }
    
    func logMedicationMissed(medicationId: UUID, medicationName: String) {
        log(
            type: .medicationMissed,
            title: "تفويت دواء",
            description: "تم تفويت \(medicationName)",
            severity: .high,
            metadata: ["medication_name": medicationName],
            relatedMedicationId: medicationId
        )
    }

    func logBloodPressure(systolic: Int, diastolic: Int, status: String) {
        let isAlert = status == "مرتفع" || status == "منخفض"

        log(
            type: isAlert ? .bloodPressureAlert : .bloodPressureLogged,
            title: isAlert ? "تنبيه ضغط الدم" : "تسجيل ضغط الدم",
            description: "القراءة: \(systolic)/\(diastolic) - الحالة: \(status)",
            severity: isAlert ? .critical : .low,
            metadata: [
                "systolic": "\(systolic)",
                "diastolic": "\(diastolic)",
                "status": status
            ]
        )
    }

    func logPrayerCheckIn(prayerName: String, completed: Bool) {
        log(
            type: .prayerCheckIn,
            title: "تأكيد الصلاة",
            description: completed ? "تم تأكيد أداء صلاة \(prayerName)" : "لم يتم تأكيد صلاة \(prayerName)",
            severity: completed ? .low : .medium,
            metadata: [
                "prayer_name": prayerName,
                "completed": completed ? "true" : "false"
            ]
        )
    }
    
    func logLocationShared(location: CLLocation, method: String, recipientCount: Int) {
        log(
            type: .locationShared,
            title: "مشاركة موقع",
            description: "تم مشاركة الموقع عبر \(method) مع \(recipientCount) شخص",
            severity: .medium,
            metadata: [
                "method": method,
                "recipient_count": "\(recipientCount)"
            ],
            location: location
        )
    }
    
    func logPhoneCall(contactId: UUID, contactName: String, duration: TimeInterval? = nil) {
        var metadata: [String: String] = ["contact_name": contactName]
        if let duration = duration {
            metadata["duration"] = "\(Int(duration))"
        }
        
        log(
            type: .phoneCall,
            title: "مكالمة هاتفية",
            description: "اتصال بـ \(contactName)",
            severity: .low,
            metadata: metadata,
            relatedContactId: contactId
        )
    }
    
    func logGeofenceExit(location: CLLocation) {
        log(
            type: .geofenceExit,
            title: "خروج من المنطقة",
            description: "تم الخروج من منطقة المنزل",
            severity: .high,
            metadata: [:],
            location: location
        )
    }
    
    func logGeofenceEntry(location: CLLocation) {
        log(
            type: .geofenceEntry,
            title: "دخول المنطقة",
            description: "تم الدخول إلى منطقة المنزل",
            severity: .low,
            metadata: [:],
            location: location
        )
    }
    
    func logVoiceCommand(command: String, success: Bool) {
        log(
            type: .voiceCommand,
            title: "أمر صوتي",
            description: success ? "تم تنفيذ: \(command)" : "فشل تنفيذ: \(command)",
            severity: success ? .low : .medium,
            metadata: [
                "command": command,
                "success": success ? "true" : "false"
            ]
        )
    }
    
    func logError(error: Error, context: String) {
        log(
            type: .error,
            title: "خطأ",
            description: "\(context): \(error.localizedDescription)",
            severity: .critical,
            metadata: [
                "context": context,
                "error_type": String(describing: type(of: error))
            ]
        )
    }
    
    // MARK: - Retrieval Methods
    
    /// Get all logs
    func getAllLogs() -> [ActivityLog] {
        return logs
    }
    
    /// Get logs with filter
    func getLogs(filter: LogFilter) -> [ActivityLog] {
        return logs.filter { filter.matches($0) }
    }
    
    /// Get logs by type
    func getLogs(ofType type: ActivityType) -> [ActivityLog] {
        return logs.filter { $0.type == type }
    }
    
    /// Get logs by severity
    func getLogs(withSeverity severity: LogSeverity) -> [ActivityLog] {
        return logs.filter { $0.severity == severity }
    }
    
    /// Get logs for date range
    func getLogs(from startDate: Date, to endDate: Date) -> [ActivityLog] {
        return logs.filter { $0.timestamp >= startDate && $0.timestamp <= endDate }
    }
    
    /// Get logs for today
    func getLogsForToday() -> [ActivityLog] {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return getLogs(from: startOfDay, to: Date())
    }
    
    /// Get logs for this week
    func getLogsForThisWeek() -> [ActivityLog] {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return getLogs(from: weekAgo, to: Date())
    }
    
    /// Get logs for this month
    func getLogsForThisMonth() -> [ActivityLog] {
        let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        return getLogs(from: monthAgo, to: Date())
    }
    
    // MARK: - Statistics
    
    /// Get activity statistics
    func getStatistics(for logs: [ActivityLog]? = nil) -> ActivityStatistics {
        let logsToAnalyze = logs ?? self.logs
        
        return ActivityStatistics(
            totalLogs: logsToAnalyze.count,
            criticalCount: logsToAnalyze.filter { $0.severity == .critical }.count,
            highCount: logsToAnalyze.filter { $0.severity == .high }.count,
            mediumCount: logsToAnalyze.filter { $0.severity == .medium }.count,
            lowCount: logsToAnalyze.filter { $0.severity == .low }.count,
            infoCount: logsToAnalyze.filter { $0.severity == .info }.count,
            emergencyCount: logsToAnalyze.filter { $0.type == .emergency }.count,
            fallDetectionCount: logsToAnalyze.filter { $0.type == .fallDetection }.count,
            medicationTakenCount: logsToAnalyze.filter { $0.type == .medicationTaken }.count,
            medicationMissedCount: logsToAnalyze.filter { $0.type == .medicationMissed }.count,
            locationSharedCount: logsToAnalyze.filter { $0.type == .locationShared }.count,
            phoneCallCount: logsToAnalyze.filter { $0.type == .phoneCall }.count
        )
    }
    
    /// Get logs grouped by date
    func getLogsGroupedByDate() -> [Date: [ActivityLog]] {
        var grouped: [Date: [ActivityLog]] = [:]
        
        for log in logs {
            let date = Calendar.current.startOfDay(for: log.timestamp)
            if grouped[date] == nil {
                grouped[date] = []
            }
            grouped[date]?.append(log)
        }
        
        return grouped
    }
    
    // MARK: - Export
    
    /// Export logs to JSON
    func exportToJSON(logs: [ActivityLog]? = nil) throws -> Data {
        let logsToExport = logs ?? self.logs
        return try JSONEncoder().encode(logsToExport)
    }
    
    /// Export logs to CSV
    func exportToCSV(logs: [ActivityLog]? = nil) -> String {
        let logsToExport = logs ?? self.logs
        
        var csv = "التاريخ,الوقت,النوع,العنوان,الوصف,الخطورة\n"
        
        for log in logsToExport {
            let row = "\(log.formattedDate),\(log.formattedTime),\(log.type.displayName),\(log.title),\(log.description),\(log.severity.displayName)\n"
            csv += row
        }
        
        return csv
    }
    
    /// Export logs to text
    func exportToText(logs: [ActivityLog]? = nil) -> String {
        let logsToExport = logs ?? self.logs
        
        var text = "سجل النشاط - تطبيق سند\n"
        text += "تاريخ التصدير: \(Date().formatted())\n"
        text += "عدد السجلات: \(logsToExport.count)\n"
        text += String(repeating: "=", count: 50) + "\n\n"
        
        for log in logsToExport {
            text += "[\(log.formattedDateTime)] \(log.type.displayName)\n"
            text += "العنوان: \(log.title)\n"
            text += "الوصف: \(log.description)\n"
            text += "الخطورة: \(log.severity.displayName)\n"
            if let location = log.location {
                text += "الموقع: \(location.formattedCoordinates)\n"
            }
            text += "\n"
        }
        
        return text
    }
    
    // MARK: - Management
    
    /// Clear all logs
    func clearAllLogs() {
        logs.removeAll()
        saveLogs()
        print("🗑️ All logs cleared")
    }
    
    /// Clear logs older than specified days
    func clearOldLogs(olderThan days: Int) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let countBefore = logs.count
        logs = logs.filter { $0.timestamp >= cutoffDate }
        let countAfter = logs.count
        saveLogs()
        print("🗑️ Cleared \(countBefore - countAfter) old logs")
    }
    
    /// Delete specific log
    func deleteLog(_ log: ActivityLog) {
        logs.removeAll { $0.id == log.id }
        saveLogs()
    }
    
    // MARK: - Persistence
    
    private func loadLogs() {
        let fileURL = logsDirectory.appendingPathComponent("logs.json")
        
        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let loadedLogs = try? JSONDecoder().decode([ActivityLog].self, from: data) else {
            return
        }
        
        logs = loadedLogs
        print("📝 Loaded \(logs.count) logs from disk")
    }
    
    private func saveLogs() {
        let fileURL = logsDirectory.appendingPathComponent("logs.json")
        
        // Trim to max size before saving
        let logsToSave = Array(logs.prefix(maxLogsOnDisk))
        
        guard let data = try? JSONEncoder().encode(logsToSave) else {
            print("❌ Failed to encode logs")
            return
        }
        
        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("❌ Failed to save logs: \(error)")
        }
    }
    
    private func setupAutoSave() {
        // Save logs every 5 minutes
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.saveLogs()
        }
        
        // Save on app termination
        NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.saveLogs()
        }
        
        // Save on app background
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.saveLogs()
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let activityLogged = Notification.Name("activityLogged")
}
