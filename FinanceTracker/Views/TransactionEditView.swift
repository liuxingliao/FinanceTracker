import SwiftUI

struct TransactionEditView: View {
    @Environment(\.presentationMode) var presentationMode
    
    let transaction: Transaction
    let accounts: [Account]
    let categories: [Category]
    var onEdit: (Transaction) -> Void
    var onDelete: (Transaction) -> Void
    
    @State private var amountString: String
    @State private var selectedType: TransactionType
    @State private var selectedAccountId: UUID?
    @State private var selectedCategoryId: UUID?
    @State private var date: Date
    @State private var note: String
    @State private var showingDeleteAlert = false
    
    init(transaction: Transaction, accounts: [Account], categories: [Category], onEdit: @escaping (Transaction) -> Void, onDelete: @escaping (Transaction) -> Void) {
        self.transaction = transaction
        self.accounts = accounts
        self.categories = categories
        self.onEdit = onEdit
        self.onDelete = onDelete
        
        _amountString = State(initialValue: "\(transaction.amount)")
        _selectedType = State(initialValue: transaction.type)
        _selectedAccountId = State(initialValue: transaction.accountId)
        _selectedCategoryId = State(initialValue: transaction.categoryId)
        _date = State(initialValue: transaction.date)
        _note = State(initialValue: transaction.note ?? "")
    }
    
    var body: some View {
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
                
                if !categories.isEmpty {
                    Picker("分类", selection: $selectedCategoryId) {
                        ForEach(categories.filter { $0.type.rawValue == selectedType.rawValue }, id: \.id) { category in
                            Text(category.name).tag(category.id as UUID?)
                        }
                    }
                }
                
                DatePicker("日期", selection: $date, displayedComponents: [.date, .hourAndMinute])
                
                TextField("备注", text: $note)
            }
        }
        .navigationTitle("编辑交易")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    saveTransaction()
                }
                .disabled(!isFormValid)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("删除") {
                    showingDeleteAlert = true
                }
                .foregroundColor(.red)
            }
        }
        .alert("确认删除", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                deleteTransaction()
            }
        } message: {
            Text("确定要删除这条交易记录吗？此操作无法撤销。")
        }
    }
    
    private var isFormValid: Bool {
        guard let _ = Decimal(string: amountString),
              selectedAccountId != nil,
              selectedCategoryId != nil else {
            return false
        }
        return true
    }
    
    private func saveTransaction() {
        guard let amount = Decimal(string: amountString),
              let accountId = selectedAccountId,
              let categoryId = selectedCategoryId else {
            return
        }
        
        var updatedTransaction = transaction
        updatedTransaction.amount = amount
        updatedTransaction.type = selectedType
        updatedTransaction.accountId = accountId
        updatedTransaction.categoryId = categoryId
        updatedTransaction.date = date
        updatedTransaction.note = note.isEmpty ? nil : note
        
        onEdit(updatedTransaction)
        presentationMode.wrappedValue.dismiss()
    }
    
    private func deleteTransaction() {
        onDelete(transaction)
        presentationMode.wrappedValue.dismiss()
    }
}

struct TransactionEditView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TransactionEditView(
                transaction: Transaction(
                    id: UUID(),
                    amount: 100.0,
                    type: .income,
                    accountId: UUID(),
                    categoryId: UUID(),
                    date: Date(),
                    note: "工资"
                ),
                accounts: [
                    Account(id: UUID(), name: "现金", type: .cash, balance: 500.0),
                    Account(id: UUID(), name: "储蓄卡", type: .bank, balance: 10000.0)
                ],
                categories: [
                    Category(id: UUID(), name: "工资", type: .income),
                    Category(id: UUID(), name: "餐饮", type: .expense)
                ],
                onEdit: { _ in },
                onDelete: { _ in }
            )
        }
    }
}