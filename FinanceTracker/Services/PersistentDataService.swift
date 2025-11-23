import Foundation

// MARK: - Data Service Errors
enum DataServiceError: Error, LocalizedError {
    case transactionNotFound
    case accountNotFound
    case categoryNotFound
    case loanNotFound
    case allocationNotFound
    case memberNotFound
    
    var errorDescription: String? {
        switch self {
        case .transactionNotFound:
            return "未找到指定的交易记录"
        case .accountNotFound:
            return "未找到指定的账户"
        case .categoryNotFound:
            return "未找到指定的分类"
        case .loanNotFound:
            return "未找到指定的借贷记录"
        case .allocationNotFound:
            return "未找到指定的收入分配记录"
        case .memberNotFound:
            return "未找到指定的成员"
        }
    }
}

class PersistentDataService: DataServiceProtocol {
    private var accounts: [Account] = []
    private var transactions: [Transaction] = []
    private var categories: [Category] = []
    private var loans: [Loan] = []
    private var allocations: [IncomeAllocation] = []
    private var members: [Member] = []
    
    private let accountsKey = "FinanceTracker.Accounts"
    private let transactionsKey = "FinanceTracker.Transactions"
    private let categoriesKey = "FinanceTracker.Categories"
    private let loansKey = "FinanceTracker.Loans"
    private let allocationsKey = "FinanceTracker.Allocations"
    private let membersKey = "FinanceTracker.Members"
    
    init() {
        loadFromUserDefaults()
    }
    
    // MARK: - Account Methods
    func getAllAccounts() throws -> [Account] {
        return accounts
    }
    
    func getAccount(withId id: UUID) throws -> Account? {
        return accounts.first { $0.id == id }
    }
    
    func addAccount(_ account: Account) throws {
        accounts.append(account)
        saveToUserDefaults()
    }
    
    func updateAccount(_ account: Account) throws {
        if let index = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[index] = account
            saveToUserDefaults()
        }
    }
    
    func deleteAccount(_ account: Account) throws {
        accounts.removeAll { $0.id == account.id }
        saveToUserDefaults()
    }
    
    // MARK: - Transaction Methods
    func getAllTransactions() throws -> [Transaction] {
        return transactions
    }
    
    func getTransaction(withId id: UUID) throws -> Transaction? {
        return transactions.first { $0.id == id }
    }
    
    func getTransactions(forAccount accountId: UUID) throws -> [Transaction] {
        return transactions.filter { $0.accountId == accountId }
    }
    
    func getTransactions(by type: TransactionType) throws -> [Transaction] {
        return transactions.filter { $0.type == type }
    }
    
    func getTransactions(from startDate: Date, to endDate: Date) throws -> [Transaction] {
        return transactions.filter { $0.date >= startDate && $0.date <= endDate }
    }
    
    func getTransactions(forMember memberId: UUID) throws -> [Transaction] {
        return transactions.filter { $0.memberId == memberId }
    }
    
    func addTransaction(_ transaction: Transaction) throws {
        transactions.append(transaction)
        
        // 更新相关账户的余额
        if let accountIndex = accounts.firstIndex(where: { $0.id == transaction.accountId }) {
            var updatedAccount = accounts[accountIndex]
            switch transaction.type {
            case .income:
                updatedAccount.balance += transaction.amount
            case .expense:
                updatedAccount.balance -= transaction.amount
            }
            accounts[accountIndex] = updatedAccount
        }
        
        saveToUserDefaults()
        NotificationCenter.default.post(name: .transactionsDidUpdate, object: nil)
    }
    
    func updateTransaction(_ transaction: Transaction) throws {
        // 先找到旧的交易记录
        guard let index = transactions.firstIndex(where: { $0.id == transaction.id }) else {
            throw DataServiceError.transactionNotFound
        }
        
        let oldTransaction = transactions[index]
        
        // 如果账户ID或交易类型发生变化，需要调整两个账户的余额
        if oldTransaction.accountId != transaction.accountId || oldTransaction.type != transaction.type || oldTransaction.amount != transaction.amount {
            // 恢复旧交易对账户的影响
            if let oldAccountIndex = accounts.firstIndex(where: { $0.id == oldTransaction.accountId }) {
                var oldAccount = accounts[oldAccountIndex]
                switch oldTransaction.type {
                case .income:
                    oldAccount.balance -= oldTransaction.amount
                case .expense:
                    oldAccount.balance += oldTransaction.amount
                }
                accounts[oldAccountIndex] = oldAccount
            }
            
            // 应用新交易对账户的影响
            if let newAccountIndex = accounts.firstIndex(where: { $0.id == transaction.accountId }) {
                var newAccount = accounts[newAccountIndex]
                switch transaction.type {
                case .income:
                    newAccount.balance += transaction.amount
                case .expense:
                    newAccount.balance -= transaction.amount
                }
                accounts[newAccountIndex] = newAccount
            }
        }
        
        transactions[index] = transaction
        saveToUserDefaults()
        NotificationCenter.default.post(name: .transactionsDidUpdate, object: nil)
    }
    
    func deleteTransaction(withId id: UUID) throws {
        // 先找到要删除的交易记录
        guard let index = transactions.firstIndex(where: { $0.id == id }) else {
            throw DataServiceError.transactionNotFound
        }
        
        let transaction = transactions[index]
        
        // 恢复该交易对账户的影响
        if let accountIndex = accounts.firstIndex(where: { $0.id == transaction.accountId }) {
            var account = accounts[accountIndex]
            switch transaction.type {
            case .income:
                account.balance -= transaction.amount
            case .expense:
                account.balance += transaction.amount
            }
            accounts[accountIndex] = account
        }
        
        transactions.remove(at: index)
        saveToUserDefaults()
        NotificationCenter.default.post(name: .transactionsDidUpdate, object: nil)
    }
    
    // MARK: - Category Methods
    func getAllCategories() throws -> [Category] {
        return categories
    }
    
    func getCategory(withId id: UUID) throws -> Category? {
        return categories.first { $0.id == id }
    }
    
    func getCategories(by type: CategoryType) throws -> [Category] {
        return categories.filter { $0.type == type }
    }
    
    func addCategory(_ category: Category) throws {
        categories.append(category)
        saveToUserDefaults()
    }
    
    func updateCategory(_ category: Category) throws {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
            saveToUserDefaults()
        }
    }
    
    func deleteCategory(_ category: Category) throws {
        categories.removeAll { $0.id == category.id }
        saveToUserDefaults()
    }
    
    // MARK: - Loan Methods
    func getAllLoans() throws -> [Loan] {
        return loans
    }
    
    func getLoan(withId id: UUID) throws -> Loan? {
        return loans.first { $0.id == id }
    }
    
    func getLoans(by type: LoanType) throws -> [Loan] {
        return loans.filter { $0.type == type }
    }
    
    func getLoans(isSettled: Bool) throws -> [Loan] {
        return loans.filter { $0.isSettled == isSettled }
    }
    
    func getLoans(forMember memberId: UUID) throws -> [Loan] {
        return loans.filter { $0.memberId == memberId }
    }
    
    func addLoan(_ loan: Loan) throws {
        loans.append(loan)
        saveToUserDefaults()
    }
    
    func updateLoan(_ loan: Loan) throws {
        if let index = loans.firstIndex(where: { $0.id == loan.id }) {
            loans[index] = loan
            saveToUserDefaults()
        }
    }
    
    func deleteLoan(_ loan: Loan) throws {
        loans.removeAll { $0.id == loan.id }
        saveToUserDefaults()
    }
    
    // MARK: - Income Allocation Methods
    func getAllAllocations() throws -> [IncomeAllocation] {
        return allocations
    }
    
    func getAllocation(withId id: UUID) throws -> IncomeAllocation? {
        return allocations.first { $0.id == id }
    }
    
    func addAllocation(_ allocation: IncomeAllocation) throws {
        allocations.append(allocation)
        saveToUserDefaults()
    }
    
    func updateAllocation(_ allocation: IncomeAllocation) throws {
        if let index = allocations.firstIndex(where: { $0.id == allocation.id }) {
            allocations[index] = allocation
            saveToUserDefaults()
        }
    }
    
    func deleteAllocation(_ allocation: IncomeAllocation) throws {
        allocations.removeAll { $0.id == allocation.id }
        saveToUserDefaults()
    }
    
    // MARK: - Member Methods
    func getAllMembers() throws -> [Member] {
        return members
    }
    
    func getMember(withId id: UUID) throws -> Member? {
        return members.first { $0.id == id }
    }
    
    func addMember(_ member: Member) throws {
        members.append(member)
        saveToUserDefaults()
    }
    
    func updateMember(_ member: Member) throws {
        if let index = members.firstIndex(where: { $0.id == member.id }) {
            members[index] = member
            saveToUserDefaults()
        }
    }
    
    func deleteMember(_ member: Member) throws {
        members.removeAll { $0.id == member.id }
        saveToUserDefaults()
    }
    
    // MARK: - Private Methods
    private func saveToUserDefaults() {
        // Save accounts
        if let accountsData = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(accountsData, forKey: accountsKey)
        }
        
        // Save transactions
        if let transactionsData = try? JSONEncoder().encode(transactions) {
            UserDefaults.standard.set(transactionsData, forKey: transactionsKey)
        }
        
        // Save categories
        if let categoriesData = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(categoriesData, forKey: categoriesKey)
        }
        
        // Save loans
        if let loansData = try? JSONEncoder().encode(loans) {
            UserDefaults.standard.set(loansData, forKey: loansKey)
        }
        
        // Save allocations
        if let allocationsData = try? JSONEncoder().encode(allocations) {
            UserDefaults.standard.set(allocationsData, forKey: allocationsKey)
        }
        
        // Save members
        if let membersData = try? JSONEncoder().encode(members) {
            UserDefaults.standard.set(membersData, forKey: membersKey)
        }
    }
    
    private func loadFromUserDefaults() {
        // Load accounts
        if let accountsData = UserDefaults.standard.data(forKey: accountsKey),
           let decodedAccounts = try? JSONDecoder().decode([Account].self, from: accountsData) {
            accounts = decodedAccounts
        }
        
        // Load transactions
        if let transactionsData = UserDefaults.standard.data(forKey: transactionsKey),
           let decodedTransactions = try? JSONDecoder().decode([Transaction].self, from: transactionsData) {
            transactions = decodedTransactions
        }
        
        // Load categories
        if let categoriesData = UserDefaults.standard.data(forKey: categoriesKey),
           let decodedCategories = try? JSONDecoder().decode([Category].self, from: categoriesData) {
            categories = decodedCategories
        }
        
        // Load loans
        if let loansData = UserDefaults.standard.data(forKey: loansKey),
           let decodedLoans = try? JSONDecoder().decode([Loan].self, from: loansData) {
            loans = decodedLoans
        }
        
        // Load allocations
        if let allocationsData = UserDefaults.standard.data(forKey: allocationsKey),
           let decodedAllocations = try? JSONDecoder().decode([IncomeAllocation].self, from: allocationsData) {
            allocations = decodedAllocations
        }
        
        // Load members
        if let membersData = UserDefaults.standard.data(forKey: membersKey),
           let decodedMembers = try? JSONDecoder().decode([Member].self, from: membersData) {
            members = decodedMembers
        }
    }
}