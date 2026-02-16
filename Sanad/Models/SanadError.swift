//
//  SanadError.swift
//  Sanad
//
//  Comprehensive error handling for the app
//

import Foundation

/// أخطاء تطبيق سند - Sanad App Errors
enum SanadError: LocalizedError {
    // Location Errors
    case locationUnavailable
    case locationPermissionDenied
    case locationServiceDisabled
    case geofenceSetupFailed
    
    // Contact Errors
    case noContacts
    case noEmergencyContacts
    case noFavoriteContacts
    case invalidPhoneNumber
    case invalidContactName
    case contactNotFound
    case duplicateContact
    
    // Emergency Errors
    case emergencyActivationFailed
    case phoneCallFailed
    case smsFailedToSend
    case whatsappNotInstalled
    
    // Medication Errors
    case noMedications
    case invalidMedicationName
    case invalidDosage
    case invalidTime
    case notificationPermissionDenied
    case medicationNotFound
    
    // Voice Errors
    case voiceRecognitionFailed
    case microphonePermissionDenied
    case speechRecognitionNotAvailable
    case voiceCommandNotRecognized
    
    // Storage Errors
    case storageError
    case dataCorrupted
    case encryptionFailed
    case decryptionFailed
    case saveFailed
    case loadFailed
    
    // Network Errors
    case networkUnavailable
    case requestTimeout
    
    // General Errors
    case invalidInput(String)
    case operationCancelled
    case permissionRequired(String)
    case featureDisabled(String)
    case unknownError
    
    var errorDescription: String? {
        switch self {
        // Location Errors
        case .locationUnavailable:
            return "لا يمكن الحصول على الموقع الحالي. تأكد من تفعيل خدمات الموقع."
        case .locationPermissionDenied:
            return "تم رفض إذن الموقع. يرجى تفعيله من الإعدادات."
        case .locationServiceDisabled:
            return "خدمات الموقع معطلة. يرجى تفعيلها من إعدادات الجهاز."
        case .geofenceSetupFailed:
            return "فشل إعداد السياج الجغرافي. حاول مرة أخرى."
            
        // Contact Errors
        case .noContacts:
            return "لا توجد جهات اتصال. يرجى إضافة جهات اتصال أولاً."
        case .noEmergencyContacts:
            return "لم يتم تحديد جهات اتصال طارئة. يرجى تحديدها من الإعدادات."
        case .noFavoriteContacts:
            return "لا توجد جهات اتصال مفضلة. يرجى تحديدها من الإعدادات."
        case .invalidPhoneNumber:
            return "رقم الهاتف غير صحيح. يرجى إدخال رقم سعودي صحيح (05XXXXXXXX)."
        case .invalidContactName:
            return "اسم جهة الاتصال غير صحيح. يجب أن يكون بين 2-50 حرف."
        case .contactNotFound:
            return "جهة الاتصال غير موجودة."
        case .duplicateContact:
            return "جهة الاتصال موجودة مسبقاً."
            
        // Emergency Errors
        case .emergencyActivationFailed:
            return "فشل تفعيل الطوارئ. حاول مرة أخرى."
        case .phoneCallFailed:
            return "فشل إجراء المكالمة. تأكد من صحة رقم الهاتف."
        case .smsFailedToSend:
            return "فشل إرسال الرسالة. حاول مرة أخرى."
        case .whatsappNotInstalled:
            return "تطبيق واتساب غير مثبت على الجهاز."
            
        // Medication Errors
        case .noMedications:
            return "لا توجد أدوية مضافة. يرجى إضافة أدوية أولاً."
        case .invalidMedicationName:
            return "اسم الدواء غير صحيح. يجب أن يكون بين 2-100 حرف."
        case .invalidDosage:
            return "الجرعة غير صحيحة. يرجى إدخال جرعة صحيحة."
        case .invalidTime:
            return "الوقت غير صحيح. يرجى اختيار وقت صحيح."
        case .notificationPermissionDenied:
            return "تم رفض إذن الإشعارات. يرجى تفعيله من الإعدادات."
        case .medicationNotFound:
            return "الدواء غير موجود."
            
        // Voice Errors
        case .voiceRecognitionFailed:
            return "فشل التعرف على الصوت. حاول مرة أخرى وتحدث بوضوح."
        case .microphonePermissionDenied:
            return "تم رفض إذن الميكروفون. يرجى تفعيله من الإعدادات."
        case .speechRecognitionNotAvailable:
            return "التعرف على الصوت غير متاح حالياً."
        case .voiceCommandNotRecognized:
            return "لم يتم التعرف على الأمر الصوتي. حاول مرة أخرى."
            
        // Storage Errors
        case .storageError:
            return "خطأ في حفظ البيانات. حاول مرة أخرى."
        case .dataCorrupted:
            return "البيانات تالفة. قد تحتاج لإعادة تعيين التطبيق."
        case .encryptionFailed:
            return "فشل تشفير البيانات."
        case .decryptionFailed:
            return "فشل فك تشفير البيانات."
        case .saveFailed:
            return "فشل حفظ البيانات. تأكد من وجود مساحة كافية."
        case .loadFailed:
            return "فشل تحميل البيانات."
            
        // Network Errors
        case .networkUnavailable:
            return "لا يوجد اتصال بالإنترنت."
        case .requestTimeout:
            return "انتهت مهلة الطلب. حاول مرة أخرى."
            
        // General Errors
        case .invalidInput(let message):
            return message
        case .operationCancelled:
            return "تم إلغاء العملية."
        case .permissionRequired(let permission):
            return "يتطلب إذن \(permission) لإتمام هذه العملية."
        case .featureDisabled(let feature):
            return "ميزة \(feature) معطلة. يرجى تفعيلها من الإعدادات."
        case .unknownError:
            return "حدث خطأ غير متوقع. حاول مرة أخرى."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .locationPermissionDenied:
            return "افتح الإعدادات > سند > الموقع > اختر 'دائماً'"
        case .microphonePermissionDenied:
            return "افتح الإعدادات > سند > الميكروفون > فعّل"
        case .notificationPermissionDenied:
            return "افتح الإعدادات > سند > الإشعارات > فعّل"
        case .locationServiceDisabled:
            return "افتح الإعدادات > الخصوصية > خدمات الموقع > فعّل"
        case .whatsappNotInstalled:
            return "قم بتثبيت تطبيق واتساب من App Store"
        case .noContacts, .noEmergencyContacts, .noFavoriteContacts:
            return "افتح الإعدادات > جهات الاتصال > أضف جهة اتصال جديدة"
        case .noMedications:
            return "افتح قائمة الأدوية > اضغط + لإضافة دواء جديد"
        case .invalidPhoneNumber:
            return "أدخل رقم سعودي صحيح يبدأ بـ 05 متبوعاً بـ 8 أرقام"
        case .dataCorrupted:
            return "افتح الإعدادات > إعادة تعيين البيانات"
        case .networkUnavailable:
            return "تحقق من اتصال الإنترنت أو الواي فاي"
        case .voiceRecognitionFailed:
            return "تأكد من التحدث بوضوح باللغة العربية"
        default:
            return "حاول مرة أخرى أو أعد تشغيل التطبيق"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .locationUnavailable:
            return "لم يتمكن الجهاز من تحديد الموقع الحالي"
        case .locationPermissionDenied:
            return "لم يتم منح التطبيق إذن الوصول للموقع"
        case .phoneCallFailed:
            return "فشل الاتصال بالرقم المحدد"
        case .storageError, .saveFailed:
            return "فشل حفظ البيانات على الجهاز"
        case .networkUnavailable:
            return "الجهاز غير متصل بالإنترنت"
        default:
            return nil
        }
    }
}

// MARK: - Error Extensions

extension SanadError {
    /// Check if error requires user action
    var requiresUserAction: Bool {
        switch self {
        case .locationPermissionDenied, .microphonePermissionDenied, 
             .notificationPermissionDenied, .locationServiceDisabled,
             .noContacts, .noEmergencyContacts, .noFavoriteContacts,
             .noMedications, .whatsappNotInstalled:
            return true
        default:
            return false
        }
    }
    
    /// Check if error is recoverable
    var isRecoverable: Bool {
        switch self {
        case .dataCorrupted, .unknownError:
            return false
        default:
            return true
        }
    }
    
    /// Get error severity level
    var severity: ErrorSeverity {
        switch self {
        case .emergencyActivationFailed, .phoneCallFailed, .dataCorrupted:
            return .critical
        case .locationUnavailable, .noEmergencyContacts, .storageError:
            return .high
        case .invalidPhoneNumber, .invalidContactName, .voiceRecognitionFailed:
            return .medium
        case .operationCancelled, .voiceCommandNotRecognized:
            return .low
        default:
            return .medium
        }
    }
}

// MARK: - Error Severity

enum ErrorSeverity {
    case critical  // Requires immediate attention
    case high      // Important but not critical
    case medium    // Normal error
    case low       // Minor issue
    
    var color: String {
        switch self {
        case .critical: return "red"
        case .high: return "orange"
        case .medium: return "yellow"
        case .low: return "blue"
        }
    }
}
