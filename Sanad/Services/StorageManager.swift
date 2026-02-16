//
//  StorageManager.swift
//  Sanad
//
//  Manages data persistence using UserDefaults
//

import Foundation

/// مدير التخزين - Storage Manager
class StorageManager {
    
    static let shared = StorageManager()
    
    private let defaults = UserDefaults.standard
    
    // مفاتيح التخزين - Storage Keys
    private enum Keys {
        static let contacts = "sanad_contacts"
        static let medications = "sanad_medications"
        static let settings = "sanad_settings"
    }
    
    private init() {}
    
    // MARK: - Contacts Management
    
    /// حفظ جهات الاتصال - Save Contacts
    func saveContacts(_ contacts: [Contact]) {
        if let encoded = try? JSONEncoder().encode(contacts) {
            defaults.set(encoded, forKey: Keys.contacts)
        }
    }
    
    /// تحميل جهات الاتصال - Load Contacts
    func loadContacts() -> [Contact] {
        guard let data = defaults.data(forKey: Keys.contacts),
              let contacts = try? JSONDecoder().decode([Contact].self, from: data) else {
            return []
        }
        return contacts
    }
    
    /// إضافة جهة اتصال - Add Contact
    func addContact(_ contact: Contact) {
        var contacts = loadContacts()
        contacts.append(contact)
        saveContacts(contacts)
    }
    
    /// تحديث جهة اتصال - Update Contact
    func updateContact(_ contact: Contact) {
        var contacts = loadContacts()
        if let index = contacts.firstIndex(where: { $0.id == contact.id }) {
            contacts[index] = contact
            saveContacts(contacts)
        }
    }
    
    /// حذف جهة اتصال - Delete Contact
    func deleteContact(_ contact: Contact) {
        var contacts = loadContacts()
        contacts.removeAll { $0.id == contact.id }
        saveContacts(contacts)
    }
    
    /// الحصول على جهات الاتصال الطارئة - Get Emergency Contacts
    func getEmergencyContacts() -> [Contact] {
        return loadContacts().filter { $0.isEmergencyContact }
    }
    
    /// الحصول على جهات الاتصال المفضلة - Get Favorite Contacts
    func getFavoriteContacts() -> [Contact] {
        return loadContacts().filter { $0.isFavorite }
    }
    
    /// تبديل حالة المفضلة لجهة اتصال - Toggle Favorite Status
    func toggleFavoriteContact(_ contact: Contact) {
        var updatedContact = contact
        updatedContact.isFavorite.toggle()
        updateContact(updatedContact)
    }
    
    // MARK: - Medications Management
    
    /// حفظ الأدوية - Save Medications
    func saveMedications(_ medications: [Medication]) {
        if let encoded = try? JSONEncoder().encode(medications) {
            defaults.set(encoded, forKey: Keys.medications)
        }
    }
    
    /// تحميل الأدوية - Load Medications
    func loadMedications() -> [Medication] {
        guard let data = defaults.data(forKey: Keys.medications),
              let medications = try? JSONDecoder().decode([Medication].self, from: data) else {
            return []
        }
        return medications
    }
    
    /// إضافة دواء - Add Medication
    func addMedication(_ medication: Medication) {
        var medications = loadMedications()
        medications.append(medication)
        saveMedications(medications)
    }
    
    /// تحديث دواء - Update Medication
    func updateMedication(_ medication: Medication) {
        var medications = loadMedications()
        if let index = medications.firstIndex(where: { $0.id == medication.id }) {
            medications[index] = medication
            saveMedications(medications)
        }
    }
    
    /// حذف دواء - Delete Medication
    func deleteMedication(_ medication: Medication) {
        var medications = loadMedications()
        medications.removeAll { $0.id == medication.id }
        saveMedications(medications)
    }
    
    /// الحصول على الأدوية النشطة - Get Active Medications
    func getActiveMedications() -> [Medication] {
        return loadMedications().filter { $0.isActive }
    }
    
    // MARK: - Settings Management
    
    /// حفظ الإعدادات - Save Settings
    func saveSettings(_ settings: AppSettings) {
        if let encoded = try? JSONEncoder().encode(settings) {
            defaults.set(encoded, forKey: Keys.settings)
        }
    }
    
    /// تحميل الإعدادات - Load Settings
    func loadSettings() -> AppSettings {
        guard let data = defaults.data(forKey: Keys.settings),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return AppSettings.default
        }
        return settings
    }
    
    /// تحديث حجم الخط - Update Font Size
    func updateFontSize(_ fontSize: FontSize) {
        var settings = loadSettings()
        settings.fontSize = fontSize
        saveSettings(settings)
    }
    
    /// تحديث موقع المنزل - Update Home Location
    func updateHomeLocation(_ location: HomeLocation?) {
        var settings = loadSettings()
        settings.homeLocation = location
        saveSettings(settings)
    }
    
    /// تحديث نطاق السياج الجغرافي - Update Geofence Radius
    func updateGeofenceRadius(_ radius: Double) {
        var settings = loadSettings()
        settings.geofenceRadius = radius
        saveSettings(settings)
    }
    
    /// تحديث حالة كشف السقوط - Update Fall Detection Status
    func updateFallDetection(_ enabled: Bool) {
        var settings = loadSettings()
        settings.fallDetectionEnabled = enabled
        saveSettings(settings)
    }
    
    /// تحديث حالة الأوامر الصوتية - Update Voice Commands Status
    func updateVoiceCommands(_ enabled: Bool) {
        var settings = loadSettings()
        settings.voiceCommandsEnabled = enabled
        saveSettings(settings)
    }
    
    // MARK: - Clear All Data
    
    /// مسح جميع البيانات - Clear All Data
    func clearAllData() {
        defaults.removeObject(forKey: Keys.contacts)
        defaults.removeObject(forKey: Keys.medications)
        defaults.removeObject(forKey: Keys.settings)
    }
}
