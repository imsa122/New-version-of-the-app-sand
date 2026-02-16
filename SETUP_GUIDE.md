# Sanad App - Setup Guide

## Quick Start Guide

This guide will help you set up and run the Sanad iOS application.

---

## Prerequisites

Before you begin, ensure you have:

- ✅ **macOS** (Ventura 13.0 or later recommended)
- ✅ **Xcode 15.0+** installed from the Mac App Store
- ✅ **Apple Developer Account** (free or paid)
- ✅ **iPhone** running iOS 17.0+ (for full testing)

---

## Step 1: Open the Project

1. Navigate to the project directory:
   ```bash
   cd Sanad-step1-main
   ```

2. Open the Xcode project:
   ```bash
   open Sanad.xcodeproj
   ```

---

## Step 2: Configure Project Settings

### A. Update Info.plist

1. In Xcode, locate `Sanad/Info.plist`
2. Replace its contents with the content from `Sanad/EnhancedInfo.plist`
3. Or simply delete the old `Info.plist` and rename `EnhancedInfo.plist` to `Info.plist`

### B. Update App Entry Point

1. Open `Sanad/SanadApp.swift`
2. Replace its content with:

```swift
//
//  SanadApp.swift
//  Sanad
//

import SwiftUI

@main
struct SanadApp: App {
    
    init() {
        setupAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            EnhancedMainView()
                .onAppear {
                    requestPermissions()
                }
        }
    }
    
    private func setupAppearance() {
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
    }
    
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
```

### C. Configure Signing

1. Select the **Sanad** target in Xcode
2. Go to **Signing & Capabilities** tab
3. Select your **Team** from the dropdown
4. Xcode will automatically generate a Bundle Identifier
5. Ensure **Automatically manage signing** is checked

---

## Step 3: Add Required Capabilities

In **Signing & Capabilities**, add:

1. **Background Modes**
   - ✅ Location updates
   - ✅ Background fetch
   - ✅ Remote notifications

2. **Push Notifications** (optional, for future features)

---

## Step 4: Build and Run

### Option A: Run on Simulator

1. Select an iPhone simulator (iPhone 15 Pro recommended)
2. Press **⌘R** or click the **Run** button
3. Wait for the build to complete

**Note**: Some features won't work on simulator:
- Fall detection (requires real device sensors)
- Phone calls
- SMS sending

### Option B: Run on Real Device (Recommended)

1. Connect your iPhone via USB
2. Trust the computer on your iPhone if prompted
3. Select your iPhone from the device list
4. Press **⌘R** or click **Run**
5. If you see a signing error:
   - Go to iPhone Settings > General > VPN & Device Management
   - Trust your developer certificate

---

## Step 5: Grant Permissions

When the app launches for the first time, it will request several permissions:

### 1. Location Permission
- **Choose**: "Allow While Using App" or "Always Allow"
- **Why**: Required for location sharing and geofencing

### 2. Notifications Permission
- **Choose**: "Allow"
- **Why**: Required for medication reminders and emergency alerts

### 3. Microphone Permission
- **Choose**: "Allow"
- **Why**: Required for voice commands

### 4. Speech Recognition Permission
- **Choose**: "OK"
- **Why**: Required to understand Arabic voice commands

### 5. Motion & Fitness Permission
- **Choose**: "Allow"
- **Why**: Required for fall detection

**Important**: Grant all permissions for full functionality!

---

## Step 6: Initial Setup

### Add Emergency Contacts

1. Tap **الإعدادات** (Settings) at the bottom
2. Tap **إدارة جهات الاتصال** (Manage Contacts)
3. Tap the **+** button
4. Enter contact details:
   - Name (e.g., "أحمد")
   - Phone number (e.g., "+966501234567")
   - Relationship (e.g., "ابن")
5. Toggle **جهة اتصال طارئة** (Emergency Contact) ON
6. Tap **حفظ** (Save)

### Add Medications

1. From home screen, tap **الأدوية** (Medications)
2. Tap the **+** button
3. Enter medication details:
   - Name (e.g., "أسبرين")
   - Dosage (e.g., "حبة واحدة")
4. Tap **إضافة وقت** (Add Time)
5. Set hour and minute
6. Add label (e.g., "صباحاً")
7. Tap **حفظ** (Save)

### Set Home Location

1. Go to **الإعدادات** (Settings)
2. Under **الموقع والسياج الجغرافي** (Location & Geofencing)
3. Tap **تحديد موقع المنزل** (Set Home Location)
4. Tap **الموقع الحالي** (Current Location)
5. Tap **حفظ** (Save)

---

## Step 7: Test Features

### Test Emergency System

1. Tap **🚨 المساعدة الطارئة** (Emergency Help)
2. You'll see a countdown alert
3. Tap **أنا بخير - إلغاء** (I'm OK - Cancel) to test cancellation
4. Or wait for the countdown to test automatic alert

### Test Voice Commands

1. Tap **اضغط للأوامر الصوتية** (Press for Voice Commands)
2. Wait for "أنا أستمع" (I'm listening)
3. Say one of these commands:
   - "اتصل بالعائلة" (Call family)
   - "أرسل موقعي" (Send my location)
   - "ساعدني" (Help me)

### Test Fall Detection

**Note**: This requires a real device with motion sensors.

1. Go to Settings
2. Ensure **كشف السقوط** (Fall Detection) is ON
3. Shake the device vigorously
4. You should see an alert: "هل أنت بخير؟" (Are you okay?)

### Test Geofencing

1. Ensure home location is set
2. In Xcode, go to **Debug** > **Simulate Location**
3. Choose a location far from home
4. You should receive an alert about leaving the area

---

## Troubleshooting

### Build Errors

**Error**: "No such module 'SwiftUI'"
- **Fix**: Ensure you're using Xcode 15+ and iOS 17+ deployment target

**Error**: "Command CodeSign failed"
- **Fix**: Check Signing & Capabilities, ensure valid Team is selected

**Error**: "Could not find module 'Combine'"
- **Fix**: This is included in iOS SDK, ensure deployment target is iOS 17+

### Runtime Issues

**Issue**: Permissions not appearing
- **Fix**: 
  1. Delete the app from device
  2. Clean build folder (⌘⇧K)
  3. Rebuild and run

**Issue**: Voice commands not working
- **Fix**:
  1. Check microphone permission in iOS Settings
  2. Ensure speech recognition is enabled in app settings
  3. Speak clearly in Arabic

**Issue**: Fall detection not triggering
- **Fix**:
  1. Must use real device (not simulator)
  2. Check motion permission in iOS Settings
  3. Shake device more vigorously

**Issue**: Notifications not appearing
- **Fix**:
  1. Check notification permission in iOS Settings
  2. Ensure medications are marked as "active"
  3. Check notification times are in the future

---

## File Structure Overview

```
Sanad/
├── Models/                      # Data models
│   ├── Contact.swift           # Contact model
│   ├── Medication.swift        # Medication model
│   └── AppSettings.swift       # Settings model
│
├── ViewModels/                  # Business logic
│   ├── HomeViewModel.swift     # Home screen logic
│   ├── SettingsViewModel.swift # Settings logic
│   └── MedicationViewModel.swift # Medication logic
│
├── Views/                       # UI screens
│   ├── EnhancedMainView.swift  # Main home screen
│   ├── SettingsView.swift      # Settings screen
│   ├── ContactsListView.swift  # Contacts management
│   ├── EmergencyContactsView.swift # Emergency contacts
│   ├── MedicationListView.swift # Medications list
│   └── GeofenceSetupView.swift # Geofence setup
│
├── Services/                    # Core services
│   ├── StorageManager.swift    # Data persistence
│   ├── LocationManager.swift   # Location services
│   ├── FallDetectionManager.swift # Fall detection
│   ├── EnhancedVoiceManager.swift # Voice recognition
│   ├── EnhancedEmergencyManager.swift # Emergency system
│   └── EnhancedReminderManager.swift # Reminders
│
├── EnhancedSanadApp.swift      # App entry point
└── Info.plist                   # App configuration
```

---

## Testing Checklist

Before considering the app complete, test:

- [ ] App launches successfully
- [ ] All permissions are granted
- [ ] Can add/edit/delete contacts
- [ ] Can mark contacts as emergency
- [ ] Can add/edit/delete medications
- [ ] Medication reminders appear on time
- [ ] Can set home location on map
- [ ] Emergency button triggers countdown
- [ ] Can cancel emergency alert
- [ ] Voice commands are recognized
- [ ] Fall detection triggers alert (on real device)
- [ ] Geofence alerts work when leaving area
- [ ] Settings are persisted after app restart
- [ ] RTL layout displays correctly
- [ ] Large fonts are readable

---

## Performance Tips

1. **Battery Optimization**:
   - Location services use battery
   - Consider using "While Using" instead of "Always" for testing

2. **Testing on Simulator**:
   - Use for UI testing only
   - Test core features on real device

3. **Debug Mode**:
   - Check Xcode console for helpful logs
   - All managers print status messages

---

## Next Steps

After successful setup:

1. **Customize**: Adjust colors, fonts, and layouts
2. **Extend**: Add more features like health tracking
3. **Localize**: Add more languages
4. **Deploy**: Prepare for App Store submission

---

## Support

For issues or questions:
1. Check the README.md file
2. Review code comments in source files
3. Check Xcode console for error messages

---

**Happy Coding! 🎉**

Made with ❤️ for the community
