import SwiftUI

struct AccountsView: View {
    @StateObject private var viewModel = AccountViewModel()
    @State private var showingAddAccount = false
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("加载中...")
                } else {
                    List {
                        ForEach(viewModel.accounts) { account in
                            NavigationLink(destination: AccountDetailView(account: account)) {
                                AccountsViewRow(account: account)
                            }
                        }
                        .onDelete(perform: deleteAccounts)
                    }
                }
            }
            .navigationTitle("账户管理")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddAccount = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddAccount) {
                AddAccountView(onAdd: { name, type, balance in
                    viewModel.addAccount(name: name, type: type, balance: balance)
                })
            }
        }
        .onAppear {
            viewModel.loadAccounts()
        }
    }
    
    private func deleteAccounts(at offsets: IndexSet) {
        for index in offsets {
            let account = viewModel.accounts[index]
            viewModel.deleteAccount(account)
        }
    }
}

struct AccountsViewRow: View {
    let account: Account
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(account.name)
                    .font(.headline)
                Text(account.type.displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(formatCurrency(account.balance))
                .font(.headline)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 4)
    }
}

struct AddAccountView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var name = ""
    @State private var selectedType: AccountType = .cash
    @State private var balanceString = ""
    
    var onAdd: (String, AccountType, Decimal) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("账户信息")) {
                    TextField("账户名称", text: $name)
                    
                    Picker("账户类型", selection: $selectedType) {
                        ForEach(AccountType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    
                    TextField("初始余额", text: $balanceString)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("添加账户")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        let balance = Decimal(string: balanceString) ?? 0
                        onAdd(name, selectedType, balance)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct AccountDetailView: View {
    let account: Account
    
    var body: some View {
        Form {
            Section(header: Text("账户详情")) {
                HStack {
                    Text("账户名称")
                    Spacer()
                    Text(account.name)
                }
                
                HStack {
                    Text("账户类型")
                    Spacer()
                    Text(account.type.displayName)
                }
                
                HStack {
                    Text("账户余额")
                    Spacer()
                    Text(formatCurrency(account.balance))
                }
                
                HStack {
                    Text("创建日期")
                    Spacer()
                    Text(formatDate(account.createdDate))
                }
            }
        }
        .navigationTitle("账户详情")
    }
}

private func formatCurrency(_ amount: Decimal) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale.current
    return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "\(amount)"
}

private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
}

struct AccountsView_Previews: PreviewProvider {
    static var previews: some View {
        AccountsView()
    }
}