//
//  CloudSyncManager.swift
//  Sanad
//
//  iCloud/CloudKit sync for contacts and medications
//  Requires iCloud + CloudKit capability in Xcode project settings
//  Container: iCloud.com.sanad.app
//

import Foundation
import CloudKit
import Combine

/// مدير المزامنة السحابية - Cloud Sync Manager
class CloudSyncManager: ObservableObject {

    static let shared = CloudSyncManager()

    // MARK: - Published Properties

    @Published var isSyncing: Bool = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    @Published var isCloudAvailable: Bool = false

    // MARK: - CloudKit

    private let container: CKContainer
    private let privateDB: CKDatabase

    // Record Types
    private enum RecordType {
        static let contact    = "Contact"
        static let medication = "Medication"
    }

    // MARK: - Init

    private init() {
        container = CKContainer(identifier: "iCloud.com.sanad.app")
        privateDB = container.privateCloudDatabase
        checkCloudAvailability()
    }

    // MARK: - Availability Check

    /// التحقق من توفر iCloud - Check iCloud availability
    func checkCloudAvailability() {
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    self?.isCloudAvailable = true
                    print("✅ iCloud متوفر")
                case .noAccount:
                    self?.isCloudAvailable = false
                    self?.syncError = "لا يوجد حساب iCloud. يرجى تسجيل الدخول في الإعدادات."
                    print("❌ لا يوجد حساب iCloud")
                case .restricted:
                    self?.isCloudAvailable = false
                    self?.syncError = "iCloud مقيد على هذا الجهاز."
                    print("❌ iCloud مقيد")
                case .couldNotDetermine:
                    self?.isCloudAvailable = false
                    print("⚠️ لا يمكن تحديد حالة iCloud")
                case .temporarilyUnavailable:
                    self?.isCloudAvailable = false
                    self?.syncError = "iCloud غير متوفر مؤقتاً."
                    print("⚠️ iCloud غير متوفر مؤقتاً")
                @unknown default:
                    self?.isCloudAvailable = false
                }
            }
        }
    }

    // MARK: - Full Sync

    /// مزامنة كاملة - Full sync (upload local → cloud, download cloud → local)
    func syncAll(completion: ((Bool) -> Void)? = nil) {
        guard isCloudAvailable else {
            print("⚠️ iCloud غير متوفر — تخطي المزامنة")
            completion?(false)
            return
        }

        isSyncing = true
        syncError = nil

        let group = DispatchGroup()

        group.enter()
        uploadContacts { group.leave() }

        group.enter()
        uploadMedications { group.leave() }

        group.notify(queue: .main) { [weak self] in
            self?.isSyncing = false
            self?.lastSyncDate = Date()
            print("✅ اكتملت المزامنة")
            completion?(true)
        }
    }

    // MARK: - Upload Contacts

    /// رفع جهات الاتصال - Upload contacts to CloudKit
    func uploadContacts(completion: @escaping () -> Void) {
        let contacts = StorageManager.shared.loadContacts()

        guard !contacts.isEmpty else {
            completion()
            return
        }

        var records: [CKRecord] = []

        for contact in contacts {
            let recordID = CKRecord.ID(recordName: contact.id.uuidString)
            let record = CKRecord(recordType: RecordType.contact, recordID: recordID)
            record["name"]               = contact.name as CKRecordValue
            record["phoneNumber"]        = contact.phoneNumber as CKRecordValue
            record["relationship"]       = contact.relationship as CKRecordValue
            record["isEmergencyContact"] = (contact.isEmergencyContact ? 1 : 0) as CKRecordValue
            record["isFavorite"]         = (contact.isFavorite ? 1 : 0) as CKRecordValue
            records.append(record)
        }

        let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        operation.savePolicy = .changedKeys
        operation.modifyRecordsResultBlock = { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("✅ تم رفع \(records.count) جهة اتصال إلى iCloud")
                case .failure(let error):
                    print("❌ خطأ في رفع جهات الاتصال: \(error.localizedDescription)")
                }
                completion()
            }
        }

        privateDB.add(operation)
    }

    // MARK: - Upload Medications

    /// رفع الأدوية - Upload medications to CloudKit
    func uploadMedications(completion: @escaping () -> Void) {
        let medications = StorageManager.shared.loadMedications()

        guard !medications.isEmpty else {
            completion()
            return
        }

        var records: [CKRecord] = []

        for medication in medications {
            let recordID = CKRecord.ID(recordName: medication.id.uuidString)
            let record = CKRecord(recordType: RecordType.medication, recordID: recordID)
            record["name"]      = medication.name as CKRecordValue
            record["dosage"]    = medication.dosage as CKRecordValue
            record["isActive"]  = (medication.isActive ? 1 : 0) as CKRecordValue
            record["notes"]     = (medication.notes ?? "") as CKRecordValue
            record["startDate"] = medication.startDate as CKRecordValue

            // Encode times as JSON string
            if let timesData = try? JSONEncoder().encode(medication.times),
               let timesString = String(data: timesData, encoding: .utf8) {
                record["timesJSON"] = timesString as CKRecordValue
            }

            records.append(record)
        }

        let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        operation.savePolicy = .changedKeys
        operation.modifyRecordsResultBlock = { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("✅ تم رفع \(records.count) دواء إلى iCloud")
                case .failure(let error):
                    print("❌ خطأ في رفع الأدوية: \(error.localizedDescription)")
                }
                completion()
            }
        }

        privateDB.add(operation)
    }

    // MARK: - Download Contacts

    /// تنزيل جهات الاتصال - Download contacts from CloudKit
    func downloadContacts(completion: @escaping ([Contact]) -> Void) {
        let query = CKQuery(
            recordType: RecordType.contact,
            predicate: NSPredicate(value: true)
        )

        privateDB.fetch(withQuery: query, inZoneWith: nil) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let (matchResults, _)):
                    var contacts: [Contact] = []
                    for (_, recordResult) in matchResults {
                        if case .success(let record) = recordResult {
                            if let contact = self.contactFromRecord(record) {
                                contacts.append(contact)
                            }
                        }
                    }
                    print("✅ تم تنزيل \(contacts.count) جهة اتصال من iCloud")
                    completion(contacts)

                case .failure(let error):
                    print("❌ خطأ في تنزيل جهات الاتصال: \(error.localizedDescription)")
                    completion([])
                }
            }
        }
    }

    // MARK: - Download Medications

    /// تنزيل الأدوية - Download medications from CloudKit
    func downloadMedications(completion: @escaping ([Medication]) -> Void) {
        let query = CKQuery(
            recordType: RecordType.medication,
            predicate: NSPredicate(value: true)
        )

        privateDB.fetch(withQuery: query, inZoneWith: nil) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let (matchResults, _)):
                    var medications: [Medication] = []
                    for (_, recordResult) in matchResults {
                        if case .success(let record) = recordResult {
                            if let medication = self.medicationFromRecord(record) {
                                medications.append(medication)
                            }
                        }
                    }
                    print("✅ تم تنزيل \(medications.count) دواء من iCloud")
                    completion(medications)

                case .failure(let error):
                    print("❌ خطأ في تنزيل الأدوية: \(error.localizedDescription)")
                    completion([])
                }
            }
        }
    }

    // MARK: - Restore from Cloud

    /// استعادة البيانات من السحابة - Restore data from cloud (overwrites local)
    func restoreFromCloud(completion: @escaping (Bool) -> Void) {
        guard isCloudAvailable else {
            completion(false)
            return
        }

        isSyncing = true
        let group = DispatchGroup()

        group.enter()
        downloadContacts { contacts in
            if !contacts.isEmpty {
                StorageManager.shared.saveContacts(contacts)
            }
            group.leave()
        }

        group.enter()
        downloadMedications { medications in
            if !medications.isEmpty {
                StorageManager.shared.saveMedications(medications)
            }
            group.leave()
        }

        group.notify(queue: .main) { [weak self] in
            self?.isSyncing = false
            self?.lastSyncDate = Date()
            completion(true)
        }
    }

    // MARK: - Record Converters

    private func contactFromRecord(_ record: CKRecord) -> Contact? {
        guard
            let name         = record["name"] as? String,
            let phoneNumber  = record["phoneNumber"] as? String,
            let relationship = record["relationship"] as? String
        else { return nil }

        let isEmergency = (record["isEmergencyContact"] as? Int ?? 0) == 1
        let isFavorite  = (record["isFavorite"] as? Int ?? 0) == 1
        let id          = UUID(uuidString: record.recordID.recordName) ?? UUID()

        return Contact(
            id: id,
            name: name,
            phoneNumber: phoneNumber,
            relationship: relationship,
            isEmergencyContact: isEmergency,
            isFavorite: isFavorite
        )
    }

    private func medicationFromRecord(_ record: CKRecord) -> Medication? {
        guard
            let name    = record["name"] as? String,
            let dosage  = record["dosage"] as? String
        else { return nil }

        let isActive  = (record["isActive"] as? Int ?? 1) == 1
        let notes     = record["notes"] as? String
        let startDate = record["startDate"] as? Date ?? Date()
        let id        = UUID(uuidString: record.recordID.recordName) ?? UUID()

        var times: [MedicationTime] = []
        if let timesJSON = record["timesJSON"] as? String,
           let data = timesJSON.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([MedicationTime].self, from: data) {
            times = decoded
        }

        return Medication(
            id: id,
            name: name,
            dosage: dosage,
            times: times,
            notes: notes?.isEmpty == true ? nil : notes,
            isActive: isActive,
            startDate: startDate
        )
    }

    // MARK: - Auto Sync on Foreground

    /// إعداد المزامنة التلقائية - Setup auto sync when app comes to foreground
    func setupAutoSync() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.syncAll()
        }
    }
}

// MARK: - UIApplication import
import UIKit
