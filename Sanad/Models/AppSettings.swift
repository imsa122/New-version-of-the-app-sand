//
//  AppSettings.swift
//  Sanad
//
//  Model for app settings and preferences
//

import Foundation
import CoreLocation

/// إعدادات التطبيق - App Settings Model
struct AppSettings: Codable {
    var fontSize: FontSize
    var homeLocation: HomeLocation?
    var geofenceRadius: Double // بالأمتار
    var fallDetectionEnabled: Bool
    var voiceCommandsEnabled: Bool
    var emergencyTimeout: Int // بالثواني
    var language: String
    
    init(
        fontSize: FontSize = .large,
        homeLocation: HomeLocation? = nil,
        geofenceRadius: Double = 500.0,
        fallDetectionEnabled: Bool = true,
        voiceCommandsEnabled: Bool = true,
        emergencyTimeout: Int = 30,
        language: String = "ar"
    ) {
        self.fontSize = fontSize
        self.homeLocation = homeLocation
        self.geofenceRadius = geofenceRadius
        self.fallDetectionEnabled = fallDetectionEnabled
        self.voiceCommandsEnabled = voiceCommandsEnabled
        self.emergencyTimeout = emergencyTimeout
        self.language = language
    }
}

/// حجم الخط - Font Size
enum FontSize: String, Codable, CaseIterable {
    case normal = "عادي"
    case large = "كبير"
    case extraLarge = "كبير جداً"
    
    var scale: CGFloat {
        switch self {
        case .normal: return 1.0
        case .large: return 1.3
        case .extraLarge: return 1.6
        }
    }
}

/// موقع المنزل - Home Location
struct HomeLocation: Codable, Equatable {
    var latitude: Double
    var longitude: Double
    var address: String?
    
    init(latitude: Double, longitude: Double, address: String? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
    }
    
    /// تحويل إلى CLLocationCoordinate2D
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    /// إنشاء من CLLocationCoordinate2D
    init(coordinate: CLLocationCoordinate2D, address: String? = nil) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.address = address
    }
}

// MARK: - Default Settings
extension AppSettings {
    static let `default` = AppSettings()
    
    static let sample = AppSettings(
        fontSize: .large,
        homeLocation: HomeLocation(
            latitude: 21.4858,
            longitude: 39.1925,
            address: "جدة، المملكة العربية السعودية"
        ),
        geofenceRadius: 500.0,
        fallDetectionEnabled: true,
        voiceCommandsEnabled: true,
        emergencyTimeout: 30,
        language: "ar"
    )
}
