import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var accountViewModel = AccountViewModel()
    @StateObject private var categoryViewModel = CategoryViewModel()
    @StateObject private var memberViewModel = MemberViewModel()
    
    @State private var showingIncomeView = false
    @State private var showingExpenseView = false
    @State private var showingLoanView = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                // 财务概览
                FinancialSummaryView(
                    totalBalance: viewModel.getTotalBalance(),
                    netSavings: viewModel.getNetSavings(),
                    borrowedIn: viewModel.getTotalBorrowedIn(),
                    borrowedOut: viewModel.getTotalBorrowedOut()
                )
                
                // 快捷操作按钮
                QuickActionsView(
                    onIncomeTap: {
                        reloadData()
                        showingIncomeView = true
                    },
                    onExpenseTap: {
                        reloadData()
                        showingExpenseView = true
                    },
                    onLoanTap: {
                        reloadData()
                        showingLoanView = true
                    }
                )
                
                // 账户余额概览
                AccountsSummaryView(accounts: viewModel.accounts)
            }
            .navigationTitle("首页")
            .refreshable {
                viewModel.loadData()
            }
        }
        .onAppear {
            viewModel.loadData()
            // 监听账户更新通知
            NotificationCenter.default.addObserver(
                forName: .accountsDidUpdate,
                object: nil,
                queue: .main
            ) { _ in
                viewModel.loadData()
            }
            
            // 监听分类更新通知
            NotificationCenter.default.addObserver(
                forName: .categoriesDidUpdate,
                object: nil,
                queue: .main
            ) { _ in
                viewModel.loadData()
            }
            
            // 监听成员更新通知
            NotificationCenter.default.addObserver(
                forName: .membersDidUpdate,
                object: nil,
                queue: .main
            ) { _ in
                viewModel.loadData()
            }
            
            // 监听交易更新通知
            NotificationCenter.default.addObserver(
                forName: .transactionsDidUpdate,
                object: nil,
                queue: .main
            ) { _ in
                viewModel.loadData()
            }
        }
        .onDisappear {
            // 移除通知监听
            NotificationCenter.default.removeObserver(self, name: .accountsDidUpdate, object: nil)
            NotificationCenter.default.removeObserver(self, name: .categoriesDidUpdate, object: nil)
            NotificationCenter.default.removeObserver(self, name: .membersDidUpdate, object: nil)
            NotificationCenter.default.removeObserver(self, name: .transactionsDidUpdate, object: nil)
        }
        .sheet(isPresented: $showingIncomeView) {
            IncomeView(
                accountViewModel: accountViewModel,
                categoryViewModel: categoryViewModel,
                memberViewModel: memberViewModel
            ) { amount, type, accountId, categoryId, memberId, date, note in
                // 处理收入添加逻辑
                let transactionViewModel = TransactionViewModel()
                transactionViewModel.addTransaction(
                    amount: amount,
                    type: type,
                    accountId: accountId,
                    categoryId: categoryId,
                    memberId: memberId,
                    date: date,
                    note: note
                )
                // 发送交易更新通知
                NotificationCenter.default.post(name: .transactionsDidUpdate, object: nil)
                // 刷新主页数据
                viewModel.loadData()
                // 更新各个ViewModel数据
                reloadData()
            }
        }
        .sheet(isPresented: $showingExpenseView) {
            ExpenseView(
                accountViewModel: accountViewModel,
                categoryViewModel: categoryViewModel,
                memberViewModel: memberViewModel
            ) { amount, type, accountId, categoryId, memberId, date, note in
                // 处理支出添加逻辑
                let transactionViewModel = TransactionViewModel()
                transactionViewModel.addTransaction(
                    amount: amount,
                    type: type,
                    accountId: accountId,
                    categoryId: categoryId,
                    memberId: memberId,
                    date: date,
                    note: note
                )
                // 发送交易更新通知
                NotificationCenter.default.post(name: .transactionsDidUpdate, object: nil)
                // 刷新主页数据
                viewModel.loadData()
                // 更新各个ViewModel数据
                reloadData()
            }
        }
        .sheet(isPresented: $showingLoanView) {
            LoanView(
                accountViewModel: accountViewModel,
                memberViewModel: memberViewModel
            ) { loanType, amount, accountId, memberId, personName, date, note, isSettled in
                // 处理借贷添加逻辑
                let loanViewModel = LoanViewModel()
                loanViewModel.addLoan(
                    type: loanType,
                    amount: amount,
                    accountId: accountId,
                    memberId: memberId,
                    personName: personName,
                    date: date,
                    note: note,
                    isSettled: isSettled
                )
                // 发送交易更新通知
                NotificationCenter.default.post(name: .transactionsDidUpdate, object: nil)
                // 刷新主页数据
                viewModel.loadData()
                // 更新各个ViewModel数据
                reloadData()
            }
        }
    }
    
    /// 强制刷新所有ViewModel数据
    private func reloadData() {
        accountViewModel.loadAccounts()
        accountViewModel.loadAllocations()
        categoryViewModel.loadCategories()
        memberViewModel.loadMembers()
    }
}

// 财务概览视图
struct FinancialSummaryView: View {
    let totalBalance: Decimal
    let netSavings: Decimal
    let borrowedIn: Decimal
    let borrowedOut: Decimal
    
    var body: some View {
        VStack(spacing: 12) {
            // 当前总存款
            HStack {
                Text("当前总存款")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formatCurrency(totalBalance))
                    .font(.body)
                    .fontWeight(.medium)
            }
            
            // 净存款
            HStack {
                Text("净存款")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formatCurrency(netSavings))
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            Divider()
            
            // 借入金额
            HStack {
                Text("借入")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formatCurrency(borrowedIn))
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
            }
            
            // 借出金额
            HStack {
                Text("借出")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formatCurrency(borrowedOut))
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

// 账户余额概览视图
struct AccountsSummaryView: View {
    let accounts: [Account]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("账户余额")
                .font(.headline)
                .padding(.horizontal)
            
            // 使用LazyVGrid实现一行两列的布局
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(accounts) { account in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(account.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(account.type.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(formatCurrency(account.balance))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}

// 快捷操作按钮视图
struct QuickActionsView: View {
    let onIncomeTap: () -> Void
    let onExpenseTap: () -> Void
    let onLoanTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("快速记录")
                .font(.headline)
                .padding(.horizontal)
            
            HStack(spacing: 16) {
                Button(action: onIncomeTap) {
                    QuickActionButton(title: "收入", color: .green)
                }
                
                Button(action: onExpenseTap) {
                    QuickActionButton(title: "支出", color: .red)
                }
                
                Button(action: onLoanTap) {
                    QuickActionButton(title: "借贷", color: .orange)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}

// 快捷操作按钮
struct QuickActionButton: View {
    let title: String
    let color: Color
    
    var body: some View {
        VStack {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Circle()
                        .stroke(color, lineWidth: 2)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: title == "收入" ? "arrow.down" : 
                                  title == "支出" ? "arrow.up" : "arrow.left.arrow.right")
                                .foregroundColor(color)
                        )
                )
            
            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
        }
    }
}

// 货币格式化函数
private func formatCurrency(_ amount: Decimal) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale.current
    return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "\(amount)"
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}