import Foundation
import Combine

final class FamilyDashboardViewModel: ObservableObject {
    @Published var status: ElderStatus?
    @Published var alerts: [String] = []
    @Published var isLinked: Bool = false

    @Published var inviteCode: String?
    @Published var expiresAt: Date?
    @Published var enteredCode: String = ""
    @Published var infoMessage: String?
    @Published var errorMessage: String?

    @Published var pendingFamilyId: String?
    @Published var hasPendingApproval: Bool = false
    @Published var remainingAttempts: Int = 5
    @Published var isLocked: Bool = false

    private let syncService = ElderStatusSyncService.shared
    private let linkManager = FamilyLinkManager.shared

    private var cancellables: Set<AnyCancellable> = []

    init() {
        bindLinkManager()
    }

    private func bindLinkManager() {
        linkManager.$currentLink
            .receive(on: DispatchQueue.main)
            .sink { [weak self] link in
                self?.inviteCode = link?.inviteCode
                self?.expiresAt = link?.expiresAt
                self?.isLinked = (link?.status == .linked)
            }
            .store(in: &cancellables)

        linkManager.$pendingFamilyId
            .receive(on: DispatchQueue.main)
            .sink { [weak self] familyId in
                self?.pendingFamilyId = familyId
                self?.hasPendingApproval = (familyId != nil)
            }
            .store(in: &cancellables)

        linkManager.$lastError
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.errorMessage = error
            }
            .store(in: &cancellables)

        linkManager.$failedAttempts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.remainingAttempts = self?.linkManager.remainingAttempts ?? 0
            }
            .store(in: &cancellables)

        linkManager.$isLocked
            .receive(on: DispatchQueue.main)
            .sink { [weak self] locked in
                self?.isLocked = locked
            }
            .store(in: &cancellables)
    }

    func load() {
        let settings = StorageManager.shared.loadSettings()

        if let linkedElderId = settings.linkedElderId, !linkedElderId.isEmpty {
            syncService.loadStatus(for: linkedElderId)
            syncService.loadAlertFeed(for: linkedElderId)
            status = syncService.currentStatus
            alerts = syncService.alertFeed
        } else {
            status = nil
            alerts = []
        }

        let link = linkManager.currentLink
        inviteCode = link?.inviteCode
        expiresAt = link?.expiresAt
        isLinked = (link?.status == .linked)
        pendingFamilyId = linkManager.pendingFamilyId
        hasPendingApproval = linkManager.hasPendingApproval
        remainingAttempts = linkManager.remainingAttempts
        isLocked = linkManager.isLocked
    }

    // MARK: - Role actions

    func generateFatherCode() {
        var settings = StorageManager.shared.loadSettings()
        settings.userMode = .elder

        let elderId = ElderStatusSyncService.shared.currentDeviceId()
        settings.linkedElderId = elderId
        settings.lastLinkDate = Date()
        StorageManager.shared.saveSettings(settings)

        let link = linkManager.generateInviteCode(forElderId: elderId)
        inviteCode = link.inviteCode
        expiresAt = link.expiresAt
        infoMessage = "تم إنشاء الرمز بنجاح. شاركه مع أحد أفراد العائلة."
        errorMessage = nil
    }

    func submitFamilyCode() {
        guard enteredCode.count == 6 else {
            errorMessage = "الرجاء إدخال رمز من 6 أرقام."
            return
        }

        var settings = StorageManager.shared.loadSettings()
        settings.userMode = .family
        let familyId = "family-" + UUID().uuidString.prefix(8)
        let ok = linkManager.requestJoinWithCode(enteredCode, familyId: String(familyId))

        if ok {
            if let elderId = linkManager.currentLink?.elderId {
                settings.linkedElderId = elderId
                settings.lastLinkDate = Date()
            }
            StorageManager.shared.saveSettings(settings)
            infoMessage = "تم إرسال طلب الربط. يرجى موافقة الأب."
            errorMessage = nil
        } else {
            errorMessage = linkManager.lastError
        }
    }

    func approvePendingRequest() {
        guard linkManager.approvePendingJoin() else {
            errorMessage = linkManager.lastError
            return
        }

        if let elderId = linkManager.currentLink?.elderId {
            var settings = StorageManager.shared.loadSettings()
            settings.linkedElderId = elderId
            settings.lastLinkDate = Date()
            StorageManager.shared.saveSettings(settings)
        }

        infoMessage = "تمت الموافقة على الربط بنجاح."
        errorMessage = nil
        refresh()
    }

    func rejectPendingRequest() {
        linkManager.rejectPendingJoin()
        infoMessage = "تم رفض طلب الربط."
        errorMessage = nil
        refresh()
    }

    func refresh() {
        load()
    }

    // MARK: - Display helpers

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
