import Foundation

protocol DataServiceProtocol {
    // Account methods
    func getAllAccounts() throws -> [Account]
    func getAccount(withId id: UUID) throws -> Account?
    func addAccount(_ account: Account) throws
    func updateAccount(_ account: Account) throws
    func deleteAccount(_ account: Account) throws
    
    // Transaction methods
    func getAllTransactions() throws -> [Transaction]
    func getTransaction(withId id: UUID) throws -> Transaction?
    func getTransactions(forAccount accountId: UUID) throws -> [Transaction]
    func getTransactions(by type: TransactionType) throws -> [Transaction]
    func getTransactions(from startDate: Date, to endDate: Date) throws -> [Transaction]
    func getTransactions(forMember memberId: UUID) throws -> [Transaction]
    func addTransaction(_ transaction: Transaction) throws
    func updateTransaction(_ transaction: Transaction) throws
    func deleteTransaction(withId id: UUID) throws
    
    // Category methods
    func getAllCategories() throws -> [Category]
    func getCategory(withId id: UUID) throws -> Category?
    func getCategories(by type: CategoryType) throws -> [Category]
    func addCategory(_ category: Category) throws
    func updateCategory(_ category: Category) throws
    func deleteCategory(_ category: Category) throws
    
    // Loan methods
    func getAllLoans() throws -> [Loan]
    func getLoan(withId id: UUID) throws -> Loan?
    func getLoans(by type: LoanType) throws -> [Loan]
    func getLoans(isSettled: Bool) throws -> [Loan]
    func getLoans(forMember memberId: UUID) throws -> [Loan]
    func addLoan(_ loan: Loan) throws
    func updateLoan(_ loan: Loan) throws
    func deleteLoan(_ loan: Loan) throws
    
    // Income Allocation methods
    func getAllAllocations() throws -> [IncomeAllocation]
    func getAllocation(withId id: UUID) throws -> IncomeAllocation?
    func addAllocation(_ allocation: IncomeAllocation) throws
    func updateAllocation(_ allocation: IncomeAllocation) throws
    func deleteAllocation(_ allocation: IncomeAllocation) throws
    
    // Member methods
    func getAllMembers() throws -> [Member]
    func getMember(withId id: UUID) throws -> Member?
    func addMember(_ member: Member) throws
    func updateMember(_ member: Member) throws
    func deleteMember(_ member: Member) throws
}

class InMemoryDataService: DataServiceProtocol {
    private var accounts: [Account] = []
    private var transactions: [Transaction] = []
    private var categories: [Category] = []
    private var loans: [Loan] = []
    private var allocations: [IncomeAllocation] = []
    private var members: [Member] = []
    
    // MARK: - Account Methods
    func getAllAccounts() throws -> [Account] {
        return accounts
    }
    
    func getAccount(withId id: UUID) throws -> Account? {
        return accounts.first { $0.id == id }
    }
    
    func addAccount(_ account: Account) throws {
        accounts.append(account)
    }
    
    func updateAccount(_ account: Account) throws {
        if let index = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[index] = account
        }
    }
    
    func deleteAccount(_ account: Account) throws {
        accounts.removeAll { $0.id == account.id }
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
    }
    
    func updateTransaction(_ transaction: Transaction) throws {
        if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
            transactions[index] = transaction
        }
    }
    
    func deleteTransaction(withId id: UUID) throws {
        transactions.removeAll { $0.id == id }
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
    }
    
    func updateCategory(_ category: Category) throws {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
        }
    }
    
    func deleteCategory(_ category: Category) throws {
        categories.removeAll { $0.id == category.id }
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
    }
    
    func updateLoan(_ loan: Loan) throws {
        if let index = loans.firstIndex(where: { $0.id == loan.id }) {
            loans[index] = loan
        }
    }
    
    func deleteLoan(_ loan: Loan) throws {
        loans.removeAll { $0.id == loan.id }
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
    }
    
    func updateAllocation(_ allocation: IncomeAllocation) throws {
        if let index = allocations.firstIndex(where: { $0.id == allocation.id }) {
            allocations[index] = allocation
        }
    }
    
    func deleteAllocation(_ allocation: IncomeAllocation) throws {
        allocations.removeAll { $0.id == allocation.id }
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
    }
    
    func updateMember(_ member: Member) throws {
        if let index = members.firstIndex(where: { $0.id == member.id }) {
            members[index] = member
        }
    }
    
    func deleteMember(_ member: Member) throws {
        members.removeAll { $0.id == member.id }
    }
}