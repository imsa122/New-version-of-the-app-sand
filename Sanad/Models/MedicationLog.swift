import Foundation

struct MedicationLog: Identifiable, Codable {
    var id: UUID = UUID()
    var medicationID: UUID
    var date: Date
    var wasTaken: Bool
}
