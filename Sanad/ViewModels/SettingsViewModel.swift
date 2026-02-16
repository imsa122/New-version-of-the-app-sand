//
//  SettingsViewModel.swift
//  Sanad
//
//  ViewModel for settings screen
//

import Foundation
import Combine
import CoreLocation

/// نموذج عرض الإعدادات - Settings View Model
class SettingsViewModel: ObservableObject {
    
    @Published var settings: AppSettings
    @Published var contacts: [Contact] = []
    @Published var emergencyContacts: [Contact] = []
    
    private let storageManager = StorageManager.shared
    private let locationManager = LocationManager.shared
    private let fallDetectionManager = FallDetectionManager.shared
    
    init() {
        self.settings = storageManager.loadSettings()
        loadContacts()
    }
    
    // MARK: - Load Data
    
    /// تحميل جهات الاتصال - Load Contacts
    func loadContacts() {
        contacts = storageManager.loadContacts()
        emergencyContacts = contacts.filter { $0.isEmergencyContact }
    }
    
    // MARK: - Font Size
    
    /// تحديث حجم الخط - Update Font Size
    func updateFontSize(_ fontSize: FontSize) {
        settings.fontSize = fontSize
        storageManager.updateFontSize(fontSize)
    }
    
    // MARK: - Home Location
    
    /// تعيين موقع المنزل - Set Home Location
    func setHomeLocation(coordinate: CLLocationCoordinate2D, address: String?) {
        let homeLocation = HomeLocation(coordinate: coordinate, address: address)
        settings.homeLocation = homeLocation
        storageManager.updateHomeLocation(homeLocation)
        
        // تحديث السياج الجغرافي
        locationManager.setupGeofence(
            center: coordinate,
            radius: settings.geofenceRadius
        )
    }
    
    /// استخدام الموقع الحالي كمنزل - Use Current Location as Home
    func useCurrentLocationAsHome() {
        guard let location = locationManager.location else { return }
        
        setHomeLocation(
            coordinate: location.coordinate,
            address: "الموقع الحالي"
        )
    }
    
    /// إزالة موقع المنزل - Remove Home Location
    func removeHomeLocation() {
        settings.homeLocation = nil
        storageManager.updateHomeLocation(nil)
        locationManager.removeGeofence()
    }
    
    // MARK: - Geofence Radius
    
    /// تحديث نطاق السياج الجغرافي - Update Geofence Radius
    func updateGeofenceRadius(_ radius: Double) {
        settings.geofenceRadius = radius
        storageManager.updateGeofenceRadius(radius)
        
        // تحديث السياج إذا كان موقع المنزل محدداً
        if let homeLocation = settings.homeLocation {
            locationManager.setupGeofence(
                center: homeLocation.coordinate,
                radius: radius
            )
        }
    }
    
    // MARK: - Fall Detection
    
    /// تبديل كشف السقوط - Toggle Fall Detection
    func toggleFallDetection(_ enabled: Bool) {
        settings.fallDetectionEnabled = enabled
        storageManager.updateFallDetection(enabled)
        
        if enabled {
            fallDetectionManager.startMonitoring()
        } else {
            fallDetectionManager.stopMonitoring()
        }
    }
    
    // MARK: - Voice Commands
    
    /// تبديل الأوامر الصوتية - Toggle Voice Commands
    func toggleVoiceCommands(_ enabled: Bool) {
        settings.voiceCommandsEnabled = enabled
        storageManager.updateVoiceCommands(enabled)
    }
    
    // MARK: - Emergency Timeout
    
    /// تحديث مهلة الطوارئ - Update Emergency Timeout
    func updateEmergencyTimeout(_ timeout: Int) {
        settings.emergencyTimeout = timeout
        storageManager.saveSettings(settings)
    }
    
    // MARK: - Contacts Management
    
    /// إضافة جهة اتصال - Add Contact
    func addContact(_ contact: Contact) {
        storageManager.addContact(contact)
        loadContacts()
    }
    
    /// تحديث جهة اتصال - Update Contact
    func updateContact(_ contact: Contact) {
        storageManager.updateContact(contact)
        loadContacts()
    }
    
    /// حذف جهة اتصال - Delete Contact
    func deleteContact(_ contact: Contact) {
        storageManager.deleteContact(contact)
        loadContacts()
    }
    
    /// تبديل حالة جهة اتصال طارئة - Toggle Emergency Contact
    func toggleEmergencyContact(_ contact: Contact) {
        var updatedContact = contact
        updatedContact.isEmergencyContact.toggle()
        updateContact(updatedContact)
    }
    
    /// تبديل حالة جهة اتصال مفضلة - Toggle Favorite Contact
    func toggleFavoriteContact(_ contact: Contact) {
        storageManager.toggleFavoriteContact(contact)
        loadContacts()
    }
    
    // MARK: - Reset Settings
    
    /// إعادة تعيين الإعدادات - Reset Settings
    func resetSettings() {
        settings = .default
        storageManager.saveSettings(settings)
        
        // إعادة تطبيق الإعدادات
        locationManager.removeGeofence()
        fallDetectionManager.stopMonitoring()
    }
    
    /// مسح جميع البيانات - Clear All Data
    func clearAllData() {
        storageManager.clearAllData()
        settings = .default
        contacts = []
        emergencyContacts = []
        
        locationManager.removeGeofence()
        fallDetectionManager.stopMonitoring()
        EnhancedReminderManager.shared.cancelAllReminders()
    }
}
