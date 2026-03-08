import Foundation
import CoreLocation

struct ElderStatus: Codable, Equatable {
    var elderId: String
    var updatedAt: Date

    // Location
    var latitude: Double?
    var longitude: Double?
    var locationText: String?

    // Medication
    var lastMedicationName: String?
    var lastMedicationTakenAt: Date?
    var medicationStatus: MedicationStatus

    // Blood Pressure
    var lastSystolic: Int?
    var lastDiastolic: Int?
    var bloodPressureStatus: BloodPressureLevel

    // Safety
    var fallDetectedAt: Date?
    var emergencyActive: Bool

    static func empty(elderId: String) -> ElderStatus {
        ElderStatus(
            elderId: elderId,
            updatedAt: Date(),
            latitude: nil,
            longitude: nil,
            locationText: nil,
            lastMedicationName: nil,
            lastMedicationTakenAt: nil,
            medicationStatus: .unknown,
            lastSystolic: nil,
            lastDiastolic: nil,
            bloodPressureStatus: .unknown,
            fallDetectedAt: nil,
            emergencyActive: false
        )
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

enum MedicationStatus: String, Codable, CaseIterable {
    case unknown
    case taken
    case missed

    var arabicLabel: String {
        switch self {
        case .unknown: return "غير معروف"
        case .taken: return "تم التناول"
        case .missed: return "تم التفويت"
        }
    }
}

enum BloodPressureLevel: String, Codable, CaseIterable {
    case unknown
    case low
    case normal
    case high

    var arabicLabel: String {
        switch self {
        case .unknown: return "غير معروف"
        case .low: return "منخفض"
        case .normal: return "طبيعي"
        case .high: return "مرتفع"
        }
    }

    static func fromArabic(_ value: String) -> BloodPressureLevel {
        switch value {
        case "منخفض": return .low
        case "طبيعي": return .normal
        case "مرتفع": return .high
        default: return .unknown
        }
    }
}
