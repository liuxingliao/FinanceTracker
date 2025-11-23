import Foundation
import Combine

class MemberViewModel: ObservableObject {
    @Published var members: [Member] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let dataService: DataServiceProtocol
    
    init(dataService: DataServiceProtocol = PersistentDataService()) {
        self.dataService = dataService
        loadMembers()
    }
    
    /// 加载所有成员
    func loadMembers() {
        isLoading = true
        do {
            members = try dataService.getAllMembers()
        } catch {
            errorMessage = "加载成员失败: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    /// 添加新成员
    func addMember(name: String, avatar: String?) {
        let newMember = Member(name: name, avatar: avatar)
        do {
            try dataService.addMember(newMember)
            loadMembers() // 重新加载成员列表
        } catch {
            errorMessage = "添加成员失败: \(error.localizedDescription)"
        }
    }
    
    /// 更新成员
    func updateMember(_ member: Member) {
        do {
            try dataService.updateMember(member)
            loadMembers() // 重新加载成员列表
        } catch {
            errorMessage = "更新成员失败: \(error.localizedDescription)"
        }
    }
    
    /// 删除成员
    func deleteMember(_ member: Member) {
        do {
            try dataService.deleteMember(member)
            loadMembers() // 重新加载成员列表
        } catch {
            errorMessage = "删除成员失败: \(error.localizedDescription)"
        }
    }
    
    /// 切换成员激活状态
    func toggleMemberActive(_ member: Member) {
        var updatedMember = member
        updatedMember.isActive.toggle()
        updateMember(updatedMember)
    }
}