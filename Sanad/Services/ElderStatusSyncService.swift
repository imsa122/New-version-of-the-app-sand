import Foundation
import Combine
import CoreLocation

final class ElderStatusSyncService: ObservableObject {
    static let shared = ElderStatusSyncService()

    @Published private(set) var currentStatus: ElderStatus?
    @Published private(set) var alertFeed: [String] = []

    private let statusStoragePrefix = "elder_status_"
    private let alertStoragePrefix = "family_alert_feed_"

    private init() {}

    // MARK: - Identity helpers

    func resolveElderId() -> String {
        let settings = StorageManager.shared.loadSettings()
        if settings.userMode == .elder {
            return currentDeviceId()
        }
        if let linked = settings.linkedElderId, !linked.isEmpty {
            return linked
        }
        return "unlinked-elder"
    }

    func currentDeviceId() -> String {
        if let existing = UserDefaults.standard.string(forKey: "sanad_device_id"), !existing.isEmpty {
            return existing
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: "sanad_device_id")
        return newId
    }

    // MARK: - Load/Save

    func loadStatus(for elderId: String) {
        let key = statusStoragePrefix + elderId
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(ElderStatus.self, from: data) else {
            currentStatus = ElderStatus.empty(elderId: elderId)
            return
        }
        currentStatus = decoded
    }

    private func saveStatus(_ status: ElderStatus) {
        let key = statusStoragePrefix + status.elderId
        guard let data = try? JSONEncoder().encode(status) else { return }
        UserDefaults.standard.set(data, forKey: key)
        currentStatus = status
    }

    private func pushAlert(_ message: String, elderId: String) {
        let key = alertStoragePrefix + elderId
        var existing = UserDefaults.standard.stringArray(forKey: key) ?? []
        existing.insert(message, at: 0)
        existing = Array(existing.prefix(100))
        UserDefaults.standard.set(existing, forKey: key)
        alertFeed = existing
    }

    func loadAlertFeed(for elderId: String) {
        let key = alertStoragePrefix + elderId
        alertFeed = UserDefaults.standard.stringArray(forKey: key) ?? []
    }

    // MARK: - Update APIs (Father side)

    func publishLocation(_ location: CLLocation?, locationText: String?) {
        let elderId = resolveElderId()
        var status = currentStatus ?? ElderStatus.empty(elderId: elderId)
        status.updatedAt = Date()
        status.latitude = location?.coordinate.latitude
        status.longitude = location?.coordinate.longitude
        status.locationText = locationText
        saveStatus(status)
    }

    func publishMedicationTaken(name: String) {
        let elderId = resolveElderId()
        var status = currentStatus ?? ElderStatus.empty(elderId: elderId)
        status.updatedAt = Date()
        status.lastMedicationName = name
        status.lastMedicationTakenAt = Date()
        status.medicationStatus = .taken
        saveStatus(status)
    }

    func publishMedicationMissed(name: String) {
        let elderId = resolveElderId()
        var status = currentStatus ?? ElderStatus.empty(elderId: elderId)
        status.updatedAt = Date()
        status.lastMedicationName = name
        status.medicationStatus = .missed
        saveStatus(status)
        pushAlert("⚠️ تم تفويت دواء: \(name)", elderId: elderId)
    }

    func publishBloodPressure(systolic: Int, diastolic: Int, statusArabic: String) {
        let elderId = resolveElderId()
        var status = currentStatus ?? ElderStatus.empty(elderId: elderId)
        status.updatedAt = Date()
        status.lastSystolic = systolic
        status.lastDiastolic = diastolic
        status.bloodPressureStatus = .fromArabic(statusArabic)
        saveStatus(status)

        if status.bloodPressureStatus == .low || status.bloodPressureStatus == .high {
            pushAlert("🚨 تنبيه ضغط الدم: \(systolic)/\(diastolic) (\(statusArabic))", elderId: elderId)
        }
    }

    func publishFallDetected() {
        let elderId = resolveElderId()
        var status = currentStatus ?? ElderStatus.empty(elderId: elderId)
        status.updatedAt = Date()
        status.fallDetectedAt = Date()
        status.emergencyActive = true
        saveStatus(status)
        pushAlert("🆘 تم رصد سقوط محتمل", elderId: elderId)
    }

    func clearEmergency() {
        let elderId = resolveElderId()
        var status = currentStatus ?? ElderStatus.empty(elderId: elderId)
        status.updatedAt = Date()
        status.emergencyActive = false
        saveStatus(status)
    }
}
