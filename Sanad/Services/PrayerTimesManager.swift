//
//  PrayerTimesManager.swift
//  Sanad
//
//  Calculates Islamic prayer times based on user location
//  Uses astronomical calculation method (Umm Al-Qura — Saudi Arabia)
//  Schedules prayer time notifications and calculates Qibla direction
//

import Foundation
import CoreLocation
import UserNotifications
import Combine

/// مدير أوقات الصلاة - Prayer Times Manager
class PrayerTimesManager: ObservableObject {

    static let shared = PrayerTimesManager()

    // MARK: - Published Properties

    @Published var prayerTimes: [Prayer] = []
    @Published var nextPrayer: Prayer?
    @Published var timeUntilNextPrayer: String = ""
    @Published var qiblaDirection: Double = 0.0 // degrees from North
    @Published var currentLocation: CLLocation?

    // MARK: - Private

    private var timer: Timer?
    private let locationManager = LocationManager.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    private init() {
        setupLocationObserver()
        startCountdownTimer()
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - Location Observer

    private func setupLocationObserver() {
        locationManager.$location
            .compactMap { $0 }
            .removeDuplicates { loc1, loc2 in
                loc1.coordinate.latitude == loc2.coordinate.latitude &&
                loc1.coordinate.longitude == loc2.coordinate.longitude
            }
            .sink { [weak self] location in
                self?.currentLocation = location
                self?.calculatePrayerTimes(for: location)
                self?.calculateQiblaDirection(from: location)
            }
            .store(in: &cancellables)
    }

    // MARK: - Prayer Times Calculation
    // Uses Umm Al-Qura method (standard for Saudi Arabia)

    func calculatePrayerTimes(for location: CLLocation) {
        let coordinate = location.coordinate
        let date = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)

        guard let year = components.year,
              let month = components.month,
              let day = components.day else { return }

        let times = computePrayerTimes(
            year: year, month: month, day: day,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            timezone: Double(TimeZone.current.secondsFromGMT()) / 3600.0
        )

        DispatchQueue.main.async {
            self.prayerTimes = times
            self.updateNextPrayer()
        }
    }

    // MARK: - Core Calculation Engine (Umm Al-Qura Method)

    private func computePrayerTimes(
        year: Int, month: Int, day: Int,
        latitude: Double, longitude: Double,
        timezone: Double
    ) -> [Prayer] {

        let jd = julianDay(year: year, month: month, day: day)
        let d = jd - 2451545.0

        // Sun position
        let g = (357.529 + 0.98560028 * d).truncatingRemainder(dividingBy: 360)
        let q = (280.459 + 0.98564736 * d).truncatingRemainder(dividingBy: 360)
        let l = (q + 1.915 * sin(g.toRad) + 0.020 * sin(2 * g.toRad)).truncatingRemainder(dividingBy: 360)
        let e = 23.439 - 0.00000036 * d
        let ra = atan2(cos(e.toRad) * sin(l.toRad), cos(l.toRad)).toDeg / 15
        let eqt = q / 15 - ra.truncatingRemainder(dividingBy: 24)
        let decl = asin(sin(e.toRad) * sin(l.toRad)).toDeg

        // Transit (Dhuhr)
        let transit = 12 + timezone - longitude / 15 - eqt

        // Sunrise / Sunset angle
        let sunriseAngle = -0.8333
        let sunriseT = sunAngleTime(angle: sunriseAngle, transit: transit, latitude: latitude, decl: decl, direction: -1)
        let sunsetT  = sunAngleTime(angle: sunriseAngle, transit: transit, latitude: latitude, decl: decl, direction: 1)

        // Fajr (18° below horizon — Umm Al-Qura)
        let fajrT = sunAngleTime(angle: -18.0, transit: transit, latitude: latitude, decl: decl, direction: -1)

        // Asr (Shafi'i — shadow factor 1)
        let asrT = asrTime(shadowFactor: 1, transit: transit, latitude: latitude, decl: decl)

        // Maghrib = Sunset
        let maghribT = sunsetT

        // Isha (90 min after Maghrib — Umm Al-Qura)
        let ishaT = maghribT + 1.5

        let prayers: [(String, Double, String)] = [
            ("الفجر",   fajrT,    "fajr"),
            ("الشروق",  sunriseT, "sunrise"),
            ("الظهر",   transit,  "dhuhr"),
            ("العصر",   asrT,     "asr"),
            ("المغرب",  maghribT, "maghrib"),
            ("العشاء",  ishaT,    "isha")
        ]

        return prayers.map { name, time, key in
            Prayer(
                name: name,
                key: key,
                time: timeFromDouble(time),
                timeDouble: time
            )
        }
    }

    // MARK: - Math Helpers

    private func julianDay(year: Int, month: Int, day: Int) -> Double {
        var y = Double(year)
        var m = Double(month)
        let d = Double(day)
        if m <= 2 { y -= 1; m += 12 }
        let a = floor(y / 100)
        let b = 2 - a + floor(a / 4)
        return floor(365.25 * (y + 4716)) + floor(30.6001 * (m + 1)) + d + b - 1524.5
    }

    private func sunAngleTime(angle: Double, transit: Double, latitude: Double, decl: Double, direction: Double) -> Double {
        let cosHour = (sin(angle.toRad) - sin(latitude.toRad) * sin(decl.toRad)) /
                      (cos(latitude.toRad) * cos(decl.toRad))
        if cosHour < -1 || cosHour > 1 { return transit } // polar day/night
        let hour = acos(cosHour).toDeg / 15
        return transit + direction * hour
    }

    private func asrTime(shadowFactor: Double, transit: Double, latitude: Double, decl: Double) -> Double {
        let angle = -atan(1.0 / (shadowFactor + tan(abs(latitude - decl).toRad))).toDeg
        return sunAngleTime(angle: angle, transit: transit, latitude: latitude, decl: decl, direction: 1)
    }

    private func timeFromDouble(_ t: Double) -> Date {
        var hours = t.truncatingRemainder(dividingBy: 24)
        if hours < 0 { hours += 24 }
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = h
        components.minute = m
        components.second = 0
        return calendar.date(from: components) ?? Date()
    }

    // MARK: - Qibla Direction

    /// حساب اتجاه القبلة - Calculate Qibla Direction
    func calculateQiblaDirection(from location: CLLocation) {
        // Kaaba coordinates
        let kaabaLat = 21.4225 * .pi / 180
        let kaabaLon = 39.8262 * .pi / 180
        let userLat  = location.coordinate.latitude  * .pi / 180
        let userLon  = location.coordinate.longitude * .pi / 180

        let dLon = kaabaLon - userLon
        let y = sin(dLon) * cos(kaabaLat)
        let x = cos(userLat) * sin(kaabaLat) - sin(userLat) * cos(kaabaLat) * cos(dLon)
        var bearing = atan2(y, x) * 180 / .pi
        bearing = (bearing + 360).truncatingRemainder(dividingBy: 360)

        DispatchQueue.main.async {
            self.qiblaDirection = bearing
        }
    }

    // MARK: - Next Prayer

    private func updateNextPrayer() {
        let now = Date()
        nextPrayer = prayerTimes.first { $0.time > now && $0.key != "sunrise" }
        updateCountdown()
    }

    private func updateCountdown() {
        guard let next = nextPrayer else {
            timeUntilNextPrayer = ""
            return
        }
        let diff = next.time.timeIntervalSince(Date())
        if diff <= 0 {
            timeUntilNextPrayer = "الآن"
            return
        }
        let hours = Int(diff) / 3600
        let minutes = (Int(diff) % 3600) / 60
        if hours > 0 {
            timeUntilNextPrayer = "بعد \(hours) ساعة و\(minutes) دقيقة"
        } else {
            timeUntilNextPrayer = "بعد \(minutes) دقيقة"
        }
    }

    // MARK: - Countdown Timer

    private func startCountdownTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateNextPrayer()
        }
    }

    // MARK: - Notifications

    /// جدولة إشعارات أوقات الصلاة - Schedule Prayer Notifications
    func schedulePrayerNotifications() {
        // Remove existing prayer notifications
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let prayerIds = requests
                .filter { $0.identifier.hasPrefix("prayer_") }
                .map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: prayerIds)
        }

        for prayer in prayerTimes where prayer.key != "sunrise" {
            let content = UNMutableNotificationContent()
            content.title = "حان وقت \(prayer.name)"
            content.body = "الوقت: \(prayer.timeString)"
            content.sound = .default

            let components = Calendar.current.dateComponents([.hour, .minute], from: prayer.time)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

            let request = UNNotificationRequest(
                identifier: "prayer_\(prayer.key)",
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ خطأ في جدولة إشعار \(prayer.name): \(error.localizedDescription)")
                } else {
                    print("✅ تم جدولة إشعار \(prayer.name)")
                }
            }
        }
    }

    /// إلغاء إشعارات الصلاة - Cancel Prayer Notifications
    func cancelPrayerNotifications() {
        let ids = prayerTimes.map { "prayer_\($0.key)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - Manual Refresh

    func refresh() {
        if let location = locationManager.location {
            calculatePrayerTimes(for: location)
            calculateQiblaDirection(from: location)
        }
    }
}

// MARK: - Prayer Model

struct Prayer: Identifiable {
    let id = UUID()
    let name: String
    let key: String
    let time: Date
    let timeDouble: Double

    var timeString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar_SA")
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: time)
    }

    var isPassed: Bool {
        time < Date()
    }

    var icon: String {
        switch key {
        case "fajr":    return "moon.stars.fill"
        case "sunrise": return "sunrise.fill"
        case "dhuhr":   return "sun.max.fill"
        case "asr":     return "sun.haze.fill"
        case "maghrib": return "sunset.fill"
        case "isha":    return "moon.fill"
        default:        return "clock.fill"
        }
    }
}

// MARK: - Double Extensions for Angle Math

private extension Double {
    var toRad: Double { self * .pi / 180 }
    var toDeg: Double { self * 180 / .pi }
}
