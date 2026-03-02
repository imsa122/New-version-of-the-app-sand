//
//  MedicationListView.swift
//  Sanad
//
//  View for managing medications
//

import SwiftUI

struct MedicationListView: View {
    
    @StateObject private var viewModel = MedicationViewModel()
    @State private var showAddMedication = false
    @State private var selectedMedication: Medication?
    
    var body: some View {
        List {
            // قسم الإحصائيات - Statistics Section
            Section {
                HStack {
                    StatCard(
                        icon: "pills.fill",
                        title: "الأدوية النشطة",
                        value: "\(viewModel.activeMedicationsCount)",
                        color: .blue
                    )
                    
                    StatCard(
                        icon: "bell.fill",
                        title: "التذكيرات اليومية",
                        value: "\(viewModel.dailyRemindersCount)",
                        color: .orange
                    )
                }
            }
            .listRowBackground(Color.clear)
            
            // قسم التذكيرات القادمة - Upcoming Reminders
            if !viewModel.upcomingReminders.isEmpty {
                Section("التذكيرات القادمة") {
                    ForEach(viewModel.upcomingReminders.prefix(3)) { reminder in
                        UpcomingReminderRow(reminder: reminder)
                    }
                }
            }
            
            // قسم الأدوية - Medications Section
            Section("قائمة الأدوية") {
                if viewModel.medications.isEmpty {
                    ContentUnavailableView(
                        "لا توجد أدوية",
                        systemImage: "pills",
                        description: Text("قم بإضافة أدويتك لتلقي التذكيرات")
                    )
                } else {
                    ForEach(viewModel.medications) { medication in
                        MedicationRow(medication: medication) {
                            selectedMedication = medication
                        } onToggle: {
                            viewModel.toggleMedicationActive(medication)
                        } onSpeak: {
                            viewModel.speakReminder(for: medication)
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { index in
                            viewModel.deleteMedication(viewModel.medications[index])
                        }
                    }
                }
            }
        }
        .navigationTitle("الأدوية")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddMedication = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
        }
        .sheet(isPresented: $showAddMedication) {
            AddMedicationView { medication in
                viewModel.addMedication(medication)
            }
        }
        .sheet(item: $selectedMedication) { medication in
            EditMedicationView(medication: medication) { updatedMedication in
                viewModel.updateMedication(updatedMedication)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .onAppear {
            viewModel.loadMedications()
            viewModel.fetchUpcomingReminders()
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            
            Text(value)
                .font(.title.bold())
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(15)
    }
}

// MARK: - Upcoming Reminder Row

struct UpcomingReminderRow: View {
    let reminder: ScheduledReminder
    
    var body: some View {
        HStack {
            Image(systemName: "bell.fill")
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(reminder.body)
                    .font(.subheadline)
                
                Text(reminder.timeString)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - Medication Row

struct MedicationRow: View {
    let medication: Medication
    let onTap: () -> Void
    let onToggle: () -> Void
    let onSpeak: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 15) {
                // أيقونة الدواء - Medication Icon
                ZStack {
                    Circle()
                        .fill(medication.isActive ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "pills.fill")
                        .foregroundColor(medication.isActive ? .blue : .gray)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(medication.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(medication.dosage)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 5) {
                        ForEach(medication.times.prefix(3)) { time in
                            Text(time.timeString)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        if medication.times.count > 3 {
                            Text("+\(medication.times.count - 3)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Spacer()
                
                VStack(spacing: 10) {
                    Button(action: onSpeak) {
                        Image(systemName: "speaker.wave.2.fill")
                            .foregroundColor(.purple)
                    }
                    
                    Toggle("", isOn: Binding(
                        get: { medication.isActive },
                        set: { _ in onToggle() }
                    ))
                    .labelsHidden()
                }
            }
            .padding(.vertical, 5)
        }
    }
}

// MARK: - Add Medication View

struct AddMedicationView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (Medication) -> Void
    
    @State private var name = ""
    @State private var dosage = ""
    @State private var notes = ""
    @State private var times: [MedicationTime] = []
    @State private var showAddTime = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("معلومات الدواء") {
                    TextField("اسم الدواء", text: $name)
                    TextField("الجرعة (مثل: حبة واحدة)", text: $dosage)
                    TextField("ملاحظات (اختياري)", text: $notes)
                }
                
                Section("أوقات التناول") {
                    ForEach(times) { time in
                        HStack {
                            Text(time.label)
                            Spacer()
                            Text(time.timeString)
                                .foregroundColor(.blue)
                        }
                    }
                    .onDelete { indexSet in
                        times.remove(atOffsets: indexSet)
                    }
                    
                    Button {
                        showAddTime = true
                    } label: {
                        Label("إضافة وقت", systemImage: "plus.circle")
                    }
                }
            }
            .navigationTitle("إضافة دواء")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إلغاء") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("حفظ") {
                        let medication = Medication(
                            name: name,
                            dosage: dosage,
                            times: times,
                            notes: notes.isEmpty ? nil : notes
                        )
                        onSave(medication)
                        dismiss()
                    }
                    .disabled(name.isEmpty || dosage.isEmpty || times.isEmpty)
                }
            }
            .sheet(isPresented: $showAddTime) {
                AddTimeView { time in
                    times.append(time)
                }
            }
            .environment(\.layoutDirection, .rightToLeft)
        }
    }
}

// MARK: - Edit Medication View

struct EditMedicationView: View {
    @Environment(\.dismiss) private var dismiss
    let medication: Medication
    let onSave: (Medication) -> Void
    
    @State private var name: String
    @State private var dosage: String
    @State private var notes: String
    @State private var times: [MedicationTime]
    @State private var isActive: Bool
    @State private var showAddTime = false
    
    init(medication: Medication, onSave: @escaping (Medication) -> Void) {
        self.medication = medication
        self.onSave = onSave
        _name = State(initialValue: medication.name)
        _dosage = State(initialValue: medication.dosage)
        _notes = State(initialValue: medication.notes ?? "")
        _times = State(initialValue: medication.times)
        _isActive = State(initialValue: medication.isActive)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("معلومات الدواء") {
                    TextField("اسم الدواء", text: $name)
                    TextField("الجرعة", text: $dosage)
                    TextField("ملاحظات", text: $notes)
                }
                
                Section {
                    Toggle("نشط", isOn: $isActive)
                }
                
                Section("أوقات التناول") {
                    ForEach(times) { time in
                        HStack {
                            Text(time.label)
                            Spacer()
                            Text(time.timeString)
                                .foregroundColor(.blue)
                        }
                    }
                    .onDelete { indexSet in
                        times.remove(atOffsets: indexSet)
                    }
                    
                    Button {
                        showAddTime = true
                    } label: {
                        Label("إضافة وقت", systemImage: "plus.circle")
                    }
                }
            }
            .navigationTitle("تعديل الدواء")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إلغاء") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("حفظ") {
                        var updatedMedication = medication
                        updatedMedication.name = name
                        updatedMedication.dosage = dosage
                        updatedMedication.notes = notes.isEmpty ? nil : notes
                        updatedMedication.times = times
                        updatedMedication.isActive = isActive
                        onSave(updatedMedication)
                        dismiss()
                    }
                    .disabled(name.isEmpty || dosage.isEmpty || times.isEmpty)
                }
            }
            .sheet(isPresented: $showAddTime) {
                AddTimeView { time in
                    times.append(time)
                }
            }
            .environment(\.layoutDirection, .rightToLeft)
        }
    }
}

// MARK: - Add Time View

struct AddTimeView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (MedicationTime) -> Void
    
    @State private var hour = 9
    @State private var minute = 0
    @State private var label = "صباحاً"
    
    var body: some View {
        NavigationStack {
            Form {
                Section("الوقت") {
                    Picker("الساعة", selection: $hour) {
                        ForEach(0..<24) { hour in
                            Text("\(hour)").tag(hour)
                        }
                    }
                    
                    Picker("الدقيقة", selection: $minute) {
                        ForEach(0..<60) { minute in
                            Text("\(minute)").tag(minute)
                        }
                    }
                    
                    TextField("التسمية (مثل: صباحاً)", text: $label)
                }
            }
            .navigationTitle("إضافة وقت")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إلغاء") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("إضافة") {
                        let time = MedicationTime(
                            hour: hour,
                            minute: minute,
                            label: label
                        )
                        onSave(time)
                        dismiss()
                    }
                }
            }
            .environment(\.layoutDirection, .rightToLeft)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MedicationListView()
    }
}
