import Foundation

// MARK: - Loan
struct Loan: Identifiable, Codable {
    let id: UUID
    var type: LoanType
    var amount: Decimal
    var accountId: UUID
    var memberId: UUID?  // 可选的成员关联
    var personName: String
    var date: Date
    var note: String?
    var isSettled: Bool
    
    init(id: UUID = UUID(), type: LoanType, amount: Decimal, accountId: UUID, memberId: UUID? = nil, personName: String, date: Date, note: String? = nil, isSettled: Bool = false) {
        self.id = id
        self.type = type
        self.amount = amount
        self.accountId = accountId
        self.memberId = memberId
        self.personName = personName
        self.date = date
        self.note = note
        self.isSettled = isSettled
    }
}

enum LoanType: String, CaseIterable, Codable {
    case borrowIn = "借入"
    case borrowOut = "借出"
}