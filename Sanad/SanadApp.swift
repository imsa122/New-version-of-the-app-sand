//
//  SanadApp.swift
//  Sanad
//
//  Created by hhhh on 20/08/1447 AH.
//  Updated: Fixed entry point, registered NotificationDelegate,
//           added HealthKit + Siri + Dark Mode support
//

import SwiftUI
import UserNotifications

@main
struct SanadApp: App {

    // MARK: - App Storage for Color Scheme
    @AppStorage("preferredColorScheme") private var preferredColorScheme: String = "system"

    // MARK: - Init
    init() {
        setupAppearance()
        setupNotificationDelegate()
    }

    // MARK: - Scene
    var body: some Scene {
        WindowGroup {
            // ✅ Fixed: Use SplashView as root (handles onboarding check internally)
            SplashView()
                .preferredColorScheme(resolvedColorScheme)
                .onAppear {
                    requestPermissions()
                    donateSiriShortcuts()
                    setupWatchConnectivity()
                    setupCloudSync()
                }
        }
    }

    // MARK: - Color Scheme Resolution
    private var resolvedColorScheme: ColorScheme? {
        switch preferredColorScheme {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil // follows system
        }
    }

    // MARK: - Notification Delegate
    /// ✅ Fixed: Register NotificationDelegate so medication missed alerts work
    private func setupNotificationDelegate() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    // MARK: - Appearance
    private func setupAppearance() {
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
    }

    // MARK: - Permissions
    private func requestPermissions() {
        // Location
        LocationManager.shared.requestPermission()

        // Notifications
        EnhancedReminderManager.requestPermission { granted in
            print(granted ? "✅ Notifications granted" : "❌ Notifications denied")
        }

        // Speech Recognition
        EnhancedVoiceManager.shared.requestPermission { granted in
            print(granted ? "✅ Speech recognition granted" : "❌ Speech recognition denied")
        }

        // HealthKit
        HealthKitManager.shared.requestAuthorization { granted in
            print(granted ? "✅ HealthKit granted" : "❌ HealthKit denied")
        }
    }

    // MARK: - Siri Shortcuts
    private func donateSiriShortcuts() {
        SiriShortcutsManager.shared.donateShortcuts()
    }

    // MARK: - Watch Connectivity
    private func setupWatchConnectivity() {
        WatchConnectivityManager.shared.updateApplicationContext()
    }

    // MARK: - iCloud Auto Sync
    private func setupCloudSync() {
        let settings = StorageManager.shared.loadSettings()
        if settings.iCloudSyncEnabled {
            CloudSyncManager.shared.setupAutoSync()
            CloudSyncManager.shared.syncAll()
        }
    }
}
