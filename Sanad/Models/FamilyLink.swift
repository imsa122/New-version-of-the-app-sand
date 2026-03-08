//
//  FamilyLink.swift
//  Sanad
//
//  Family linking model (Option B: 6-digit invite code)
//

import Foundation

struct FamilyLink: Codable, Identifiable, Equatable {
    let id: UUID
    let elderId: String
    let inviteCode: String
    let createdAt: Date
    var expiresAt: Date
    var linkedFamilyId: String?
    var linkedAt: Date?
    var status: LinkStatus

    init(
        id: UUID = UUID(),
        elderId: String,
        inviteCode: String,
        createdAt: Date = Date(),
        expiresAt: Date = Calendar.current.date(byAdding: .hour, value: 24, to: Date()) ?? Date(),
        linkedFamilyId: String? = nil,
        linkedAt: Date? = nil,
        status: LinkStatus = .pending
    ) {
        self.id = id
        self.elderId = elderId
        self.inviteCode = inviteCode
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.linkedFamilyId = linkedFamilyId
        self.linkedAt = linkedAt
        self.status = status
    }

    var isExpired: Bool {
        Date() > expiresAt
    }

    var isActive: Bool {
        status == .linked && !isExpired
    }
}

enum LinkStatus: String, Codable, CaseIterable {
    case pending
    case linked
    case expired
    case revoked

    var displayNameArabic: String {
        switch self {
        case .pending: return "بانتظار الربط"
        case .linked: return "مرتبط"
        case .expired: return "منتهي الصلاحية"
        case .revoked: return "ملغي"
        }
    }
}
