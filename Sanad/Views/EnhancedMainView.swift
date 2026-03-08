//
//  EnhancedMainView.swift
//  Sanad
//
//  Updated: Added DailyStatusCard, ActivityLog navigation,
//           Health Dashboard navigation, Dark Mode support
//

import SwiftUI

struct EnhancedMainView: View {

    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var voiceManager = EnhancedVoiceManager.shared
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var emergencyManager = EnhancedEmergencyManager.shared

    @State private var showSettings = false
    @State private var showMedications = false
    @State private var showActivityLog = false
    @State private var showHealthDashboard = false
    @State private var showPrayerTimes = false
    @State private var showFamilyDashboard = false

    var body: some View {
        NavigationStack {
            ZStack {

                // 🎨 Adaptive background — supports Dark Mode
                LinearGradient(
                    colors: [
                        Color(red: 0.88, green: 0.96, blue: 0.93).opacity(0.6),
                        Color(.systemBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        headerView

                        // ✅ NEW: Daily Status Card — shows medication, location, alert status
                        DailyStatusCard(
                            isInsideHomeArea: locationManager.isInsideHomeArea,
                            hasActiveAlert: emergencyManager.isEmergencyActive
                        )

                        mainButtonsView

                        voiceCommandButton

                        bottomNavigationView
                    }
                    .padding()
                }
            }

            .navigationBarHidden(true)

            // MARK: - Navigation Destinations
            .navigationDestination(isPresented: $showSettings) {
                SettingsView()
            }
            .navigationDestination(isPresented: $showMedications) {
                MedicationListView()
            }
            // ✅ NEW: Activity Log navigation
            .navigationDestination(isPresented: $showActivityLog) {
                ActivityLogView()
            }
            // ✅ NEW: Health Dashboard navigation
            .navigationDestination(isPresented: $showHealthDashboard) {
                HealthDashboardView()
            }
            // ✅ NEW: Prayer Times navigation
            .navigationDestination(isPresented: $showPrayerTimes) {
                PrayerTimesView()
            }

            // ✅ NEW: Family Dashboard navigation
            .navigationDestination(isPresented: $showFamilyDashboard) {
                FamilyDashboardView()
            }

            // MARK: - Sheets
            .sheet(isPresented: $viewModel.showFavoritesSelection) {
                FavoritesSelectionView { selectedContacts in
                    viewModel.callSelectedContacts(selectedContacts)
                }
            }
            .sheet(isPresented: $viewModel.showLocationSharing) {
                LocationSharingOptionsView(
                    locationText: viewModel.getLocationText(),
                    locationLink: viewModel.getLocationLink()
                )
            }
            .sheet(isPresented: $viewModel.showEmergencyOptions) {
                EmergencyOptionsView()
            }

            // MARK: - Alerts
            .alert("تنبيه طوارئ", isPresented: $viewModel.showEmergencyAlert) {
                Button("أنا بخير", role: .cancel) {
                    viewModel.cancelEmergency()
                }
                Button("أحتاج مساعدة!", role: .destructive) {
                    viewModel.confirmEmergency()
                }
            } message: {
                Text("هل أنت بحاجة للمساعدة؟ سيتم إرسال تنبيه للعائلة.")
            }
            .alert("هل أنت بخير؟", isPresented: $viewModel.showFallAlert) {
                Button("نعم، أنا بخير", role: .cancel) {
                    viewModel.respondToFallAlert(isOkay: true)
                }
                Button("أحتاج مساعدة!", role: .destructive) {
                    viewModel.respondToFallAlert(isOkay: false)
                }
            } message: {
                Text("تم اكتشاف سقوط محتمل. هل أنت بحاجة للمساعدة؟")
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 8) {
            Image("sanadlogo")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .shadow(radius: 5)

            Text("سند")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.green)

            Text("رفيقك في الأمان")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 16)
    }

    // MARK: - Main Buttons

    private var mainButtonsView: some View {
        VStack(spacing: 16) {
            ModernBigButton(
                title: "اتصل بالعائلة",
                icon: "phone.fill",
                color: .green,
                action: viewModel.callFamily
            )
            ModernBigButton(
                title: "أرسل موقعي",
                icon: "location.fill",
                color: .blue,
                action: viewModel.sendLocation
            )
            ModernBigButton(
                title: "المساعدة الطارئة",
                icon: "siren.fill",
                color: .red,
                action: viewModel.requestEmergencyHelp
            )
        }
    }

    // MARK: - Voice Button

    private var voiceCommandButton: some View {
        Button {
            if voiceManager.isListening {
                viewModel.stopVoiceListening()
            } else {
                viewModel.startVoiceListening()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: voiceManager.isListening ? "mic.fill" : "mic")
                    .font(.title2)
                Text(voiceManager.isListening ? "جاري الاستماع..." : "اضغط للأوامر الصوتية")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                LinearGradient(
                    colors: voiceManager.isListening
                        ? [Color.orange, Color.orange.opacity(0.8)]
                        : [Color.purple, Color.purple.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(20)
            .shadow(radius: 8)
        }
        .animation(.easeInOut, value: voiceManager.isListening)
    }

    // MARK: - Bottom Navigation
    // ✅ Updated: Added Activity Log, Health, Prayer Times buttons

    private var bottomNavigationView: some View {
        VStack(spacing: 12) {
            // Row 1
            HStack(spacing: 12) {
                SmallCardButton(title: "الأدوية", icon: "pills.fill", color: .orange) {
                    showMedications = true
                }
                SmallCardButton(title: "الصحة", icon: "heart.fill", color: .pink) {
                    showHealthDashboard = true
                }
            }
            // Row 2
            HStack(spacing: 12) {
                SmallCardButton(title: "أوقات الصلاة", icon: "moon.stars.fill", color: .indigo) {
                    showPrayerTimes = true
                }
                SmallCardButton(title: "سجل النشاط", icon: "list.bullet.clipboard.fill", color: .teal) {
                    showActivityLog = true
                }
            }
            // Row 3
            HStack(spacing: 12) {
                SmallCardButton(title: "الإعدادات", icon: "gearshape.fill", color: .gray) {
                    showSettings = true
                }

                SmallCardButton(title: "العائلة", icon: "person.2.fill", color: .blue) {
                    showFamilyDashboard = true
                }
            }
        }
        .padding(.bottom, 8)
    }
}


// MARK: - Modern Big Button

struct ModernBigButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                
                Image(systemName: icon)
                    .font(.title2)
                
                Text(title)
                    .font(.system(size: 22, weight: .bold))
                
                Spacer()
            }
            .foregroundColor(.white)
            .padding()
            .frame(height: 75)
            .background(
                LinearGradient(
                    colors: [color, color.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(22)
            .shadow(color: color.opacity(0.3), radius: 10, x: 0, y: 5)
        }
    }
}


// MARK: - Small Card Button

struct SmallCardButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .shadow(radius: 5)
        }
    }
}


// MARK: - Preview

#Preview {
    EnhancedMainView()
}
