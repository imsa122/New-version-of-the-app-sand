import Foundation
import Combine

final class FamilyDashboardViewModel: ObservableObject {
    @Published var status: ElderStatus?
    @Published var alerts: [String] = []
    @Published var isLinked: Bool = false

    private let syncService = ElderStatusSyncService.shared

    func load() {
        let settings = StorageManager.shared.loadSettings()
        guard let linkedElderId = settings.linkedElderId, !linkedElderId.isEmpty else {
            isLinked = false
            status = nil
            alerts = []
            return
        }

        isLinked = true
        syncService.loadStatus(for: linkedElderId)
        syncService.loadAlertFeed(for: linkedElderId)
        status = syncService.currentStatus
        alerts = syncService.alertFeed
    }

    func refresh() {
        load()
    }

    var medicationText: String {
        guard let status else { return "غير متوفر" }
        switch status.medicationStatus {
        case .taken:
            if let name = status.lastMedicationName {
                return "✅ \(status.medicationStatus.arabicLabel) - \(name)"
            }
            return "✅ \(status.medicationStatus.arabicLabel)"
        case .missed:
            if let name = status.lastMedicationName {
                return "⚠️ \(status.medicationStatus.arabicLabel) - \(name)"
            }
            return "⚠️ \(status.medicationStatus.arabicLabel)"
        case .unknown:
            return status.medicationStatus.arabicLabel
        }
    }

    var bloodPressureText: String {
        guard let status else { return "غير متوفر" }
        guard let sys = status.lastSystolic, let dia = status.lastDiastolic else {
            return "لا توجد قراءة"
        }
        return "\(sys)/\(dia) - \(status.bloodPressureStatus.arabicLabel)"
    }

    var locationText: String {
        guard let status else { return "غير متوفر" }
        return status.locationText ?? "غير متوفر"
    }

    var emergencyText: String {
        guard let status else { return "غير متوفر" }
        if status.emergencyActive { return "🚨 حالة طوارئ نشطة" }
        return "آمن"
    }
}
