import Foundation

// MARK: - Category
struct Category: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var type: CategoryType
    var icon: String?
    var parentId: UUID? // 添加父级分类ID，如果是根分类则为nil
    
    init(id: UUID = UUID(), name: String, type: CategoryType, icon: String? = nil, parentId: UUID? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.icon = icon
        self.parentId = parentId
    }
    
    static func == (lhs: Category, rhs: Category) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.type == rhs.type &&
               lhs.icon == rhs.icon &&
               lhs.parentId == rhs.parentId
    }
}

enum CategoryType: String, CaseIterable, Codable {
    case income = "收入"
    case expense = "支出"
}