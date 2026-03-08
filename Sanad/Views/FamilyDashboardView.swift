import SwiftUI

struct FamilyDashboardView: View {
    @StateObject private var viewModel = FamilyDashboardViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                rolePanel
                messagePanel

                if viewModel.hasPendingApproval {
                    pendingApprovalCard
                }

                if viewModel.isLinked {
                    statusCard
                    alertsCard
                }
            }
            .padding()
        }
        .navigationTitle("متابعة الأب")
        .navigationBarTitleDisplayMode(.large)
        .environment(\.layoutDirection, .rightToLeft)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .onAppear {
            viewModel.load()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 34))
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text("لوحة متابعة العائلة")
                    .font(.title3.bold())
                Text("ربط آمن + موقع، أدوية، ضغط الدم، وتنبيهات الطوارئ")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.blue.opacity(0.08))
        .cornerRadius(16)
    }

    private var rolePanel: some View {
        VStack(spacing: 12) {
            fatherSection
            familySection
        }
    }

    private var fatherSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("أنا الأب", systemImage: "person.fill")
                .font(.headline)

            Text("اضغط لإنشاء رمز ربط من 6 أرقام صالح لمدة 10 دقائق.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button("إنشاء رمز ربط") {
                viewModel.generateFatherCode()
            }
            .buttonStyle(.borderedProminent)

            if let code = viewModel.inviteCode {
                HStack {
                    Text("رمز الربط:")
                        .font(.subheadline.weight(.semibold))
                    Text(code)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                }

                if let expiresAt = viewModel.expiresAt {
                    Text("ينتهي: \(expiresAt.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    private var familySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("أنا أحد أفراد العائلة", systemImage: "person.2.fill")
                .font(.headline)

            Text("أدخل رمز الأب (6 أرقام). سيتم إرسال طلب موافقة للأب أولاً.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            TextField("أدخل الرمز", text: $viewModel.enteredCode)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)

            Button("متابعة الأب") {
                viewModel.submitFamilyCode()
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLocked)

            if viewModel.isLocked {
                Text("تم قفل المحاولات مؤقتاً لأسباب أمنية.")
                    .font(.caption)
                    .foregroundColor(.red)
            } else {
                Text("المحاولات المتبقية: \(viewModel.remainingAttempts)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    private var pendingApprovalCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("طلب ربط بانتظار موافقتك", systemImage: "checkmark.shield.fill")
                .font(.headline)

            if let pendingId = viewModel.pendingFamilyId {
                Text("معرّف العائلة: \(pendingId)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 10) {
                Button("موافقة") {
                    viewModel.approvePendingRequest()
                }
                .buttonStyle(.borderedProminent)

                Button("رفض", role: .destructive) {
                    viewModel.rejectPendingRequest()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color.green.opacity(0.08))
        .cornerRadius(16)
    }

    private var messagePanel: some View {
        VStack(spacing: 6) {
            if let info = viewModel.infoMessage {
                Text(info)
                    .font(.footnote)
                    .foregroundColor(.green)
            }
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.red)
            }
        }
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("الحالة الحالية")
                .font(.headline)

            row("الموقع", viewModel.locationText, "location.fill")
            row("الدواء", viewModel.medicationText, "pills.fill")
            row("ضغط الدم", viewModel.bloodPressureText, "heart.fill")
            row("السلامة", viewModel.emergencyText, "shield.lefthalf.filled")
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    private var alertsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("آخر التنبيهات")
                .font(.headline)

            if viewModel.alerts.isEmpty {
                Text("لا توجد تنبيهات")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.alerts.prefix(8), id: \.self) { alert in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "bell.badge.fill")
                            .foregroundColor(.red)
                        Text(alert)
                            .font(.subheadline)
                    }
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    private func row(_ title: String, _ value: String, _ icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundColor(.blue)
            Text("\(title):")
                .font(.subheadline.weight(.semibold))
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        FamilyDashboardView()
    }
}
