import Foundation
import Combine

class TransactionViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var loans: [Loan] = []
    @Published var accounts: [Account] = []
    @Published var categories: [Category] = []
    @Published var members: [Member] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let dataService: DataServiceProtocol
    
    init(dataService: DataServiceProtocol = PersistentDataService()) {
        self.dataService = dataService
        loadData()
    }
    
    /// 加载所有数据
    func loadData() {
        isLoading = true
        do {
            transactions = try dataService.getAllTransactions()
            loans = try dataService.getAllLoans()
            accounts = try dataService.getAllAccounts()
            categories = try dataService.getAllCategories()
            members = try dataService.getAllMembers()
        } catch {
            errorMessage = "加载数据失败: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    /// 添加新交易
    func addTransaction(amount: Decimal, type: TransactionType, accountId: UUID, categoryId: UUID, memberId: UUID?, date: Date, note: String?) {
        let newTransaction = Transaction(amount: amount, type: type, accountId: accountId, categoryId: categoryId, memberId: memberId, date: date, note: note)
        do {
            try dataService.addTransaction(newTransaction)
            loadData() // 重新加载数据
        } catch {
            errorMessage = "添加交易失败: \(error.localizedDescription)"
        }
    }
    
    /// 更新交易
    func updateTransaction(_ transaction: Transaction) {
        do {
            try dataService.updateTransaction(transaction)
            loadData() // 重新加载数据
        } catch {
            errorMessage = "更新交易失败: \(error.localizedDescription)"
        }
    }
    
    /// 删除交易
    func deleteTransaction(_ transaction: Transaction) {
        do {
            try dataService.deleteTransaction(withId: transaction.id)
            loadData() // 重新加载数据
        } catch {
            errorMessage = "删除交易失败: \(error.localizedDescription)"
        }
    }
    
    /// 根据类型筛选交易
    func getTransactions(by type: TransactionType) -> [Transaction] {
        return transactions.filter { $0.type == type }
    }
    
    /// 根据账户ID筛选交易
    func getTransactions(forAccount accountId: UUID) -> [Transaction] {
        return transactions.filter { $0.accountId == accountId }
    }
    
    /// 获取指定日期范围内的交易
    func getTransactions(from startDate: Date, to endDate: Date) -> [Transaction] {
        return transactions.filter { $0.date >= startDate && $0.date <= endDate }
    }
    
    /// 根据成员ID筛选交易
    func getTransactions(forMember memberId: UUID) -> [Transaction] {
        return transactions.filter { $0.memberId == memberId }
    }
    
    /// 根据ID获取账户名称
    func getAccountName(withId id: UUID) -> String? {
        return accounts.first { $0.id == id }?.name
    }
    
    /// 根据ID获取分类名称
    func getCategoryName(withId id: UUID) -> String? {
        return categories.first { $0.id == id }?.name
    }
    
    /// 根据ID获取成员名称
    func getMemberName(withId id: UUID) -> String? {
        return members.first { $0.id == id }?.name
    }
    
    /// 获取所有交易和借贷记录（用于流水显示）
    func getAllRecords() -> [Any] {
        var allRecords: [Any] = []
        allRecords.append(contentsOf: transactions)
        allRecords.append(contentsOf: loans)
        return allRecords
    }
}