//
//  FamilyLinkManager.swift
//  Sanad
//
//  Option B secure linking flow:
//  - 6-digit code
//  - 10-minute expiry
//  - one-time use
//  - failed-attempt lock
//  - father approval required
//

import Foundation
import Combine

final class FamilyLinkManager: ObservableObject {
    static let shared = FamilyLinkManager()

    @Published private(set) var currentLink: FamilyLink?
    @Published private(set) var pendingFamilyId: String?
    @Published private(set) var pendingRequestedAt: Date?
    @Published private(set) var failedAttempts: Int = 0
    @Published private(set) var isLocked: Bool = false
    @Published var lastError: String?

    private let linkStorageKey = "family_link_record"
    private let pendingFamilyIdKey = "family_link_pending_family_id"
    private let pendingRequestedAtKey = "family_link_pending_requested_at"
    private let failedAttemptsKey = "family_link_failed_attempts"
    private let lockKey = "family_link_is_locked"

    private let maxAttempts = 5

    private init() {
        loadState()
    }

    // MARK: - Elder side (generate code)

    @discardableResult
    func generateInviteCode(forElderId elderId: String) -> FamilyLink {
        resetSecurityState()

        var code = String(format: "%06d", Int.random(in: 0...999999))
        if currentLink?.inviteCode == code {
            code = String(format: "%06d", Int.random(in: 0...999999))
        }

        let link = FamilyLink(
            elderId: elderId,
            inviteCode: code,
            createdAt: Date(),
            expiresAt: Calendar.current.date(byAdding: .minute, value: 10, to: Date()) ?? Date(),
            linkedFamilyId: nil,
            linkedAt: nil,
            status: .pending
        )

        currentLink = link
        saveLink(link)

        ActivityLogger.shared.log(
            type: .familyLinkCodeGenerated,
            title: "إنشاء رمز ربط",
            description: "تم إنشاء رمز ربط جديد صالح لمدة 10 دقائق",
            severity: .medium,
            metadata: ["invite_code": code]
        )

        return link
    }

    // MARK: - Family side (submit code)

    /// Step 1: family submits code -> pending approval on father side
    @discardableResult
    func requestJoinWithCode(_ code: String, familyId: String) -> Bool {
        guard !isLocked else {
            lastError = "تم قفل الربط مؤقتاً بسبب كثرة المحاولات."
            return false
        }

        guard var link = currentLink else {
            lastError = "لا يوجد رمز ربط متاح حالياً."
            return false
        }

        if link.status == .linked || link.status == .revoked {
            lastError = "هذا الرمز مستخدم مسبقاً أو ملغي."
            return false
        }

        if link.isExpired {
            link.status = .expired
            currentLink = link
            saveLink(link)
            lastError = "انتهت صلاحية رمز الربط."
            return false
        }

        guard link.inviteCode == code else {
            registerFailedAttempt(enteredCode: code)
            return false
        }

        // Valid code -> wait father approval
        pendingFamilyId = familyId
        pendingRequestedAt = Date()
        savePendingRequest()

        failedAttempts = 0
        isLocked = false
        saveSecurityState()
        lastError = nil

        ActivityLogger.shared.log(
            type: .familyLinked,
            title: "طلب ربط جديد",
            description: "تم إرسال طلب ربط وينتظر موافقة الأب",
            severity: .medium,
            metadata: ["family_id": familyId]
        )

        return true
    }

    // MARK: - Father approval

    /// Step 2: father approves pending request -> link becomes active
    @discardableResult
    func approvePendingJoin() -> Bool {
        guard var link = currentLink else {
            lastError = "لا يوجد ربط قيد الانتظار."
            return false
        }

        guard let familyId = pendingFamilyId else {
            lastError = "لا يوجد طلب ربط للموافقة."
            return false
        }

        if link.isExpired {
            link.status = .expired
            currentLink = link
            saveLink(link)
            clearPendingRequest()
            lastError = "انتهت صلاحية الرمز قبل الموافقة."
            return false
        }

        link.linkedFamilyId = familyId
        link.linkedAt = Date()
        link.status = .linked
        currentLink = link
        saveLink(link)
        clearPendingRequest()

        ActivityLogger.shared.log(
            type: .familyLinked,
            title: "تم ربط العائلة",
            description: "تمت الموافقة على ربط فرد من العائلة",
            severity: .low,
            metadata: ["family_id": familyId]
        )

        return true
    }

    func rejectPendingJoin() {
        guard pendingFamilyId != nil else { return }
        clearPendingRequest()

        ActivityLogger.shared.log(
            type: .familyLinkFailedAttempt,
            title: "رفض طلب ربط",
            description: "تم رفض طلب الربط من جهة الأب",
            severity: .medium
        )
    }

    func revokeLink() {
        guard var link = currentLink else { return }
        link.status = .revoked
        currentLink = link
        saveLink(link)
        clearPendingRequest()

        ActivityLogger.shared.log(
            type: .familyLinkRevoked,
            title: "إلغاء الربط",
            description: "تم إلغاء ربط العائلة",
            severity: .medium
        )
    }

    // MARK: - Helpers

    var hasPendingApproval: Bool {
        pendingFamilyId != nil
    }

    var remainingAttempts: Int {
        max(0, maxAttempts - failedAttempts)
    }

    // MARK: - Persistence

    private func registerFailedAttempt(enteredCode: String) {
        failedAttempts += 1
        if failedAttempts >= maxAttempts {
            isLocked = true
        }
        saveSecurityState()

        lastError = isLocked
            ? "تم قفل الربط بعد \(maxAttempts) محاولات فاشلة."
            : "رمز الربط غير صحيح. المحاولات المتبقية: \(remainingAttempts)"

        ActivityLogger.shared.log(
            type: .familyLinkFailedAttempt,
            title: "محاولة ربط فاشلة",
            description: "تم إدخال رمز ربط غير صحيح",
            severity: .high,
            metadata: [
                "entered_code": enteredCode,
                "failed_attempts": "\(failedAttempts)"
            ]
        )
    }

    private func resetSecurityState() {
        failedAttempts = 0
        isLocked = false
        saveSecurityState()
        clearPendingRequest()
    }

    private func saveLink(_ link: FamilyLink) {
        guard let data = try? JSONEncoder().encode(link) else { return }
        UserDefaults.standard.set(data, forKey: linkStorageKey)
    }

    private func savePendingRequest() {
        UserDefaults.standard.set(pendingFamilyId, forKey: pendingFamilyIdKey)
        UserDefaults.standard.set(pendingRequestedAt, forKey: pendingRequestedAtKey)
    }

    private func clearPendingRequest() {
        pendingFamilyId = nil
        pendingRequestedAt = nil
        UserDefaults.standard.removeObject(forKey: pendingFamilyIdKey)
        UserDefaults.standard.removeObject(forKey: pendingRequestedAtKey)
    }

    private func saveSecurityState() {
        UserDefaults.standard.set(failedAttempts, forKey: failedAttemptsKey)
        UserDefaults.standard.set(isLocked, forKey: lockKey)
    }

    private func loadState() {
        if let data = UserDefaults.standard.data(forKey: linkStorageKey),
           let link = try? JSONDecoder().decode(FamilyLink.self, from: data) {
            currentLink = link
        }

        pendingFamilyId = UserDefaults.standard.string(forKey: pendingFamilyIdKey)
        pendingRequestedAt = UserDefaults.standard.object(forKey: pendingRequestedAtKey) as? Date
        failedAttempts = UserDefaults.standard.integer(forKey: failedAttemptsKey)
        isLocked = UserDefaults.standard.bool(forKey: lockKey)
    }
}
