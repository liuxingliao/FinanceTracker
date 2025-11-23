import SwiftUI

struct LoanView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var accountViewModel: AccountViewModel
    @ObservedObject var memberViewModel: MemberViewModel
    
    @State private var selectedLoanType: LoanType = .borrowIn
    @State private var amountString = ""
    @State private var selectedAccountId: UUID?
    @State private var selectedMemberId: UUID?
    @State private var personName = ""
    @State private var date = Date()
    @State private var note = ""
    
    var onAdd: (LoanType, Decimal, UUID, UUID?, String, Date, String?, Bool) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("借贷信息")) {
                    Picker("借贷类型", selection: $selectedLoanType) {
                        ForEach(LoanType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    TextField("金额", text: $amountString)
                        .keyboardType(.decimalPad)
                    
                    if !accountViewModel.accounts.isEmpty {
                        Picker("账户", selection: $selectedAccountId) {
                            Text("请选择账户").tag(nil as UUID?)
                            ForEach(accountViewModel.accounts, id: \.id) { account in
                                Text(account.name).tag(account.id as UUID?)
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
                    
                    TextField("对方姓名", text: $personName)
                    
                    DatePicker("日期", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    
                    TextField("备注", text: $note)
                }
            }
            .navigationTitle("添加借贷")
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
                              let memberId = selectedMemberId,
                              !personName.isEmpty else {
                            return
                        }
                        
                        onAdd(selectedLoanType, amount, accountId, memberId, personName, date, note.isEmpty ? nil : note, false)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(selectedAccountId == nil || selectedMemberId == nil || personName.isEmpty)
                }
            }
        }
        .onAppear {
            // 加载数据
            memberViewModel.loadMembers()
            accountViewModel.loadAccounts()
        }
    }
}

struct LoanView_Previews: PreviewProvider {
    static var previews: some View {
        LoanView(
            accountViewModel: AccountViewModel(),
            memberViewModel: MemberViewModel()
        ) { _, _, _, _, _, _, _, _ in }
    }
}