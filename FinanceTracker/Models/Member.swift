import Foundation

// MARK: - Member
struct Member: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var avatar: String?
    var createdDate: Date
    var isActive: Bool
    
    init(id: UUID = UUID(), name: String, avatar: String? = nil, createdDate: Date = Date(), isActive: Bool = true) {
        self.id = id
        self.name = name
        self.avatar = avatar
        self.createdDate = createdDate
        self.isActive = isActive
    }
    
    static func == (lhs: Member, rhs: Member) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.avatar == rhs.avatar &&
               lhs.createdDate == rhs.createdDate &&
               lhs.isActive == rhs.isActive
    }
}