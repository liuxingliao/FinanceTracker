import SwiftUI

struct TransactionsView: View {
    @StateObject private var viewModel = TransactionViewModel()
    @State private var showingAddTransaction = false
    @State private var groupMode: GroupMode = .day // 默认按天分组
    @State private var expandedGroups: Set<Date> = [] // 记录展开的分组
    
    // 分组模式枚举
    enum GroupMode: String, CaseIterable {
        case day = "天"
        case week = "周"
        case month = "月"
        case year = "年"
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("加载中...")
                } else {
                    transactionsListView
                }
            }
            .navigationTitle("交易记录")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddTransaction = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Picker(selection: $groupMode, label: EmptyView()) {
                            ForEach(GroupMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                    } label: {
                        Label("分组", systemImage: "line.horizontal.3.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView(
                    accounts: viewModel.accounts,
                    categories: viewModel.categories,
                    members: viewModel.members,
                    onAdd: { amount, type, accountId, categoryId, memberId, date, note in
                        viewModel.addTransaction(
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
                    }
                )
            }
        }
        .onAppear {
            viewModel.loadData()
            
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
            NotificationCenter.default.removeObserver(self, name: .transactionsDidUpdate, object: nil)
        }
    }
    
    private var transactionsListView: some View {
        List {
            // 按日期倒序排列分组，确保最新的分组在最上面
            ForEach(groupedTransactions.keys.sorted(by: >), id: \.self) { date in
                Section(header: groupHeader(for: date, records: groupedTransactions[date] ?? [])) {
                    if expandedGroups.contains(date) {
                        // 分组内的交易也按日期倒序排列，最新的交易在分组顶部
                        let records = groupedTransactions[date] ?? []
                        // 先按照日期排序，然后显示
                        let sortedRecords = records.sorted { (first, second) -> Bool in
                            let firstDate: Date
                            let secondDate: Date
                            
                            if let transaction = first as? Transaction {
                                firstDate = transaction.date
                            } else if let loan = first as? Loan {
                                firstDate = loan.date
                            } else {
                                firstDate = Date.distantPast
                            }
                            
                            if let transaction = second as? Transaction {
                                secondDate = transaction.date
                            } else if let loan = second as? Loan {
                                secondDate = loan.date
                            } else {
                                secondDate = Date.distantPast
                            }
                            
                            return firstDate > secondDate
                        }
                        
                        ForEach(Array(sortedRecords.enumerated()), id: \.offset) { _, record in
                            if let transaction = record as? Transaction {
                                NavigationLink(
                                    destination: TransactionEditView(
                                        transaction: transaction,
                                        accounts: viewModel.accounts,
                                        categories: viewModel.categories,
                                        onEdit: { updatedTransaction in
                                            viewModel.updateTransaction(updatedTransaction)
                                        },
                                        onDelete: { deletedTransaction in
                                            viewModel.deleteTransaction(deletedTransaction)
                                        }
                                    )
                                ) {
                                    TransactionRowView(
                                        transaction: transaction,
                                        accountName: viewModel.getAccountName(withId: transaction.accountId) ?? "未知账户",
                                        categoryName: viewModel.getCategoryName(withId: transaction.categoryId) ?? "未知分类"
                                    )
                                }
                            } else if let loan = record as? Loan {
                                // 贷款记录视图
                                LoanRowView(
                                    loan: loan,
                                    accountName: viewModel.getAccountName(withId: loan.accountId) ?? "未知账户",
                                    memberName: loan.memberId != nil ? (viewModel.getMemberName(withId: loan.memberId!) ?? "未知成员") : ""
                                )
                            }
                        }
                    }
                }
            }
        }
    }
    
    // 创建分组头部视图，包含展开/收缩功能和统计信息
    private func groupHeader(for date: Date, records: [Any]) -> some View {
        let isExpanded = expandedGroups.contains(date)
        let stats = calculateGroupStatistics(records: records)
        
        return HStack {
            // 展开/收缩按钮
            Button(action: {
                if isExpanded {
                    expandedGroups.remove(date)
                } else {
                    expandedGroups.insert(date)
                }
            }) {
                Image(systemName: isExpanded ? "chevron.down.circle.fill" : "chevron.right.circle.fill")
                    .foregroundColor(.blue)
                    .imageScale(.large)
            }
            .buttonStyle(PlainButtonStyle())
            
            // 日期标题
            Text(formattedDateHeader(date))
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            // 统计信息卡片
            HStack(spacing: 12) {
                if stats.totalIncome > 0 {
                    VStack(alignment: .center, spacing: 2) {
                        Text("收入")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(formatCurrency(stats.totalIncome))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                }
                
                if stats.totalExpense > 0 {
                    VStack(alignment: .center, spacing: 2) {
                        Text("支出")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(formatCurrency(stats.totalExpense))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                }
                
                VStack(alignment: .center, spacing: 2) {
                    Text("净收入")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(stats.netIncome))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(stats.netIncome >= 0 ? .red : .green)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .padding(.vertical, 6)
    }
    
    // 计算分组统计信息
    private func calculateGroupStatistics(records: [Any]) -> (totalIncome: Decimal, totalExpense: Decimal, netIncome: Decimal) {
        var totalIncome: Decimal = 0
        var totalExpense: Decimal = 0
        
        for record in records {
            if let transaction = record as? Transaction {
                switch transaction.type {
                case .income:
                    totalIncome += transaction.amount
                case .expense:
                    totalExpense += transaction.amount
                case .transfer:
                    // 转账不影响总收入和总支出的计算
                    break
                }
            } else if let loan = record as? Loan {
                // 贷款不影响收入支出统计，但影响净收入
                // 借入算作收入，借出算作支出
                switch loan.type {
                case .borrowIn:
                    totalIncome += loan.amount
                case .borrowOut:
                    totalExpense += loan.amount
                }
            }
        }
        
        let netIncome = totalIncome - totalExpense
        return (totalIncome, totalExpense, netIncome)
    }
    
    private var groupedTransactions: [Date: [Any]] {
        // 合并交易和借贷记录
        var allRecords: [Any] = []
        allRecords.append(contentsOf: viewModel.transactions)
        allRecords.append(contentsOf: viewModel.loans)
        
        // 根据分组模式进行分组
        let grouped = Dictionary(grouping: allRecords) { record in
            let date: Date
            if let transaction = record as? Transaction {
                date = transaction.date
            } else if let loan = record as? Loan {
                date = loan.date
            } else {
                date = Date()
            }
            
            switch groupMode {
            case .day:
                return Calendar.current.startOfDay(for: date)
            case .week:
                // 获取该日期所在周的第一天
                var components = Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
                components.weekday = 2 // 周一作为一周的开始
                return Calendar.current.date(from: components) ?? Date()
            case .month:
                // 获取该日期所在月的第一天
                var components = Calendar.current.dateComponents([.year, .month], from: date)
                components.day = 1
                return Calendar.current.date(from: components) ?? Date()
            case .year:
                // 获取该日期所在年的第一天
                var components = Calendar.current.dateComponents([.year], from: date)
                components.month = 1
                components.day = 1
                return Calendar.current.date(from: components) ?? Date()
            }
        }
        return grouped
    }
    
    private func formattedDateHeader(_ date: Date) -> String {
        let today = Date()
        let calendar = Calendar.current
        
        switch groupMode {
        case .day:
            let startOfToday = calendar.startOfDay(for: today)
            let startOfDay = calendar.startOfDay(for: date)
            let yesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday)!
            
            if startOfDay == startOfToday {
                return "今天"
            } else if startOfDay == yesterday {
                return "昨天"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MM月dd日 EEEE"
                return formatter.string(from: date)
            }
            
        case .week:
            // 格式化周显示
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy年MM月第ww周"
            return formatter.string(from: date)
            
        case .month:
            // 格式化月显示
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy年MM月"
            return formatter.string(from: date)
            
        case .year:
            // 格式化年显示
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy年"
            return formatter.string(from: date)
        }
    }
}

struct TransactionRowView: View {
    let transaction: Transaction
    let accountName: String
    let categoryName: String
    
    var body: some View {
        HStack {
            // 分类图标和名称
            VStack(alignment: .center) {
                Circle()
                    .fill(transaction.type == .income ? Color.red : 
                          transaction.type == .expense ? Color.green : Color.blue)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: transaction.type == .income ? "arrow.down" : 
                              transaction.type == .expense ? "arrow.up" : "arrow.right.arrow.left")
                            .foregroundColor(.white)
                    )
                
                Text(transaction.type == .transfer ? "转账" : categoryName)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: 60)
            
            // 交易详情
            VStack(alignment: .leading, spacing: 4) {
                Text(accountName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let note = transaction.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Text(formatDateTime(transaction.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 金额
            VStack(alignment: .trailing) {
                Text(formatCurrency(transaction.amount))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(transaction.type == .income ? .red : 
                                   transaction.type == .expense ? .green : .blue)
            }
        }
        .padding(.vertical, 8)
    }
}

struct LoanRowView: View {
    let loan: Loan
    let accountName: String
    let memberName: String
    
    var body: some View {
        HStack {
            // 贷款类型图标
            VStack(alignment: .center) {
                Circle()
                    .fill(loan.type == .borrowIn ? Color.red : Color.green)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "circle.fill")
                            .foregroundColor(.yellow)
                    )
                    .overlay(
                        Image(systemName: "circle")
                            .foregroundColor(.orange)
                    )
                
                Text(loan.type == .borrowIn ? "借入" : "借出")
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 60)
            
            // 贷款详情
            VStack(alignment: .leading, spacing: 4) {
                Text(accountName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if !memberName.isEmpty && memberName != "未知成员" {
                    Text(memberName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let note = loan.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Text(formatDateTime(loan.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if loan.isSettled {
                    Text("已结算")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            // 贷款金额
            VStack(alignment: .trailing) {
                Text(formatCurrency(loan.amount))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(loan.type == .borrowIn ? .red : .green)
            }
        }
        .padding(.vertical, 8)
    }
}

struct AddTransactionView: View {
    @Environment(\.presentationMode) var presentationMode
    
    let accounts: [Account]
    let categories: [Category]
    let members: [Member]
    var onAdd: (Decimal, TransactionType, UUID, UUID, UUID?, Date, String?) -> Void
    
    @State private var amountString = ""
    @State private var selectedType: TransactionType = .expense
    @State private var selectedAccountId: UUID?
    @State private var selectedCategoryId: UUID?
    @State private var selectedMemberId: UUID?
    @State private var date = Date()
    @State private var note = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("交易信息")) {
                    Picker("交易类型", selection: $selectedType) {
                        ForEach(TransactionType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    TextField("金额", text: $amountString)
                        .keyboardType(.decimalPad)
                    
                    if !accounts.isEmpty {
                        Picker("账户", selection: $selectedAccountId) {
                            ForEach(accounts, id: \.id) { account in
                                Text(account.name).tag(account.id as UUID?)
                            }
                        }
                    }
                    
                    // 对于转账类型，我们可能需要特殊的处理
                    if selectedType != .transfer {
                        if !categories.isEmpty {
                            Picker("分类", selection: $selectedCategoryId) {
                                ForEach(categories.filter { $0.type.rawValue == selectedType.rawValue }, id: \.id) { category in
                                    Text(category.name).tag(category.id as UUID?)
                                }
                            }
                        }
                    } else {
                        // 转账类型使用默认分类
                        Text("转账将使用默认分类")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if !members.isEmpty {
                        Picker("成员", selection: $selectedMemberId) {
                            Text("无").tag(nil as UUID?)
                            ForEach(members.filter { $0.isActive }, id: \.id) { member in
                                Text(member.name).tag(member.id as UUID?)
                            }
                        }
                    }
                    
                    DatePicker("日期", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    
                    TextField("备注", text: $note)
                }
            }
            .navigationTitle("添加交易")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        guard let amount = Decimal(string: amountString),
                              let accountId = selectedAccountId,
                              let categoryId = selectedCategoryId else {
                            // 对于转账类型，我们使用默认的分类ID
                            guard let amount = Decimal(string: amountString),
                                  let accountId = selectedAccountId else {
                                return
                            }
                            
                            let transferCategoryId = UUID() // 使用默认分类ID
                            onAdd(amount, selectedType, accountId, transferCategoryId, selectedMemberId, date, note.isEmpty ? nil : note)
                            presentationMode.wrappedValue.dismiss()
                            return
                        }
                        
                        onAdd(amount, selectedType, accountId, categoryId, selectedMemberId, date, note.isEmpty ? nil : note)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(amountString.isEmpty || selectedAccountId == nil || 
                             (selectedType != .transfer && selectedCategoryId == nil))
                }
            }
        }
    }
}

private func formatCurrency(_ amount: Decimal) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale.current
    return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "\(amount)"
}

private func formatDateTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter.string(from: date)
}

struct TransactionsView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionsView()
    }
}