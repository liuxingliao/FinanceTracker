import Foundation
import Combine

class AccountViewModel: ObservableObject {
    @Published var accounts: [Account] = []
    @Published var allocations: [IncomeAllocation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let dataService: DataServiceProtocol
    
    init(dataService: DataServiceProtocol = PersistentDataService()) {
        self.dataService = dataService
        loadAccounts()
        loadAllocations()
    }
    
    /// 加载所有账户
    func loadAccounts() {
        isLoading = true
        do {
            accounts = try dataService.getAllAccounts()
        } catch {
            errorMessage = "加载账户失败: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    /// 加载所有收入分配
    func loadAllocations() {
        isLoading = true
        do {
            allocations = try dataService.getAllAllocations()
        } catch {
            errorMessage = "加载收入分配失败: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    /// 添加新账户
    func addAccount(name: String, type: AccountType, balance: Decimal) {
        let newAccount = Account(name: name, type: type, balance: balance)
        do {
            try dataService.addAccount(newAccount)
            loadAccounts() // 重新加载账户列表
        } catch {
            errorMessage = "添加账户失败: \(error.localizedDescription)"
        }
    }
    
    /// 更新账户
    func updateAccount(_ account: Account) {
        do {
            try dataService.updateAccount(account)
            loadAccounts() // 重新加载账户列表
        } catch {
            errorMessage = "更新账户失败: \(error.localizedDescription)"
        }
    }
    
    /// 删除账户
    func deleteAccount(_ account: Account) {
        do {
            try dataService.deleteAccount(account)
            loadAccounts() // 重新加载账户列表
        } catch {
            errorMessage = "删除账户失败: \(error.localizedDescription)"
        }
    }
    
    /// 获取账户总数
    func getAccountCount() -> Int {
        return accounts.count
    }
    
    /// 获取总余额
    func getTotalBalance() -> Decimal {
        return accounts.reduce(0) { $0 + $1.balance }
    }
    
    /// 添加收入分配
    func addAllocation(accountId: UUID, percentage: Int) {
        let newAllocation = IncomeAllocation(accountId: accountId, percentage: percentage)
        do {
            try dataService.addAllocation(newAllocation)
            loadAllocations() // 重新加载分配列表
        } catch {
            errorMessage = "添加收入分配失败: \(error.localizedDescription)"
        }
    }
    
    /// 更新收入分配
    func updateAllocation(_ allocation: IncomeAllocation) {
        do {
            try dataService.updateAllocation(allocation)
            loadAllocations() // 重新加载分配列表
        } catch {
            errorMessage = "更新收入分配失败: \(error.localizedDescription)"
        }
    }
    
    /// 删除收入分配
    func deleteAllocation(_ allocation: IncomeAllocation) {
        do {
            try dataService.deleteAllocation(allocation)
            loadAllocations() // 重新加载分配列表
        } catch {
            errorMessage = "删除收入分配失败: \(error.localizedDescription)"
        }
    }
    
    /// 获取账户的分配比例
    func getAllocationPercentage(for accountId: UUID) -> Int {
        return allocations.first { $0.accountId == accountId }?.percentage ?? 0
    }
    
    /// 获取所有分配比例的总和
    func getTotalAllocationPercentage() -> Int {
        return allocations.reduce(0) { $0 + $1.percentage }
    }
}