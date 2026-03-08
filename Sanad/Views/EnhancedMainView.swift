//
//  EnhancedMainView.swift
//  Sanad
//
//  Premium redesign: modern background, elevated actions,
//  richer visual hierarchy while preserving existing functionality.
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
                SanadGradientBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        headerView

                        GlassCard {
                            DailyStatusCard(
                                isInsideHomeArea: locationManager.isInsideHomeArea,
                                hasActiveAlert: emergencyManager.isEmergencyActive
                            )
                        }

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
            .navigationDestination(isPresented: $showActivityLog) {
                ActivityLogView()
            }
            .navigationDestination(isPresented: $showHealthDashboard) {
                HealthDashboardView()
            }
            .navigationDestination(isPresented: $showPrayerTimes) {
                PrayerTimesView()
            }
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
                .frame(width: 96, height: 96)
                .shadow(color: SanadPalette.emerald.opacity(0.35), radius: 18, x: 0, y: 8)

            Text("سند")
                .font(.system(size: 38, weight: .heavy))
                .foregroundStyle(
                    LinearGradient(
                        colors: [SanadPalette.emerald, SanadPalette.ocean],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("رفيقك في الأمان")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 10)
    }

    // MARK: - Main Buttons

    private var mainButtonsView: some View {
        VStack(spacing: 14) {
            PremiumActionButton(
                title: "اتصل بالعائلة",
                subtitle: "اتصال سريع وآمن",
                icon: "phone.fill",
                gradient: [SanadPalette.emerald, SanadPalette.emerald.opacity(0.78)],
                action: viewModel.callFamily
            )

            PremiumActionButton(
                title: "أرسل موقعي",
                subtitle: "مشاركة فورية للموقع",
                icon: "location.fill",
                gradient: [SanadPalette.ocean, SanadPalette.violet],
                action: viewModel.sendLocation
            )

            PremiumActionButton(
                title: "المساعدة الطارئة",
                subtitle: "تنبيه عاجل للعائلة",
                icon: "siren.fill",
                gradient: [SanadPalette.coral, Color.red.opacity(0.9)],
                isEmergency: true,
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
                Image(systemName: voiceManager.isListening ? "waveform.circle.fill" : "mic.fill")
                    .font(.title2.weight(.bold))

                Text(voiceManager.isListening ? "جاري الاستماع..." : "اضغط للأوامر الصوتية")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(
                LinearGradient(
                    colors: voiceManager.isListening
                        ? [SanadPalette.amber, Color.orange]
                        : [SanadPalette.violet, SanadPalette.ocean],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 7)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut, value: voiceManager.isListening)
    }

    // MARK: - Bottom Navigation

    private var bottomNavigationView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                QuickNavCard(title: "الأدوية", icon: "pills.fill", color: .orange) {
                    showMedications = true
                }

                QuickNavCard(title: "الصحة", icon: "heart.fill", color: .pink) {
                    showHealthDashboard = true
                }
            }

            HStack(spacing: 12) {
                QuickNavCard(title: "أوقات الصلاة", icon: "moon.stars.fill", color: .indigo) {
                    showPrayerTimes = true
                }

                QuickNavCard(title: "سجل النشاط", icon: "list.bullet.clipboard.fill", color: .teal) {
                    showActivityLog = true
                }
            }

            HStack(spacing: 12) {
                QuickNavCard(title: "الإعدادات", icon: "gearshape.fill", color: .gray) {
                    showSettings = true
                }

                QuickNavCard(title: "العائلة", icon: "person.2.fill", color: .blue) {
                    showFamilyDashboard = true
                }
            }
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Preview

#Preview {
    EnhancedMainView()
}
