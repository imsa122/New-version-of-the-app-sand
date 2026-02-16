//
//  Medication.swift
//  Sanad
//
//  Model for medication reminders
//

import Foundation

/// نموذج الدواء - Medication Model
struct Medication: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var dosage: String // الجرعة مثل: حبة واحدة، ملعقة صغيرة
    var times: [MedicationTime] // أوقات تناول الدواء
    var notes: String?
    var isActive: Bool // هل التذكير نشط
    var startDate: Date
    var endDate: Date?
    
    init(
        id: UUID = UUID(),
        name: String,
        dosage: String,
        times: [MedicationTime],
        notes: String? = nil,
        isActive: Bool = true,
        startDate: Date = Date(),
        endDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.dosage = dosage
        self.times = times
        self.notes = notes
        self.isActive = isActive
        self.startDate = startDate
        self.endDate = endDate
    }
}

/// وقت تناول الدواء - Medication Time
struct MedicationTime: Identifiable, Codable, Equatable {
    var id: UUID
    var hour: Int // 0-23
    var minute: Int // 0-59
    var label: String // مثل: صباحاً، ظهراً، مساءً
    
    init(
        id: UUID = UUID(),
        hour: Int,
        minute: Int,
        label: String
    ) {
        self.id = id
        self.hour = hour
        self.minute = minute
        self.label = label
    }
    
    /// تحويل الوقت إلى نص عربي
    var timeString: String {
        let hourString = String(format: "%02d", hour)
        let minuteString = String(format: "%02d", minute)
        return "\(hourString):\(minuteString)"
    }
    
    /// تحويل الوقت إلى DateComponents للإشعارات
    var dateComponents: DateComponents {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return components
    }
}

// MARK: - Sample Data for Preview
extension Medication {
    static let sampleMedications: [Medication] = [
        Medication(
            name: "أسبرين",
            dosage: "حبة واحدة",
            times: [
                MedicationTime(hour: 8, minute: 0, label: "صباحاً"),
                MedicationTime(hour: 20, minute: 0, label: "مساءً")
            ],
            notes: "بعد الأكل"
        ),
        Medication(
            name: "فيتامين د",
            dosage: "كبسولة واحدة",
            times: [
                MedicationTime(hour: 9, minute: 0, label: "صباحاً")
            ],
            notes: "مع وجبة الإفطار"
        ),
        Medication(
            name: "دواء الضغط",
            dosage: "حبة واحدة",
            times: [
                MedicationTime(hour: 7, minute: 30, label: "صباحاً")
            ],
            notes: "قبل الأكل بنصف ساعة"
        )
    ]
}
