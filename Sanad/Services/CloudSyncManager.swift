//
//  CloudSyncManager.swift
//  Sanad
//
//  iCloud/CloudKit sync for contacts and medications
//
//  ⚠️ IMPORTANT — To enable CloudKit, do these steps in Xcode FIRST:
//    1. Select the "Sanad" target → Signing & Capabilities tab
//    2. Click "+ Capability" → choose "iCloud"
//    3. Enable the "CloudKit" checkbox
//    4. Add container identifier: iCloud.com.sanad.app
//  Then set `cloudKitEnabled = true` below.
//
//  Until those steps are done, keep `cloudKitEnabled = false`.
//  This prevents the NSException crash caused by calling
//  CKContainer(identifier:) without the entitlement.
//

import Foundation
import Combine
import UIKit
import CloudKit

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - CloudSyncManager
// ─────────────────────────────────────────────────────────────────────────────

class CloudSyncManager: ObservableObject {

    // ── Singleton ──────────────────────────────────────────────────────────
    static let shared = CloudSyncManager()

    // ── Feature flag ───────────────────────────────────────────────────────
    /// ⚠️ Keep `false` until the iCloud + CloudKit capability is added in Xcode.
    /// When `false`, every public method is a safe no-op and CKContainer is
    /// never instantiated, so the app will not crash.
    private let cloudKitEnabled: Bool = false

    // ── Published state ────────────────────────────────────────────────────
    @Published var isSyncing: Bool        = false
    @Published var lastSyncDate: Date?    = nil
    @Published var syncError: String?     = nil
    @Published var isCloudAvailable: Bool = false

    // ── Lazy CloudKit objects ──────────────────────────────────────────────
    // Optional so they are NEVER created in init().
    // They are only instantiated inside the private `ckContainer` accessor,
    // which is only reached when cloudKitEnabled == true.
    private var _ckContainer: CKContainer?
    private var _ckPrivateDB: CKDatabase?

    // ── Init ───────────────────────────────────────────────────────────────
    private init() {
        // ✅ SAFE: CKContainer(identifier:) is NOT called here.
        // Lazy creation happens in the private `ckContainer` accessor below,
        // which is only reached when cloudKitEnabled == true.
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Public API  (all safe no-ops when cloudKitEnabled == false)
    // ─────────────────────────────────────────────────────────────────────────

    func checkCloudAvailability() {
        guard cloudKitEnabled else {
            isCloudAvailable = false
            syncError = "مزامنة iCloud غير مفعّلة. يرجى تفعيل CloudKit في Xcode أولاً."
            return
        }
        performCheckCloudAvailability()
    }

    func syncAll(completion: ((Bool) -> Void)? = nil) {
        guard cloudKitEnabled, isCloudAvailable else { completion?(false); return }
        performSyncAll(completion: completion)
    }

    func uploadContacts(completion: @escaping () -> Void) {
        guard cloudKitEnabled, isCloudAvailable else { completion(); return }
        performUploadContacts(completion: completion)
    }

    func uploadMedications(completion: @escaping () -> Void) {
        guard cloudKitEnabled, isCloudAvailable else { completion(); return }
        performUploadMedications(completion: completion)
    }

    func downloadContacts(completion: @escaping ([Contact]) -> Void) {
        guard cloudKitEnabled, isCloudAvailable else { completion([]); return }
        performDownloadContacts(completion: completion)
    }

    func downloadMedications(completion: @escaping ([Medication]) -> Void) {
        guard cloudKitEnabled, isCloudAvailable else { completion([]); return }
        performDownloadMedications(completion: completion)
    }

    func restoreFromCloud(completion: @escaping (Bool) -> Void) {
        guard cloudKitEnabled, isCloudAvailable else { completion(false); return }
        performRestoreFromCloud(completion: completion)
    }

    func setupAutoSync() {
        guard cloudKitEnabled else { return }
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.syncAll()
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - CloudKit Implementation  (private — only executed when flag is true)
// ─────────────────────────────────────────────────────────────────────────────

private extension CloudSyncManager {

    // ── Lazy container accessor ────────────────────────────────────────────
    // ⚠️ CKContainer(identifier:) is called ONLY here.
    // This accessor is ONLY reached from the perform* methods.
    // The perform* methods are ONLY called when cloudKitEnabled == true.
    // Therefore, when cloudKitEnabled == false, this code is unreachable
    // and the app will never crash.
    var ckContainer: CKContainer {
        if let existing = _ckContainer { return existing }
        let c = CKContainer(identifier: "iCloud.com.sanad.app")
        _ckContainer = c
        _ckPrivateDB = c.privateCloudDatabase
        return c
    }

    var ckPrivateDB: CKDatabase {
        if let db = _ckPrivateDB { return db }
        return ckContainer.privateCloudDatabase
    }

    // ── Record type constants ──────────────────────────────────────────────
    enum RecordType {
        static let contact    = "Contact"
        static let medication = "Medication"
    }

    // ── Availability check ─────────────────────────────────────────────────
    func performCheckCloudAvailability() {
        ckContainer.accountStatus { [weak self] status, _ in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    self?.isCloudAvailable = true
                    self?.syncError = nil
                    print("✅ iCloud متوفر")
                case .noAccount:
                    self?.isCloudAvailable = false
                    self?.syncError = "لا يوجد حساب iCloud. يرجى تسجيل الدخول في الإعدادات."
                case .restricted:
                    self?.isCloudAvailable = false
                    self?.syncError = "iCloud مقيد على هذا الجهاز."
                case .couldNotDetermine:
                    self?.isCloudAvailable = false
                    self?.syncError = "تعذّر تحديد حالة iCloud."
                case .temporarilyUnavailable:
                    self?.isCloudAvailable = false
                    self?.syncError = "iCloud غير متوفر مؤقتاً."
                @unknown default:
                    self?.isCloudAvailable = false
                }
            }
        }
    }

    // ── Full sync ──────────────────────────────────────────────────────────
    func performSyncAll(completion: ((Bool) -> Void)?) {
        isSyncing = true
        syncError = nil

        let group = DispatchGroup()
        group.enter(); performUploadContacts    { group.leave() }
        group.enter(); performUploadMedications { group.leave() }

        group.notify(queue: .main) { [weak self] in
            self?.isSyncing    = false
            self?.lastSyncDate = Date()
            print("✅ اكتملت المزامنة")
            completion?(true)
        }
    }

    // ── Upload contacts ────────────────────────────────────────────────────
    func performUploadContacts(completion: @escaping () -> Void) {
        let contacts = StorageManager.shared.loadContacts()
        guard !contacts.isEmpty else { completion(); return }

        let records: [CKRecord] = contacts.map { contact in
            let record = CKRecord(
                recordType: RecordType.contact,
                recordID:   CKRecord.ID(recordName: contact.id.uuidString)
            )
            record["name"]               = contact.name               as CKRecordValue
            record["phoneNumber"]        = contact.phoneNumber        as CKRecordValue
            record["relationship"]       = contact.relationship       as CKRecordValue
            record["isEmergencyContact"] = (contact.isEmergencyContact ? 1 : 0) as CKRecordValue
            record["isFavorite"]         = (contact.isFavorite         ? 1 : 0) as CKRecordValue
            return record
        }

        let op = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        op.savePolicy = .changedKeys
        op.modifyRecordsResultBlock = { result in
            DispatchQueue.main.async {
                if case .failure(let e) = result {
                    print("❌ خطأ رفع جهات الاتصال: \(e.localizedDescription)")
                }
                completion()
            }
        }
        ckPrivateDB.add(op)
    }

    // ── Upload medications ─────────────────────────────────────────────────
    func performUploadMedications(completion: @escaping () -> Void) {
        let medications = StorageManager.shared.loadMedications()
        guard !medications.isEmpty else { completion(); return }

        let records: [CKRecord] = medications.map { med in
            let record = CKRecord(
                recordType: RecordType.medication,
                recordID:   CKRecord.ID(recordName: med.id.uuidString)
            )
            record["name"]      = med.name                as CKRecordValue
            record["dosage"]    = med.dosage              as CKRecordValue
            record["isActive"]  = (med.isActive ? 1 : 0) as CKRecordValue
            record["notes"]     = (med.notes ?? "")       as CKRecordValue
            record["startDate"] = med.startDate           as CKRecordValue
            if let data   = try? JSONEncoder().encode(med.times),
               let string = String(data: data, encoding: .utf8) {
                record["timesJSON"] = string as CKRecordValue
            }
            return record
        }

        let op = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        op.savePolicy = .changedKeys
        op.modifyRecordsResultBlock = { result in
            DispatchQueue.main.async {
                if case .failure(let e) = result {
                    print("❌ خطأ رفع الأدوية: \(e.localizedDescription)")
                }
                completion()
            }
        }
        ckPrivateDB.add(op)
    }

    // ── Download contacts ──────────────────────────────────────────────────
    func performDownloadContacts(completion: @escaping ([Contact]) -> Void) {
        let query = CKQuery(recordType: RecordType.contact,
                            predicate: NSPredicate(value: true))
        ckPrivateDB.fetch(withQuery: query, inZoneWith: nil) { [weak self] result in
            DispatchQueue.main.async {
                guard case .success(let (matchResults, _)) = result else {
                    completion([]); return
                }
                let contacts: [Contact] = matchResults.compactMap { (_, recordResult) in
                    guard case .success(let record) = recordResult else { return nil }
                    return self?.contactFromRecord(record)
                }
                completion(contacts)
            }
        }
    }

    // ── Download medications ───────────────────────────────────────────────
    func performDownloadMedications(completion: @escaping ([Medication]) -> Void) {
        let query = CKQuery(recordType: RecordType.medication,
                            predicate: NSPredicate(value: true))
        ckPrivateDB.fetch(withQuery: query, inZoneWith: nil) { [weak self] result in
            DispatchQueue.main.async {
                guard case .success(let (matchResults, _)) = result else {
                    completion([]); return
                }
                let medications: [Medication] = matchResults.compactMap { (_, recordResult) in
                    guard case .success(let record) = recordResult else { return nil }
                    return self?.medicationFromRecord(record)
                }
                completion(medications)
            }
        }
    }

    // ── Restore from cloud ─────────────────────────────────────────────────
    func performRestoreFromCloud(completion: @escaping (Bool) -> Void) {
        isSyncing = true
        let group = DispatchGroup()

        group.enter()
        performDownloadContacts { contacts in
            if !contacts.isEmpty { StorageManager.shared.saveContacts(contacts) }
            group.leave()
        }

        group.enter()
        performDownloadMedications { medications in
            if !medications.isEmpty { StorageManager.shared.saveMedications(medications) }
            group.leave()
        }

        group.notify(queue: .main) { [weak self] in
            self?.isSyncing    = false
            self?.lastSyncDate = Date()
            completion(true)
        }
    }

    // ── Record → Model converters ──────────────────────────────────────────
    func contactFromRecord(_ record: CKRecord) -> Contact? {
        guard
            let name         = record["name"]         as? String,
            let phoneNumber  = record["phoneNumber"]  as? String,
            let relationship = record["relationship"] as? String
        else { return nil }

        return Contact(
            id:                 UUID(uuidString: record.recordID.recordName) ?? UUID(),
            name:               name,
            phoneNumber:        phoneNumber,
            relationship:       relationship,
            isEmergencyContact: (record["isEmergencyContact"] as? Int ?? 0) == 1,
            isFavorite:         (record["isFavorite"]         as? Int ?? 0) == 1
        )
    }

    func medicationFromRecord(_ record: CKRecord) -> Medication? {
        guard
            let name   = record["name"]   as? String,
            let dosage = record["dosage"] as? String
        else { return nil }

        var times: [MedicationTime] = []
        if let json    = record["timesJSON"] as? String,
           let data    = json.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([MedicationTime].self, from: data) {
            times = decoded
        }

        let notes = record["notes"] as? String
        return Medication(
            id:        UUID(uuidString: record.recordID.recordName) ?? UUID(),
            name:      name,
            dosage:    dosage,
            times:     times,
            notes:     notes?.isEmpty == true ? nil : notes,
            isActive:  (record["isActive"] as? Int ?? 1) == 1,
            startDate: record["startDate"] as? Date ?? Date()
        )
    }
}
