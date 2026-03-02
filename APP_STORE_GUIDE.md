# 🍎 Sanad — App Store Submission Guide

## 📋 Pre-Submission Checklist

---

## 1. Xcode Project Configuration

### Required Capabilities (Add in Xcode → Target → Signing & Capabilities)
| Capability | Purpose |
|---|---|
| HealthKit | Steps, heart rate, sleep data |
| iCloud (CloudKit) | Sync contacts & medications |
| Siri | Voice shortcuts |
| Background Modes | Location, fetch, remote notifications |
| Push Notifications | Medication reminders |
| WatchKit App | Apple Watch companion |

### Steps to Add Capabilities:
1. Open `Sanad.xcodeproj` in Xcode
2. Select `Sanad` target → **Signing & Capabilities**
3. Click **+ Capability** for each item above
4. For iCloud: enable **CloudKit** and set container to `iCloud.com.sanad.app`

---

## 2. Bundle ID & Signing

```
Bundle Identifier: com.sanad.app
Version: 1.0.0
Build: 1
Deployment Target: iOS 17.0
```

### Apple Developer Account Setup:
1. Go to [developer.apple.com](https://developer.apple.com)
2. Create App ID: `com.sanad.app`
3. Enable all required capabilities in App ID
4. Create Distribution Certificate
5. Create App Store Provisioning Profile
6. In Xcode: Xcode → Preferences → Accounts → Add Apple ID

---

## 3. App Icon Requirements

All icons must be in `Sanad/Assets.xcassets/AppIcon.appiconset/`

| Size | Usage |
|---|---|
| 1024×1024 | App Store listing (required) |
| 180×180 | iPhone @3x |
| 120×120 | iPhone @2x |
| 167×167 | iPad Pro @2x |
| 152×152 | iPad @2x |

**Current status:** Partial — verify 1024×1024 exists and has no alpha channel (App Store rejects transparent icons)

---

## 4. App Store Connect Setup

### Create App Record:
1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. My Apps → **+** → New App
3. Fill in:
   - **Name:** سند - Sanad
   - **Bundle ID:** com.sanad.app
   - **SKU:** sanad-001
   - **Primary Language:** Arabic

### App Information:
```
Category: Medical (Primary) / Utilities (Secondary)
Age Rating: 4+ (no objectionable content)
Price: Free (recommended for initial launch)
Availability: Saudi Arabia (primary), all Arabic countries
```

---

## 5. App Store Listing Content (Arabic)

### App Name:
```
سند - رفيق كبار السن
```

### Subtitle (30 chars max):
```
رعاية وأمان لكبار السن
```

### Description (Arabic):
```
سند هو تطبيق ذكي مصمم خصيصاً لكبار السن وذويهم في المملكة العربية السعودية.

🌟 المميزات الرئيسية:

📞 اتصال سريع بالعائلة
اتصل بأحبائك بضغطة زر واحدة عبر الهاتف أو واتساب

📍 مشاركة الموقع
أرسل موقعك الحالي للعائلة فوراً عبر خرائط جوجل أو أبل

🚨 نظام الطوارئ الذكي
عد تنازلي قابل للإلغاء مع إرسال تلقائي للموقع وتنبيه العائلة

💊 تذكير الأدوية
تذكير صوتي بالعربية مع جدولة أوقات متعددة وإشعارات منتظمة

🏠 السياج الجغرافي
تنبيه تلقائي للعائلة عند الخروج من منطقة المنزل

🎤 أوامر صوتية بالعربية
"اتصل بالعائلة" - "أرسل موقعي" - "ساعدني" - "أدويتي"

❤️ بيانات الصحة
متابعة الخطوات اليومية ومعدل ضربات القلب والنوم

🕌 أوقات الصلاة والقبلة
أوقات الصلاة الدقيقة وبوصلة القبلة

⌚ دعم Apple Watch
تحكم كامل من ساعتك مع تنبيهات فورية

☁️ مزامنة iCloud
احتفظ ببياناتك آمنة ومزامنة عبر أجهزتك

🛡️ آمن ومحمي
تشفير كامل للبيانات الحساسة وتخزين آمن

تطبيق سند — معك دائماً للراحة والأمان
```

### Keywords (100 chars max):
```
كبار السن,طوارئ,أدوية,عائلة,موقع,سقوط,تذكير,صحة,أمان,رعاية
```

### What's New (Version 1.0.0):
```
الإصدار الأول من تطبيق سند!
- نظام طوارئ ذكي مع كشف السقوط
- تذكير الأدوية بالصوت العربي
- مشاركة الموقع الفورية
- أوامر صوتية بالعربية
- دعم Apple Watch
- أوقات الصلاة والقبلة
- مزامنة iCloud
```

---

## 6. Screenshots Requirements

### iPhone Screenshots (6.7" — iPhone 15 Pro Max):
Required: 3-10 screenshots at 1290×2796 pixels

Recommended screenshots:
1. **الشاشة الرئيسية** — Main screen with 3 big buttons
2. **الطوارئ** — Emergency countdown screen
3. **الأدوية** — Medication list with reminders
4. **الصحة** — Health dashboard (steps, heart rate)
5. **أوقات الصلاة** — Prayer times with Qibla compass
6. **Apple Watch** — Watch companion app

### iPad Screenshots (12.9" — if supporting iPad):
Size: 2048×2732 pixels

---

## 7. Privacy Policy

**Required** — Apple rejects apps without a privacy policy that request sensitive permissions.

### Create a privacy policy page at:
```
https://sanad-app.com/privacy
```

### Privacy Policy Template (Arabic):
```
سياسة الخصوصية - تطبيق سند

آخر تحديث: [التاريخ]

1. البيانات التي نجمعها:
- الموقع الجغرافي (لمشاركته مع العائلة في حالات الطوارئ)
- بيانات الصحة (الخطوات، معدل ضربات القلب) — محلية فقط
- جهات الاتصال (المدخلة يدوياً فقط)
- بيانات الأدوية (محلية فقط)

2. كيف نستخدم البيانات:
- لا نشارك بياناتك مع أطراف ثالثة
- البيانات تُخزن محلياً على جهازك
- مزامنة iCloud اختيارية وخاصة بحسابك

3. الأذونات المطلوبة:
- الموقع: لإرساله للعائلة في الطوارئ
- الميكروفون: للأوامر الصوتية
- الإشعارات: لتذكيرات الأدوية
- الحركة: لكشف السقوط
- الصحة: لعرض بيانات اللياقة

4. التواصل:
support@sanad-app.com
```

---

## 8. Support URL

Create a support page at:
```
https://sanad-app.com/support
```

Or use email:
```
mailto:support@sanad-app.com
```

---

## 9. TestFlight Beta Testing

### Steps:
1. Archive app: Xcode → Product → Archive
2. Upload to App Store Connect
3. Go to TestFlight tab
4. Add internal testers (up to 100)
5. Add external testers (up to 10,000)
6. Test on real devices:
   - iPhone (for fall detection, location)
   - Apple Watch (for Watch app)
   - iPad (if supporting)

### Critical Test Cases:
- [ ] Onboarding flow (first launch)
- [ ] Add emergency contact → call them
- [ ] Send location via WhatsApp
- [ ] Emergency countdown → cancel
- [ ] Emergency countdown → confirm
- [ ] Add medication → receive notification
- [ ] Mark medication as taken
- [ ] Fall detection (shake device vigorously)
- [ ] Geofence exit alert
- [ ] Voice command: "اتصل بالعائلة"
- [ ] Prayer times display correctly for current location
- [ ] HealthKit data displays
- [ ] iCloud sync (two devices)
- [ ] Apple Watch: all 4 buttons work
- [ ] Dark mode toggle
- [ ] Arabic RTL layout on all screens

---

## 10. App Review Guidelines Compliance

### Key Points:
- ✅ App does what it says in description
- ✅ No misleading features
- ✅ Privacy policy included
- ✅ All permissions justified in Info.plist
- ✅ No private API usage
- ✅ PrivacyInfo.xcprivacy included
- ✅ App works without internet (offline-first)
- ✅ Emergency features clearly explained

### Potential Review Notes to Include:
```
This app is designed for elderly users in Saudi Arabia.
Emergency features (fall detection, SOS) require real device testing.
HealthKit integration reads data only — no writing.
Location is used only when user explicitly shares it.
```

---

## 11. Submission Steps

1. **Archive:** Xcode → Product → Archive
2. **Validate:** Organizer → Validate App
3. **Upload:** Organizer → Distribute App → App Store Connect
4. **App Store Connect:**
   - Fill all metadata
   - Upload screenshots
   - Set pricing (Free)
   - Submit for Review
5. **Review Time:** Typically 24-48 hours

---

## 12. Post-Launch

- Monitor crash reports in Xcode Organizer
- Respond to user reviews
- Plan version 1.1 with user feedback
- Consider Arabic App Store featuring (contact Apple)

---

**🎉 Good luck with the App Store submission!**
**تطبيق سند — معك دائماً للراحة والأمان**
