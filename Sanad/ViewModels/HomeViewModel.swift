//
//  HomeViewModel.swift
//  Sanad
//
//  Enhanced ViewModel for home screen with error handling and validation
//

import Foundation
import Combine
import SwiftUI

/// نموذج عرض الشاشة الرئيسية - Home View Model
class HomeViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var emergencyContacts: [Contact] = []
    @Published var favoriteContacts: [Contact] = []
    @Published var isEmergencyActive: Bool = false
    @Published var showEmergencyAlert: Bool = false
    @Published var showFallAlert: Bool = false
    @Published var settings: AppSettings = .default
    
    // Sheet states
    @Published var showFavoritesSelection: Bool = false
    @Published var showLocationSharing: Bool = false
    @Published var showEmergencyOptions: Bool = false
    
    // Error handling
    @Published var currentError: SanadError?
    @Published var showError: Bool = false
    
    // Loading states
    @Published var isLoadingLocation: Bool = false
    @Published var isLoadingContacts: Bool = false
    @Published var isProcessingEmergency: Bool = false
    
    // MARK: - Private Properties
    
    private let storageManager = StorageManager.shared
    private let locationManager = LocationManager.shared
    private let emergencyManager = EnhancedEmergencyManager.shared
    private let fallDetectionManager = FallDetectionManager.shared
    private let voiceManager = EnhancedVoiceManager.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        loadData()
        setupObservers()
        setupServices()
    }
    
    deinit {
        // Clean up resources
        cancellables.removeAll()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup Methods
    
    /// تحميل البيانات - Load Data
    private func loadData() {
        isLoadingContacts = true
        
        do {
            emergencyContacts = storageManager.getEmergencyContacts()
            favoriteContacts = storageManager.getFavoriteContacts()
            settings = storageManager.loadSettings()
            isLoadingContacts = false
        } catch {
            handleError(.loadFailed)
            isLoadingContacts = false
        }
    }
    
    /// إعداد المراقبين - Setup Observers
    private func setupObservers() {
        // مراقبة حالة الطوارئ
        emergencyManager.$isEmergencyActive
            .receive(on: DispatchQueue.main)
            .assign(to: &$isEmergencyActive)
        
        // مراقبة كشف السقوط
        NotificationCenter.default.publisher(for: .fallDetected)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleFallDetection()
            }
            .store(in: &cancellables)
        
        // مراقبة الأوامر الصوتية
        NotificationCenter.default.publisher(for: .voiceCommandReceived)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let command = notification.object as? VoiceCommand {
                    self?.handleVoiceCommand(command)
                }
            }
            .store(in: &cancellables)
        
        // مراقبة الخروج من السياج الجغرافي
        NotificationCenter.default.publisher(for: .geofenceExited)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleGeofenceExit()
            }
            .store(in: &cancellables)
    }
    
    /// إعداد الخدمات - Setup Services
    private func setupServices() {
        // طلب الأذونات
        locationManager.requestPermission()
        EnhancedReminderManager.requestPermission { _ in }
        
        // بدء خدمات الموقع
        locationManager.startUpdatingLocation()
        
        // بدء كشف السقوط إذا كان مفعلاً
        if settings.fallDetectionEnabled {
            fallDetectionManager.startMonitoring()
        }
        
        // إعداد السياج الجغرافي إذا كان محدداً
        if let homeLocation = settings.homeLocation {
            locationManager.setupGeofence(
                center: homeLocation.coordinate,
                radius: settings.geofenceRadius
            )
        }
        
        // جدولة تذكيرات الأدوية
        EnhancedReminderManager.shared.scheduleAllMedicationReminders()
    }
    
    // MARK: - Action Methods
    
    /// الاتصال بالعائلة - Call Family
    func callFamily() {
        // Reload favorite contacts
        favoriteContacts = storageManager.getFavoriteContacts()
        
        // Check if there are favorite contacts
        guard !favoriteContacts.isEmpty else {
            handleError(.noFavoriteContacts)
            return
        }
        
        // Show favorites selection view
        HapticManager.selection()
        showFavoritesSelection = true
    }
    
    /// الاتصال بجهات الاتصال المحددة - Call Selected Contacts
    func callSelectedContacts(_ contacts: [Contact]) {
        guard !contacts.isEmpty else {
            handleError(.noFavoriteContacts)
            voiceManager.speak("لا توجد جهات اتصال محددة")
            return
        }
        
        // Validate phone numbers
        for contact in contacts {
            if !Validators.isValidSaudiPhone(contact.phoneNumber) {
                handleError(.invalidPhoneNumber)
                return
            }
        }
        
        // Call the first contact
        makePhoneCall(to: contacts[0])
        
        // Speak confirmation
        if contacts.count == 1 {
            voiceManager.speak("جاري الاتصال بـ \(contacts[0].name)")
        } else {
            voiceManager.speak("جاري الاتصال بـ \(contacts.count) من جهات الاتصال")
            
            // For multiple contacts, call them sequentially with delay
            for (index, contact) in contacts.enumerated() where index > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 2.0) { [weak self] in
                    self?.makePhoneCall(to: contact)
                }
            }
        }
    }
    
    /// إرسال الموقع - Send Location
    func sendLocation() {
        isLoadingLocation = true
        
        // Check location permission
        guard locationManager.authorizationStatus == .authorizedAlways ||
              locationManager.authorizationStatus == .authorizedWhenInUse else {
            handleError(.locationPermissionDenied)
            isLoadingLocation = false
            return
        }
        
        // Check if location is available
        guard locationManager.location != nil else {
            handleError(.locationUnavailable)
            voiceManager.speak("لا يمكن الحصول على الموقع")
            isLoadingLocation = false
            return
        }
        
        // Check if there are favorite contacts
        favoriteContacts = storageManager.getFavoriteContacts()
        guard !favoriteContacts.isEmpty else {
            handleError(.noFavoriteContacts)
            isLoadingLocation = false
            return
        }
        
        // Show location sharing options
        HapticManager.selection()
        showLocationSharing = true
        isLoadingLocation = false
    }
    
    /// الحصول على نص الموقع - Get Location Text
    func getLocationText() -> String {
        return locationManager.getLocationText() ?? "الموقع غير متوفر"
    }
    
    /// الحصول على رابط الموقع - Get Location Link
    func getLocationLink() -> String {
        return locationManager.getGoogleMapsLink() ?? ""
    }
    
    /// طلب المساعدة الطارئة - Request Emergency Help
    func requestEmergencyHelp() {
        // Check if there are emergency contacts
        emergencyContacts = storageManager.getEmergencyContacts()
        guard !emergencyContacts.isEmpty else {
            handleError(.noEmergencyContacts)
            return
        }
        
        // Show emergency options
        HapticManager.notification(.warning)
        showEmergencyOptions = true
    }
    
    /// تفعيل تنبيه الطوارئ التلقائي - Activate Automatic Emergency Alert
    func activateAutomaticEmergencyAlert() {
        isProcessingEmergency = true
        
        // Check emergency contacts
        guard !emergencyContacts.isEmpty else {
            handleError(.noEmergencyContacts)
            isProcessingEmergency = false
            return
        }
        
        HapticManager.notification(.warning)
        showEmergencyAlert = true
        emergencyManager.startEmergencyCheck(timeout: settings.emergencyTimeout)
        isProcessingEmergency = false
    }
    
    /// إلغاء الطوارئ - Cancel Emergency
    func cancelEmergency() {
        HapticManager.notification(.success)
        showEmergencyAlert = false
        emergencyManager.cancelEmergency()
        isProcessingEmergency = false
    }
    
    /// تأكيد الطوارئ - Confirm Emergency
    func confirmEmergency() {
        HapticManager.notification(.error)
        showEmergencyAlert = false
        emergencyManager.activateEmergencyNow()
        isProcessingEmergency = false
    }
    
    // MARK: - Fall Detection Methods
    
    /// معالجة كشف السقوط - Handle Fall Detection
    private func handleFallDetection() {
        HapticManager.notification(.error)
        showFallAlert = true
        voiceManager.speak("هل أنت بخير؟")
    }
    
    /// الرد على تنبيه السقوط - Respond to Fall Alert
    func respondToFallAlert(isOkay: Bool) {
        showFallAlert = false
        
        if isOkay {
            HapticManager.notification(.success)
            emergencyManager.cancelEmergency()
            voiceManager.speak("الحمد لله على سلامتك")
        } else {
            HapticManager.notification(.error)
            emergencyManager.activateEmergencyNow()
        }
    }
    
    /// معالجة الخروج من السياج الجغرافي - Handle Geofence Exit
    private func handleGeofenceExit() {
        // Notify emergency contacts
        voiceManager.speak("تم الخروج من المنطقة المحددة")
        // Emergency manager will handle notifications
    }
    
    // MARK: - Voice Command Methods
    
    /// معالجة الأمر الصوتي - Handle Voice Command
    private func handleVoiceCommand(_ command: VoiceCommand) {
        HapticManager.selection()
        
        switch command {
        case .callFamily, .callSon, .callDaughter:
            callFamily()
        case .sendLocation:
            sendLocation()
        case .emergency:
            requestEmergencyHelp()
        case .showMedications:
            // سيتم التعامل معه في الواجهة
            break
        }
    }
    
    /// بدء الاستماع للأوامر الصوتية - Start Listening for Voice Commands
    func startVoiceListening() {
        guard settings.voiceCommandsEnabled else {
            handleError(.featureDisabled("الأوامر الصوتية"))
            voiceManager.speak("الأوامر الصوتية غير مفعلة")
            return
        }
        
        do {
            try voiceManager.startListening()
            HapticManager.impact(.light)
        } catch {
            handleError(.voiceRecognitionFailed)
            voiceManager.speak("عذراً، لا يمكن تفعيل الأوامر الصوتية")
        }
    }
    
    /// إيقاف الاستماع - Stop Listening
    func stopVoiceListening() {
        voiceManager.stopListening()
        HapticManager.selection()
    }
    
    // MARK: - Phone Call Methods
    
    /// إجراء مكالمة هاتفية - Make Phone Call
    private func makePhoneCall(to contact: Contact) {
        // Validate phone number
        guard Validators.isValidSaudiPhone(contact.phoneNumber) else {
            handleError(.invalidPhoneNumber)
            return
        }
        
        let phoneNumber = Validators.formatSaudiPhone(contact.phoneNumber)
        
        guard let url = URL(string: "tel://\(phoneNumber)"),
              UIApplication.shared.canOpenURL(url) else {
            handleError(.phoneCallFailed)
            voiceManager.speak("لا يمكن إجراء المكالمة")
            return
        }
        
        HapticManager.impact(.medium)
        UIApplication.shared.open(url)
        voiceManager.speak("جاري الاتصال بـ \(contact.name)")
    }
    
    // MARK: - Error Handling
    
    /// معالجة الأخطاء - Handle Errors
    private func handleError(_ error: SanadError) {
        currentError = error
        showError = true
        HapticManager.notification(.error)
        
        // Log error for debugging
        print("❌ Error: \(error.errorDescription ?? "Unknown error")")
        
        // Speak error message for accessibility
        if let message = error.errorDescription {
            voiceManager.speak(message)
        }
    }
    
    /// مسح الخطأ - Clear Error
    func clearError() {
        currentError = nil
        showError = false
    }
    
    /// إعادة المحاولة - Retry Last Action
    func retryLastAction() {
        clearError()
        // Implement retry logic based on last action
    }
    
    // MARK: - Refresh Data
    
    /// تحديث البيانات - Refresh Data
    func refreshData() {
        loadData()
        HapticManager.impact(.light)
    }
}
