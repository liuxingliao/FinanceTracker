import SwiftUI

struct ExpenseView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var accountViewModel: AccountViewModel
    @ObservedObject var categoryViewModel: CategoryViewModel
    @ObservedObject var memberViewModel: MemberViewModel
    
    @State private var amountString = ""
    @State private var selectedAccountId: UUID?
    @State private var selectedCategoryId: UUID?
    @State private var selectedMemberId: UUID?
    @State private var date = Date()
    @State private var note = ""
    
    var onAdd: (Decimal, TransactionType, UUID, UUID, UUID?, Date, String?) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("支出信息")) {
                    TextField("金额", text: $amountString)
                        .keyboardType(.decimalPad)
                    
                    if !accountViewModel.accounts.isEmpty {
                        Picker("账户", selection: $selectedAccountId) {
                            Text("请选择账户").tag(nil as UUID?)
                            ForEach(accountViewModel.accounts, id: \.id) { account in
                                HStack {
                                    Text(account.name)
                                    Spacer()
                                    Text(formatCurrency(account.balance))
                                        .foregroundColor(.secondary)
                                        .font(.subheadline)
                                }
                                .tag(account.id as UUID?)
                            }
                        }
                    }
                    
                    if !categoryViewModel.getExpenseCategories().isEmpty {
                        Picker("分类", selection: $selectedCategoryId) {
                            Text("请选择分类").tag(nil as UUID?)
                            ForEach(categoryViewModel.getExpenseCategories(), id: \.id) { category in
                                Text(category.name).tag(category.id as UUID?)
                            }
                        }
                    }
                    
                    if !memberViewModel.members.isEmpty {
                        Picker("成员", selection: $selectedMemberId) {
                            Text("请选择成员").tag(nil as UUID?)
                            ForEach(memberViewModel.members.filter { $0.isActive }, id: \.id) { member in
                                Text(member.name).tag(member.id as UUID?)
                            }
                        }
                    }
                    
                    DatePicker("日期", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    
                    TextField("备注", text: $note)
                }
            }
            .navigationTitle("添加支出")
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
                              let categoryId = selectedCategoryId,
                              let memberId = selectedMemberId else {
                            return
                        }
                        
                        onAdd(amount, .expense, accountId, categoryId, memberId, date, note.isEmpty ? nil : note)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(selectedAccountId == nil || selectedCategoryId == nil || selectedMemberId == nil)
                }
            }
        }
        .onAppear {
            // 强制刷新数据以确保获取最新信息
            reloadData()
            
            // 监听分类更新通知
            NotificationCenter.default.addObserver(
                forName: .categoriesDidUpdate,
                object: nil,
                queue: .main
            ) { _ in
                categoryViewModel.loadCategories()
            }
            
            // 监听账户更新通知
            NotificationCenter.default.addObserver(
                forName: .accountsDidUpdate,
                object: nil,
                queue: .main
            ) { _ in
                accountViewModel.loadAccounts()
            }
            
            // 监听成员更新通知
            NotificationCenter.default.addObserver(
                forName: .membersDidUpdate,
                object: nil,
                queue: .main
            ) { _ in
                memberViewModel.loadMembers()
            }
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(self, name: .categoriesDidUpdate, object: nil)
            NotificationCenter.default.removeObserver(self, name: .accountsDidUpdate, object: nil)
            NotificationCenter.default.removeObserver(self, name: .membersDidUpdate, object: nil)
        }
        // 监听金额字符串变化，确保视图更新
        .onChange(of: amountString) { _, _ in }
    }
    
    private func reloadData() {
        memberViewModel.loadMembers()
        categoryViewModel.loadCategories()
        accountViewModel.loadAccounts()
    }
}

private func formatCurrency(_ amount: Decimal) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale.current
    return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "\(amount)"
}

struct ExpenseView_Previews: PreviewProvider {
    static var previews: some View {
        ExpenseView(
            accountViewModel: AccountViewModel(),
            categoryViewModel: CategoryViewModel(),
            memberViewModel: MemberViewModel()
        ) { _, _, _, _, _, _, _ in }
    }
}