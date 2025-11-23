import Foundation

// MARK: - Category
struct Category: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var type: CategoryType
    var icon: String?
    
    init(id: UUID = UUID(), name: String, type: CategoryType, icon: String? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.icon = icon
    }
    
    static func == (lhs: Category, rhs: Category) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.type == rhs.type &&
               lhs.icon == rhs.icon
    }
}

enum CategoryType: String, CaseIterable, Codable {
    case income = "收入"
    case expense = "支出"
}