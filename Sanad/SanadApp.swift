import SwiftUI
import UserNotifications

@main
struct SanadApp: App {
    
    init() {
        setupAppearance()
        setupNotificationDelegate()   // ✅ إضافة مهمة
    }
    
    var body: some Scene {
        WindowGroup {
            SplashView()
                .onAppear {
                    requestPermissions()
                }
        }
    }
    
    // MARK: - Setup
    
    private func setupAppearance() {
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
    }
    
    private func setupNotificationDelegate() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }
    
    // MARK: - Permissions
    
    private func requestPermissions() {
        LocationManager.shared.requestPermission()
        
        EnhancedReminderManager.requestPermission { granted in
            print(granted ? "✅ Notifications granted" : "❌ Notifications denied")
        }
        
        EnhancedVoiceManager.shared.requestPermission { granted in
            print(granted ? "✅ Speech recognition granted" : "❌ Speech recognition denied")
        }
    }
}
