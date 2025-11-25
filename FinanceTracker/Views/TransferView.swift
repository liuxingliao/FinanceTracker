import SwiftUI
import Combine

struct TransferView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var accountViewModel: AccountViewModel
    @ObservedObject var memberViewModel: MemberViewModel
    
    @State private var amountString = ""
    @State private var selectedFromAccountId: UUID?
    @State private var selectedToAccountId: UUID?
    @State private var selectedMemberId: UUID?
    @State private var date = Date()
    @State private var note = ""
    
    var onAdd: (Decimal, UUID, UUID, UUID?, Date, String?) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("转账信息")) {
                    TextField("金额", text: $amountString)
                        .keyboardType(.decimalPad)
                    
                    if !accountViewModel.accounts.isEmpty {
                        Picker("转出账户", selection: $selectedFromAccountId) {
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
                        
                        Picker("转入账户", selection: $selectedToAccountId) {
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
            .navigationTitle("转账")
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
                              let fromAccountId = selectedFromAccountId,
                              let toAccountId = selectedToAccountId,
                              let memberId = selectedMemberId,
                              fromAccountId != toAccountId else {
                            return
                        }
                        
                        onAdd(amount, fromAccountId, toAccountId, memberId, date, note.isEmpty ? nil : note)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(selectedFromAccountId == nil || 
                             selectedToAccountId == nil || 
                             selectedMemberId == nil ||
                             (selectedFromAccountId != nil && selectedToAccountId != nil && selectedFromAccountId == selectedToAccountId) ||
                             amountString.isEmpty)
                }
            }
        }
        .onAppear {
            // 强制刷新数据以确保获取最新信息
            reloadData()
            
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
            NotificationCenter.default.removeObserver(self, name: .accountsDidUpdate, object: nil)
            NotificationCenter.default.removeObserver(self, name: .membersDidUpdate, object: nil)
        }
        // 监听金额字符串变化，确保视图更新
        .onChange(of: amountString) { _, _ in }
    }
    
    private func reloadData() {
        memberViewModel.loadMembers()
        accountViewModel.loadAccounts()
    }
}

private func formatCurrency(_ amount: Decimal) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale.current
    return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "\(amount)"
}

struct TransferView_Previews: PreviewProvider {
    static var previews: some View {
        TransferView(
            accountViewModel: AccountViewModel(),
            memberViewModel: MemberViewModel()
        ) { _, _, _, _, _, _ in }
    }
}