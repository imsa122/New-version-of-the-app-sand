//
//  WatchMainView.swift
//  SanadWatch
//
//  Main screen for Apple Watch — 3 large action buttons
//  Designed for quick access on small screen
//

import SwiftUI

struct WatchMainView: View {

    @EnvironmentObject private var session: WatchSessionManager
    @State private var showEmergencyConfirm = false
    @State private var showMedications = false
    @State private var actionFeedback: String? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {

                    // MARK: - App Title
                    Text("سند")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.green)

                    // MARK: - Connection Status
                    HStack(spacing: 4) {
                        Circle()
                            .fill(session.isPhoneReachable ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(session.isPhoneReachable ? "متصل" : "غير متصل")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    // MARK: - Feedback Banner
                    if let feedback = actionFeedback {
                        Text(feedback)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.green.opacity(0.8))
                            .cornerRadius(8)
                            .transition(.opacity)
                    }

                    // MARK: - Call Family Button
                    WatchActionButton(
                        title: "اتصل بالعائلة",
                        icon: "phone.fill",
                        color: .green
                    ) {
                        session.sendCallFamilyCommand()
                        showFeedback("جاري الاتصال...")
                    }

                    // MARK: - Send Location Button
                    WatchActionButton(
                        title: "أرسل موقعي",
                        icon: "location.fill",
                        color: .blue
                    ) {
                        session.sendLocationCommand()
                        showFeedback("تم إرسال الموقع")
                    }

                    // MARK: - Emergency Button
                    WatchActionButton(
                        title: "طوارئ",
                        icon: "exclamationmark.triangle.fill",
                        color: .red
                    ) {
                        showEmergencyConfirm = true
                    }

                    // MARK: - Medications Button
                    NavigationLink {
                        WatchMedicationView()
                            .environmentObject(session)
                    } label: {
                        WatchActionButtonLabel(
                            title: "الأدوية",
                            icon: "pills.fill",
                            color: .orange
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 8)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .environment(\.layoutDirection, .rightToLeft)
        .alert("تأكيد الطوارئ", isPresented: $showEmergencyConfirm) {
            Button("إلغاء", role: .cancel) {}
            Button("تأكيد", role: .destructive) {
                session.sendEmergencyCommand()
                showFeedback("تم إرسال الطوارئ!")
            }
        } message: {
            Text("هل تريد إرسال تنبيه طوارئ؟")
        }
    }

    private func showFeedback(_ message: String) {
        withAnimation {
            actionFeedback = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                actionFeedback = nil
            }
        }
    }
}

// MARK: - Watch Action Button

struct WatchActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            WatchActionButtonLabel(title: title, icon: icon, color: color)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Watch Action Button Label

struct WatchActionButtonLabel: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(color)
                .clipShape(Circle())

            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)

            Spacer()

            Image(systemName: "chevron.left")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(color.opacity(0.12))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    WatchMainView()
        .environmentObject(WatchSessionManager.shared)
}
