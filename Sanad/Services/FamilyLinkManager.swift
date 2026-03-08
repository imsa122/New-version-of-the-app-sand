//
//  FamilyLinkManager.swift
//  Sanad
//
//  Handles Option B linking flow (6-digit invite code)
//

import Foundation
import Combine

final class FamilyLinkManager: ObservableObject {
    static let shared = FamilyLinkManager()

    @Published private(set) var currentLink: FamilyLink?
    @Published var lastError: String?

    private let storage = StorageManager.shared
    private let linkStorageKey = "family_link_record"

    private init() {
        loadLink()
    }

    // MARK: - Elder side

    @discardableResult
    func generateInviteCode(forElderId elderId: String) -> FamilyLink {
        var code = String(format: "%06d", Int.random(in: 0...999999))

        // Ensure a fresh code if old one exists with same code
        if currentLink?.inviteCode == code {
            code = String(format: "%06d", Int.random(in: 0...999999))
        }

        let link = FamilyLink(
            elderId: elderId,
            inviteCode: code,
            createdAt: Date(),
            expiresAt: Calendar.current.date(byAdding: .hour, value: 24, to: Date()) ?? Date(),
            linkedFamilyId: nil,
            linkedAt: nil,
            status: .pending
        )

        currentLink = link
        saveLink(link)

        ActivityLogger.shared.log(
            type: .familyLinkCodeGenerated,
            title: "إنشاء رمز ربط",
            description: "تم إنشاء رمز ربط جديد للعائلة",
            severity: .medium,
            metadata: ["invite_code": code]
        )

        return link
    }

    // MARK: - Family side

    @discardableResult
    func joinWithCode(_ code: String, familyId: String) -> Bool {
        guard var link = currentLink else {
            lastError = "لا يوجد رمز ربط متاح حالياً."
            return false
        }

        guard !link.isExpired else {
            link.status = .expired
            currentLink = link
            saveLink(link)
            lastError = "انتهت صلاحية رمز الربط."
            return false
        }

        guard link.inviteCode == code else {
            lastError = "رمز الربط غير صحيح."
            ActivityLogger.shared.log(
                type: .familyLinkFailedAttempt,
                title: "محاولة ربط فاشلة",
                description: "تم إدخال رمز ربط غير صحيح",
                severity: .high,
                metadata: ["entered_code": code]
            )
            return false
        }

        link.linkedFamilyId = familyId
        link.linkedAt = Date()
        link.status = .linked
        currentLink = link
        saveLink(link)
        lastError = nil

        ActivityLogger.shared.log(
            type: .familyLinked,
            title: "تم ربط العائلة",
            description: "تم ربط أحد أفراد العائلة بنجاح",
            severity: .low,
            metadata: ["family_id": familyId]
        )

        return true
    }

    func revokeLink() {
        guard var link = currentLink else { return }
        link.status = .revoked
        currentLink = link
        saveLink(link)

        ActivityLogger.shared.log(
            type: .familyLinkRevoked,
            title: "إلغاء الربط",
            description: "تم إلغاء ربط العائلة",
            severity: .medium
        )
    }

    // MARK: - Persistence

    private func saveLink(_ link: FamilyLink) {
        guard let data = try? JSONEncoder().encode(link) else { return }
        UserDefaults.standard.set(data, forKey: linkStorageKey)
    }

    private func loadLink() {
        guard
            let data = UserDefaults.standard.data(forKey: linkStorageKey),
            let link = try? JSONDecoder().decode(FamilyLink.self, from: data)
        else { return }

        currentLink = link
    }
}
