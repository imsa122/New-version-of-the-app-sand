//
//  WatchMedicationView.swift
//  SanadWatch
//
//  Medication list and tracking for Apple Watch
//  Shows today's medications with "Mark as Taken" button
//

import SwiftUI

struct WatchMedicationView: View {

    @EnvironmentObject private var session: WatchSessionManager
    @State private var takenMedications: Set<String> = []
    @State private var showConfirmation = false
    @State private var selectedMedication: WatchMedication?

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {

                // MARK: - Header
                HStack {
                    Image(systemName: "pills.fill")
                        .foregroundColor(.orange)
                    Text("الأدوية")
                        .font(.system(size: 16, weight: .bold))
                    Spacer()
                }
                .padding(.horizontal, 4)

                // MARK: - Medications List
                if session.medications.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "pills")
                            .font(.system(size: 30))
                            .foregroundColor(.secondary)
                        Text("لا توجد أدوية")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        Text("افتح التطبيق على الهاتف")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                } else {
                    ForEach(session.medications) { medication in
                        WatchMedicationRow(
                            medication: medication,
                            isTaken: takenMedications.contains(medication.id)
                        ) {
                            selectedMedication = medication
                            showConfirmation = true
                        }
                    }
                }

                // MARK: - Summary
                if !session.medications.isEmpty {
                    Divider()

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("تم أخذ")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Text("\(takenMedications.count)/\(session.medications.count)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(
                                    takenMedications.count == session.medications.count
                                    ? .green : .orange
                                )
                        }

                        Spacer()

                        if takenMedications.count == session.medications.count {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title3)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .padding(.horizontal, 8)
        }
        .navigationTitle("الأدوية")
        .environment(\.layoutDirection, .rightToLeft)
        .alert("تأكيد أخذ الدواء", isPresented: $showConfirmation) {
            Button("إلغاء", role: .cancel) {}
            Button("تم أخذه ✓") {
                if let med = selectedMedication {
                    markAsTaken(med)
                }
            }
        } message: {
            if let med = selectedMedication {
                Text("هل أخذت \(med.name)؟\n\(med.dosage)")
            }
        }
    }

    // MARK: - Mark as Taken

    private func markAsTaken(_ medication: WatchMedication) {
        takenMedications.insert(medication.id)
        session.sendMedicationTaken(medicationId: medication.id)

        // Haptic feedback
        WKInterfaceDevice.current().play(.success)
    }
}

// MARK: - Watch Medication Row

struct WatchMedicationRow: View {

    let medication: WatchMedication
    let isTaken: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {

                // Status indicator
                ZStack {
                    Circle()
                        .fill(isTaken ? Color.green.opacity(0.2) : Color.orange.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: isTaken ? "checkmark.circle.fill" : "pills.fill")
                        .font(.system(size: 16))
                        .foregroundColor(isTaken ? .green : .orange)
                }

                // Medication info
                VStack(alignment: .leading, spacing: 2) {
                    Text(medication.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isTaken ? .secondary : .primary)
                        .strikethrough(isTaken)

                    Text(medication.dosage)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    // Times
                    if !medication.times.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(medication.times.prefix(2), id: \.self) { time in
                                Text(time)
                                    .font(.system(size: 10))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.15))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(
                isTaken
                ? Color.green.opacity(0.08)
                : Color(.secondarySystemBackground)
            )
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .disabled(isTaken)
    }
}

// MARK: - WKInterfaceDevice import
import WatchKit

// MARK: - Preview

#Preview {
    WatchMedicationView()
        .environmentObject(WatchSessionManager.shared)
}
