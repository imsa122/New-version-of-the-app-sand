//
//  EnhancedMainView.swift
//  Sanad
//

import SwiftUI

struct EnhancedMainView: View {
    
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var voiceManager = EnhancedVoiceManager.shared
    
    @State private var showSettings = false
    @State private var showMedications = false
    @State private var showActivityLog = false   // ✅ جديد
    
    var body: some View {
        NavigationStack {
            ZStack {
                
                // الخلفية
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 25) {
                    
                    // العنوان
                    headerView
                    
                    // 🟢 بطاقة الحالة اليومية
                    DailyStatusCard(
                        isInsideHomeArea: true,
                        hasActiveAlert: viewModel.showEmergencyAlert || viewModel.showFallAlert
                    )
                    
                    Spacer()
                    
                    // الأزرار الرئيسية
                    mainButtonsView
                    
                    Spacer()
                    
                    // زر الأوامر الصوتية
                    voiceCommandButton
                    
                    // الشريط السفلي
                    bottomNavigationView
                }
                .padding()
            }
            .navigationDestination(isPresented: $showSettings) {
                SettingsView()
            }
            .navigationDestination(isPresented: $showMedications) {
                MedicationListView()
            }
            .navigationDestination(isPresented: $showActivityLog) {   // ✅ ربط شاشة السجل
                ActivityLogView()
            }
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
            .alert("تنبيه طوارئ", isPresented: $viewModel.showEmergencyAlert) {
                Button("أنا بخير - إلغاء", role: .cancel) {
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
        VStack(spacing: 10) {
            Text("سند")
                .font(.system(size: 50, weight: .bold))
                .foregroundColor(.blue)
            
            Text("رفيقك الذكي")
                .font(.title3)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Main Buttons
    
    private var mainButtonsView: some View {
        VStack(spacing: 25) {
            
            BigButton(
                title: "📞 اتصل بالعائلة",
                backgroundColor: .green,
                action: viewModel.callFamily
            )
            
            BigButton(
                title: "📍 أرسل موقعي",
                backgroundColor: .blue,
                action: viewModel.sendLocation
            )
            
            BigButton(
                title: "🚨 المساعدة الطارئة",
                backgroundColor: .red,
                action: viewModel.requestEmergencyHelp
            )
        }
    }
    
    // MARK: - Voice Command Button
    
    private var voiceCommandButton: some View {
        Button(action: {
            if voiceManager.isListening {
                viewModel.stopVoiceListening()
            } else {
                viewModel.startVoiceListening()
            }
        }) {
            HStack {
                Image(systemName: voiceManager.isListening ? "mic.fill" : "mic")
                    .font(.title2)
                
                Text(voiceManager.isListening ? "جاري الاستماع..." : "اضغط للأوامر الصوتية")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(voiceManager.isListening ? Color.orange : Color.purple)
            .cornerRadius(15)
        }
        .animation(.easeInOut, value: voiceManager.isListening)
    }
    
    // MARK: - Bottom Navigation
    
    private var bottomNavigationView: some View {
        HStack(spacing: 15) {
            
            NavigationButton(
                icon: "pills.fill",
                title: "الأدوية",
                color: .orange
            ) {
                showMedications = true
            }
            
            NavigationButton(
                icon: "list.bullet.rectangle",   // ✅ زر السجل
                title: "السجل",
                color: .blue
            ) {
                showActivityLog = true
            }
            
            NavigationButton(
                icon: "gearshape.fill",
                title: "الإعدادات",
                color: .gray
            ) {
                showSettings = true
            }
        }
    }
}

// MARK: - Big Button

struct BigButton: View {
    let title: String
    var backgroundColor: Color = .blue
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .background(backgroundColor)
                .cornerRadius(20)
                .shadow(color: backgroundColor.opacity(0.3), radius: 10, x: 0, y: 5)
        }
    }
}

// MARK: - Navigation Button

struct NavigationButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(15)
        }
    }
}
