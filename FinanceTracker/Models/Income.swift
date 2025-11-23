import Foundation

// MARK: - Income Allocation
struct IncomeAllocation: Identifiable, Codable {
    let id: UUID
    var accountId: UUID
    var percentage: Int
    var lastModified: Date
    
    init(id: UUID = UUID(), accountId: UUID, percentage: Int, lastModified: Date = Date()) {
        self.id = id
        self.accountId = accountId
        self.percentage = percentage
        self.lastModified = lastModified
    }
}

// MARK: - Allocation Log
struct AllocationLog: Identifiable, Codable {
    let id: UUID
    var allocationId: UUID
    var date: Date
    var note: String?
    
    init(id: UUID = UUID(), allocationId: UUID, date: Date, note: String? = nil) {
        self.id = id
        self.allocationId = allocationId
        self.date = date
        self.note = note
    }
}
