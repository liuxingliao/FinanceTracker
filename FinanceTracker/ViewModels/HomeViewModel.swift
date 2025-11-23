import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var accounts: [Account] = []
    @Published var recentTransactions: [Transaction] = []
    @Published var recentLoans: [Loan] = []
    @Published var categories: [Category] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let dataService: DataServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(dataService: DataServiceProtocol = PersistentDataService()) {
        self.dataService = dataService
        loadData()
    }
    
    /// 加载主页数据
    func loadData() {
        isLoading = true
        do {
            accounts = try dataService.getAllAccounts()
            recentTransactions = try dataService.getAllTransactions().suffix(5) // 获取最近5条交易记录
            recentLoans = try dataService.getAllLoans().suffix(5) // 获取最近5条借贷记录
            categories = try dataService.getAllCategories()
        } catch {
            errorMessage = "加载数据失败: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    /// 获取当前总存款金额（所有账户余额总和）
    func getTotalBalance() -> Decimal {
        return accounts.reduce(0) { $0 + $1.balance }
    }
    
    /// 获取借入总额（未结算的借入）
    func getTotalBorrowedIn() -> Decimal {
        return recentLoans.filter { !$0.isSettled && $0.type == .borrowIn }
            .reduce(0) { $0 + $1.amount }
    }
    
    /// 获取借出总额（未结算的借出）
    func getTotalBorrowedOut() -> Decimal {
        return recentLoans.filter { !$0.isSettled && $0.type == .borrowOut }
            .reduce(0) { $0 + $1.amount }
    }
    
    /// 获取净存款金额
    /// 净存款 = 所有账户余额总和 - 借入总额 + 借出总额
    func getNetSavings() -> Decimal {
        let totalBalance = getTotalBalance()
        let totalBorrowedIn = getTotalBorrowedIn()
        let totalBorrowedOut = getTotalBorrowedOut()
        
        return totalBalance - totalBorrowedIn + totalBorrowedOut
    }
    
    /// 根据ID获取分类名称
    func getCategoryName(withId id: UUID) -> String? {
        return categories.first { $0.id == id }?.name
    }
    
    /// 根据ID获取账户名称
    func getAccountName(withId id: UUID) -> String? {
        return accounts.first { $0.id == id }?.name
    }
}