import Foundation
import UserNotifications
import Combine

class MedicationTrackingManager: ObservableObject {
    
    static let shared = MedicationTrackingManager()
    
    @Published private(set) var logs: [MedicationLog] = []
    
    private let storageKey = "medicationLogs"
    
    private init() {
        loadLogs()
        cleanOldLogs()
    }
    
    // MARK: - تسجيل أخذ الدواء
    
    func markMedicationTaken(medicationID: UUID) {
        
        let now = Date()
        
        // منع التكرار خلال نفس الدقيقة
        if let lastLog = logs.last,
           Calendar.current.isDate(lastLog.date, equalTo: now, toGranularity: .minute),
           lastLog.medicationID == medicationID {
            return
        }
        
        let log = MedicationLog(
            medicationID: medicationID,
            date: now,
            wasTaken: true
        )
        
        logs.append(log)
        saveLogs()
        
        // 🔥 إلغاء إشعار المتابعة
        EnhancedReminderManager.shared
            .cancelFollowUpNotification(for: medicationID)
        
        // 🔥 تسجيل في Activity Logger
        if let medication = StorageManager.shared
            .getActiveMedications()
            .first(where: { $0.id == medicationID }) {
            
            ActivityLogger.shared.logMedicationTaken(
                medicationId: medicationID,
                medicationName: medication.name
            )
        }
    }
    
    // MARK: - هل تم أخذ دواء اليوم
    
    var hasTakenMedicationToday: Bool {
        logs.contains {
            Calendar.current.isDateInToday($0.date) && $0.wasTaken
        }
    }
    
    // MARK: - آخر جرعة اليوم
    
    var lastTakenTimeToday: Date? {
        logs
            .filter { Calendar.current.isDateInToday($0.date) && $0.wasTaken }
            .sorted { $0.date > $1.date }
            .first?
            .date
    }
    
    // MARK: - تنظيف السجلات القديمة
    
    private func cleanOldLogs() {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        logs.removeAll { $0.date < thirtyDaysAgo }
        saveLogs()
    }
    
    // MARK: - التخزين
    
    private func saveLogs() {
        if let encoded = try? JSONEncoder().encode(logs) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    private func loadLogs() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([MedicationLog].self, from: data) {
            logs = decoded
        }
    }
}
