import Foundation

// MARK: - Account
struct Account: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var type: AccountType
    var balance: Decimal
    let createdDate: Date
    
    init(id: UUID = UUID(), name: String, type: AccountType, balance: Decimal, createdDate: Date = Date()) {
        self.id = id
        self.name = name
        self.type = type
        self.balance = balance
        self.createdDate = createdDate
    }
    
    static func == (lhs: Account, rhs: Account) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.type == rhs.type &&
               lhs.balance == rhs.balance &&
               lhs.createdDate == rhs.createdDate
    }
}

enum AccountType: String, CaseIterable, Codable {
    case cash = "现金"
    case bank = "银行卡"
    case credit = "信用卡"
    case savings = "储蓄账户"
    case investment = "投资账户"
    
    var displayName: String {
        return self.rawValue
    }
}

// MARK: - Notification Name Extension
extension Notification.Name {
    static let accountsDidUpdate = Notification.Name("AccountsDidUpdate")
    static let categoriesDidUpdate = Notification.Name("CategoriesDidUpdate")
    static let membersDidUpdate = Notification.Name("MembersDidUpdate")
    static let transactionsDidUpdate = Notification.Name("TransactionsDidUpdate")
}