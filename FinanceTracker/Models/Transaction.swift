import Foundation

// MARK: - Transaction
struct Transaction: Identifiable, Codable {
    let id: UUID
    var amount: Decimal
    var type: TransactionType
    var accountId: UUID
    var categoryId: UUID
    var memberId: UUID?  // 可选的成员关联
    var date: Date
    var note: String?
    
    init(id: UUID = UUID(), amount: Decimal, type: TransactionType, accountId: UUID, categoryId: UUID, memberId: UUID? = nil, date: Date, note: String? = nil) {
        self.id = id
        self.amount = amount
        self.type = type
        self.accountId = accountId
        self.categoryId = categoryId
        self.memberId = memberId
        self.date = date
        self.note = note
    }
}

enum TransactionType: String, CaseIterable, Codable {
    case income = "收入"
    case expense = "支出"
    case transfer = "转账"
}