//
//  Contact.swift
//  Sanad
//
//  Model for family contacts
//

import Foundation

/// نموذج جهة الاتصال - Contact Model
struct Contact: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var phoneNumber: String
    var relationship: String // مثل: ابن، ابنة، زوج، زوجة
    var isEmergencyContact: Bool
    var isFavorite: Bool // جهة اتصال مفضلة للاتصال السريع
    var photoData: Data? // صورة الشخص
    
    init(
        id: UUID = UUID(),
        name: String,
        phoneNumber: String,
        relationship: String,
        isEmergencyContact: Bool = false,
        isFavorite: Bool = false,
        photoData: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.relationship = relationship
        self.isEmergencyContact = isEmergencyContact
        self.isFavorite = isFavorite
        self.photoData = photoData
    }
}

// MARK: - Sample Data for Preview
extension Contact {
    static let sampleContacts: [Contact] = [
        Contact(
            name: "أحمد محمد",
            phoneNumber: "+966501234567",
            relationship: "ابن",
            isEmergencyContact: true,
            isFavorite: true
        ),
        Contact(
            name: "فاطمة أحمد",
            phoneNumber: "+966507654321",
            relationship: "ابنة",
            isEmergencyContact: true,
            isFavorite: true
        ),
        Contact(
            name: "سارة علي",
            phoneNumber: "+966509876543",
            relationship: "زوجة",
            isEmergencyContact: false,
            isFavorite: true
        ),
        Contact(
            name: "خالد عبدالله",
            phoneNumber: "+966505555555",
            relationship: "صديق",
            isEmergencyContact: false,
            isFavorite: false
        )
    ]
}
