import SwiftUI

struct FamilyDashboardView: View {
    @StateObject private var viewModel = FamilyDashboardViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header

                if !viewModel.isLinked {
                    notLinkedView
                } else {
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
                Text("موقع، أدوية، ضغط الدم، وتنبيهات الطوارئ")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.blue.opacity(0.08))
        .cornerRadius(16)
    }

    private var notLinkedView: some View {
        VStack(spacing: 12) {
            Image(systemName: "link.badge.plus")
                .font(.system(size: 42))
                .foregroundColor(.orange)

            Text("لا يوجد ربط مع الأب بعد")
                .font(.headline)

            Text("ادخل رمز الدعوة المكوّن من 6 أرقام من جهاز الأب")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
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
