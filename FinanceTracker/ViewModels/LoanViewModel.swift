import Foundation
import Combine

class LoanViewModel: ObservableObject {
    @Published var loans: [Loan] = []
    @Published var accounts: [Account] = []
    @Published var members: [Member] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let dataService: DataServiceProtocol
    
    init(dataService: DataServiceProtocol = PersistentDataService()) {
        self.dataService = dataService
        loadData()
    }
    
    /// 加载所有借贷记录和账户信息
    func loadData() {
        isLoading = true
        do {
            loans = try dataService.getAllLoans()
            accounts = try dataService.getAllAccounts()
            members = try dataService.getAllMembers()
        } catch {
            errorMessage = "加载数据失败: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    /// 添加新借贷记录
    func addLoan(type: LoanType, amount: Decimal, accountId: UUID, memberId: UUID?, personName: String, date: Date, note: String?, isSettled: Bool) {
        let newLoan = Loan(type: type, amount: amount, accountId: accountId, memberId: memberId, personName: personName, date: date, note: note, isSettled: isSettled)
        do {
            try dataService.addLoan(newLoan)
            loadData() // 重新加载数据
        } catch {
            errorMessage = "添加借贷记录失败: \(error.localizedDescription)"
        }
    }
    
    /// 更新借贷记录
    func updateLoan(_ loan: Loan) {
        do {
            try dataService.updateLoan(loan)
            loadData() // 重新加载数据
        } catch {
            errorMessage = "更新借贷记录失败: \(error.localizedDescription)"
        }
    }
    
    /// 删除借贷记录
    func deleteLoan(_ loan: Loan) {
        do {
            try dataService.deleteLoan(loan)
            loadData() // 重新加载数据
        } catch {
            errorMessage = "删除借贷记录失败: \(error.localizedDescription)"
        }
    }
    
    /// 切换借贷记录的结算状态
    func toggleLoanSettled(_ loan: Loan) {
        var updatedLoan = loan
        updatedLoan.isSettled.toggle()
        updateLoan(updatedLoan)
    }
    
    /// 获取未结算的借贷记录
    func getUnsettledLoans() -> [Loan] {
        return loans.filter { !$0.isSettled }
    }
    
    /// 根据类型筛选借贷记录
    func getLoans(by type: LoanType) -> [Loan] {
        return loans.filter { $0.type == type }
    }
    
    /// 获取借入记录
    func getBorrowInLoans() -> [Loan] {
        return getLoans(by: .borrowIn)
    }
    
    /// 获取借出记录
    func getBorrowOutLoans() -> [Loan] {
        return getLoans(by: .borrowOut)
    }
    
    /// 根据成员ID筛选借贷记录
    func getLoans(forMember memberId: UUID) -> [Loan] {
        return loans.filter { $0.memberId == memberId }
    }
    
    /// 根据ID获取账户名称
    func getAccountName(withId id: UUID) -> String? {
        return accounts.first { $0.id == id }?.name
    }
    
    /// 根据ID获取成员名称
    func getMemberName(withId id: UUID) -> String? {
        return members.first { $0.id == id }?.name
    }
}