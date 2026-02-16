import Foundation
import CoreLocation
import UIKit

class ActivityLogger {
    
    // MARK: - Singleton
    
    static let shared = ActivityLogger()
    
    // MARK: - Properties
    
    private let maxLogsInMemory = 1000
    private let maxLogsOnDisk = 10000
    private var logs: [ActivityLog] = []
    
    private let fileManager = FileManager.default
    private let logsDirectory: URL
    
    private var lastLogTimestamp: Date?
    
    // MARK: - Initialization
    
    private init() {
        let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        logsDirectory = documentsDir.appendingPathComponent("ActivityLogs")
        
        try? fileManager.createDirectory(at: logsDirectory, withIntermediateDirectories: true)
        
        loadLogs()
        setupAutoSave()
        
        print("📝 ActivityLogger initialized with \(logs.count) logs")
    }
    
    // MARK: - Core Logging
    
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
        let now = Date()
        
        // منع تكرار تسجيل نفس الحدث خلال 2 ثانية
        if let last = lastLogTimestamp,
           now.timeIntervalSince(last) < 2 {
            return
        }
        
        lastLogTimestamp = now
        
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
    
    func addLog(_ log: ActivityLog) {
        logs.insert(log, at: 0)
        
        if logs.count > maxLogsInMemory {
            logs = Array(logs.prefix(maxLogsInMemory))
        }
        
        saveLogs()
        
        NotificationCenter.default.post(name: .activityLogged, object: log)
        
        print("📝 Logged: [\(log.type.displayName)] \(log.title)")
    }
    
    // MARK: - Medication
    
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
            description: "لم يتم تأكيد تناول \(medicationName)",
            severity: .high,
            metadata: ["medication_name": medicationName],
            relatedMedicationId: medicationId
        )
    }
    
    func logFamilyNotification(method: String) {
        log(
            type: .info,
            title: "تنبيه للعائلة",
            description: "تم إرسال تنبيه عبر \(method)",
            severity: .medium,
            metadata: ["method": method]
        )
    }
    
    // MARK: - Retrieval
    
    func getAllLogs() -> [ActivityLog] {
        logs
    }
    
    func getLogsForToday() -> [ActivityLog] {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return logs.filter { $0.timestamp >= startOfDay }
    }
    
    // MARK: - Export
    
    func exportToCSV() -> String {
        var csv = "التاريخ,الوقت,النوع,العنوان,الوصف,الخطورة\n"
        
        for log in logs {
            let row = "\(log.formattedDate),\(log.formattedTime),\(log.type.displayName),\(log.title),\(log.description),\(log.severity.displayName)\n"
            csv += row
        }
        
        return csv
    }
    
    // MARK: - Management
    
    func clearAllLogs() {
        logs.removeAll()
        saveLogs()
        print("🗑️ All logs cleared")
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
    }
    
    private func saveLogs() {
        let fileURL = logsDirectory.appendingPathComponent("logs.json")
        let logsToSave = Array(logs.prefix(maxLogsOnDisk))
        
        guard let data = try? JSONEncoder().encode(logsToSave) else {
            print("❌ Failed to encode logs")
            return
        }
        
        try? data.write(to: fileURL, options: .atomic)
    }
    
    private func setupAutoSave() {
        let timer = Timer(timeInterval: 300, repeats: true) { [weak self] _ in
            self?.saveLogs()
        }
        RunLoop.main.add(timer, forMode: .common)
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.saveLogs()
        }
    }
}

extension Notification.Name {
    static let activityLogged = Notification.Name("activityLogged")
}
