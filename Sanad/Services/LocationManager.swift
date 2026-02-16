//
//  LocationManager.swift
//  Sanad
//
//  Manages location services and geofencing
//

import Foundation
import CoreLocation
import Combine

/// مدير الموقع - Location Manager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    static let shared = LocationManager()
    
    private let manager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isOutsideGeofence: Bool = false
    
    private var geofenceRegion: CLCircularRegion?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        authorizationStatus = manager.authorizationStatus
    }
    
    // MARK: - Authorization
    
    /// طلب إذن الموقع - Request Location Permission
    func requestPermission() {
        manager.requestAlwaysAuthorization()
    }
    
    /// بدء تحديث الموقع - Start Updating Location
    func startUpdatingLocation() {
        manager.startUpdatingLocation()
    }
    
    /// إيقاف تحديث الموقع - Stop Updating Location
    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }
    
    /// طلب الموقع مرة واحدة - Request Location Once
    func requestLocation() {
        manager.requestLocation()
    }
    
    // MARK: - Geofencing
    
    /// إعداد السياج الجغرافي - Setup Geofence
    func setupGeofence(center: CLLocationCoordinate2D, radius: Double, identifier: String = "home") {
        // إزالة السياج القديم إن وجد
        if let oldRegion = geofenceRegion {
            manager.stopMonitoring(for: oldRegion)
        }
        
        // إنشاء سياج جديد
        let region = CLCircularRegion(
            center: center,
            radius: radius,
            identifier: identifier
        )
        region.notifyOnEntry = true
        region.notifyOnExit = true
        
        geofenceRegion = region
        manager.startMonitoring(for: region)
    }
    
    /// إزالة السياج الجغرافي - Remove Geofence
    func removeGeofence() {
        if let region = geofenceRegion {
            manager.stopMonitoring(for: region)
            geofenceRegion = nil
            isOutsideGeofence = false
        }
    }
    
    // MARK: - Location Sharing
    
    /// الحصول على رابط خرائط جوجل - Get Google Maps Link
    func getGoogleMapsLink() -> String? {
        guard let location = location else { return nil }
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        return "https://www.google.com/maps?q=\(lat),\(lon)"
    }
    
    /// الحصول على رابط خرائط أبل - Get Apple Maps Link
    func getAppleMapsLink() -> String? {
        guard let location = location else { return nil }
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        return "http://maps.apple.com/?ll=\(lat),\(lon)"
    }
    
    /// الحصول على نص الموقع - Get Location Text
    func getLocationText() -> String? {
        guard let location = location else { return nil }
        let lat = String(format: "%.6f", location.coordinate.latitude)
        let lon = String(format: "%.6f", location.coordinate.longitude)
        return "موقعي الحالي:\nخط العرض: \(lat)\nخط الطول: \(lon)\n\nرابط الخريطة:\n\(getGoogleMapsLink() ?? "")"
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("خطأ في الموقع - Location error:", error.localizedDescription)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            startUpdatingLocation()
        case .denied, .restricted:
            print("تم رفض إذن الموقع - Location permission denied")
        case .notDetermined:
            requestPermission()
        @unknown default:
            break
        }
    }
    
    // MARK: - Geofence Monitoring
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region.identifier == geofenceRegion?.identifier {
            isOutsideGeofence = false
            print("دخل المنطقة المحددة - Entered geofence")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region.identifier == geofenceRegion?.identifier {
            isOutsideGeofence = true
            print("خرج من المنطقة المحددة - Exited geofence")
            // إرسال تنبيه للعائلة
            NotificationCenter.default.post(name: .geofenceExited, object: nil)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("فشل مراقبة المنطقة - Geofence monitoring failed:", error.localizedDescription)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let geofenceExited = Notification.Name("geofenceExited")
}
