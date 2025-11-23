import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @StateObject private var accountViewModel = AccountViewModel()
    @StateObject private var categoryViewModel = CategoryViewModel()
    @StateObject private var memberViewModel = MemberViewModel()
    
    @State private var showingAccountManagement = false
    @State private var showingCategoryManagement = false
    @State private var showingMemberManagement = false
    @State private var showingBackupSheet = false
    @State private var showingRestoreSheet = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("数据管理")) {
                    Button("账户管理") {
                        showingAccountManagement = true
                    }
                    
                    Button("分类管理") {
                        showingCategoryManagement = true
                    }
                    
                    Button("成员管理") {
                        showingMemberManagement = true
                    }
                }
                
                Section(header: Text("备份与恢复")) {
                    Button("本地备份") {
                        showingBackupSheet = true
                    }
                    
                    Button("本地恢复") {
                        showingRestoreSheet = true
                    }
                }
                
                Section(header: Text("关于")) {
                    HStack {
                        Text("应用版本")
                        Spacer()
                        Text("1.0.0")
                    }
                    
                    HStack {
                        Text("开发者")
                        Spacer()
                        Text("FinanceTracker Team")
                    }
                }
            }
            .navigationTitle("设置")
        }
        .sheet(isPresented: $showingAccountManagement) {
            AccountManagementView(viewModel: accountViewModel)
        }
        .sheet(isPresented: $showingCategoryManagement) {
            CategoryManagementView(viewModel: categoryViewModel)
        }
        .sheet(isPresented: $showingMemberManagement) {
            MemberManagementView(viewModel: memberViewModel)
        }
        .sheet(isPresented: $showingBackupSheet) {
            BackupView()
        }
        .sheet(isPresented: $showingRestoreSheet) {
            RestoreView()
        }
    }
}

// MARK: - Account Management View
struct AccountManagementView: View {
    @ObservedObject var viewModel: AccountViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingAddAccount = false
    @State private var editingAccount: Account?
    @State private var showingAllocationManagement = false
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("加载中...")
                } else {
                    List {
                        ForEach(viewModel.accounts) { account in
                            AccountRowView(
                                account: account,
                                allocationPercentage: viewModel.getAllocationPercentage(for: account.id)
                            ) { 
                                editingAccount = account
                            }
                        }
                        .onDelete(perform: deleteAccounts)
                        
                        Section(header: Text("账户管理")) {
                            Button("收入分配设置") {
                                showingAllocationManagement = true
                            }
                        }
                    }
                }
            }
            .navigationTitle("账户管理")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddAccount = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddAccount) {
                AccountEditView(account: nil) { name, type, balance in
                    viewModel.addAccount(name: name, type: type, balance: balance)
                }
            }
            .sheet(item: $editingAccount) { account in
                AccountEditView(
                    account: account,
                    onSave: { name, type, balance in
                        var updatedAccount = account
                        updatedAccount.name = name
                        updatedAccount.type = type
                        updatedAccount.balance = balance
                        viewModel.updateAccount(updatedAccount)
                    },
                    onSaveAllocation: { accountId, percentage in
                        // 更新分配比例
                        if let allocation = viewModel.allocations.first(where: { $0.accountId == accountId }) {
                            var updatedAllocation = allocation
                            updatedAllocation.percentage = percentage
                            viewModel.updateAllocation(updatedAllocation)
                        } else if percentage > 0 {
                            // 添加新的分配比例
                            viewModel.addAllocation(accountId: accountId, percentage: percentage)
                        }
                    },
                    currentAllocationPercentage: viewModel.getAllocationPercentage(for: account.id)
                )
            }
            .sheet(isPresented: $showingAllocationManagement) {
                AllocationManagementView(viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.loadAccounts()
            viewModel.loadAllocations()
        }
        .onChange(of: viewModel.accounts) { _, _ in
            // 当账户数据发生变化时，发送通知以便其他视图可以更新
            NotificationCenter.default.post(name: .accountsDidUpdate, object: nil)
        }
    }
    
    private func deleteAccounts(at offsets: IndexSet) {
        for index in offsets {
            let account = viewModel.accounts[index]
            viewModel.deleteAccount(account)
        }
    }
}

struct AccountRowView: View {
    let account: Account
    let allocationPercentage: Int
    let onEdit: () -> Void
    
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
            
            VStack(alignment: .trailing) {
                Text(formatCurrency(account.balance))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if allocationPercentage > 0 {
                    Text("\(allocationPercentage)%")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 4)
        .onTapGesture {
            onEdit()
        }
    }
}

struct AccountEditView: View {
    let account: Account?
    var onSave: (String, AccountType, Decimal) -> Void
    var onSaveAllocation: ((UUID, Int) -> Void)? = nil
    var currentAllocationPercentage: Int = 0
    
    @Environment(\.presentationMode) var presentationMode
    @State private var name: String
    @State private var selectedType: AccountType
    @State private var balanceString: String
    @State private var allocationPercentage: Int
    
    init(account: Account?, onSave: @escaping (String, AccountType, Decimal) -> Void, onSaveAllocation: ((UUID, Int) -> Void)? = nil, currentAllocationPercentage: Int = 0) {
        self.account = account
        self.onSave = onSave
        self.onSaveAllocation = onSaveAllocation
        self.currentAllocationPercentage = currentAllocationPercentage
        
        _name = State(initialValue: account?.name ?? "")
        _selectedType = State(initialValue: account?.type ?? .cash)
        _balanceString = State(initialValue: account != nil ? "\(account!.balance)" : "")
        _allocationPercentage = State(initialValue: currentAllocationPercentage)
    }
    
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
                
                if account != nil {
                    Section(header: Text("收入分配比例")) {
                        HStack {
                            Text("比例")
                            Spacer()
                            TextField("0", text: Binding(
                                get: { String(allocationPercentage) },
                                set: { newValue in
                                    allocationPercentage = Int(newValue.filter { "0123456789".contains($0) }) ?? 0
                                }
                            ))
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                            Text("%")
                        }
                    }
                }
            }
            .navigationTitle(account == nil ? "添加账户" : "编辑账户")
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
                        onSave(name, selectedType, balance)
                        
                        // 保存分配比例
                        if account != nil, let accountId = account?.id {
                            onSaveAllocation?(accountId, allocationPercentage)
                            // 发送账户更新通知，确保其他视图能刷新
                            NotificationCenter.default.post(name: .accountsDidUpdate, object: nil)
                        }
                        
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - Allocation Management View
struct AllocationManagementView: View {
    @ObservedObject var viewModel: AccountViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("加载中...")
                } else {
                    List {
                        ForEach(viewModel.accounts) { account in
                            AllocationRowView(
                                account: account,
                                currentPercentage: viewModel.getAllocationPercentage(for: account.id),
                                totalPercentage: viewModel.getTotalAllocationPercentage()
                            ) { percentage in
                                // 更新分配比例
                                if let allocation = viewModel.allocations.first(where: { $0.accountId == account.id }) {
                                    var updatedAllocation = allocation
                                    updatedAllocation.percentage = percentage
                                    viewModel.updateAllocation(updatedAllocation)
                                } else if percentage > 0 {
                                    // 添加新的分配比例
                                    viewModel.addAllocation(accountId: account.id, percentage: percentage)
                                }
                            }
                        }
                        
                        HStack {
                            Text("总计")
                                .font(.headline)
                            Spacer()
                            Text("\(viewModel.getTotalAllocationPercentage())%")
                                .font(.headline)
                                .foregroundColor(viewModel.getTotalAllocationPercentage() == 100 ? .green : .red)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("收入分配设置")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadAccounts()
            viewModel.loadAllocations()
        }
    }
}

struct AllocationRowView: View {
    let account: Account
    let currentPercentage: Int
    let totalPercentage: Int
    var onUpdatePercentage: (Int) -> Void
    
    @State private var percentageString: String = "0"
    
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
            
            HStack {
                TextField("0", text: $percentageString)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numberPad)
                    .frame(width: 50)
                    .onAppear {
                        percentageString = String(currentPercentage)
                    }
                    .onChange(of: percentageString) { _, newValue in
                        let value = Int(newValue.filter { "0123456789".contains($0) }) ?? 0
                        onUpdatePercentage(value)
                        // 发送账户更新通知，确保其他视图能刷新
                        NotificationCenter.default.post(name: .accountsDidUpdate, object: nil)
                    }
                
                Text("%")
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Category Management View
struct CategoryManagementView: View {
    @ObservedObject var viewModel: CategoryViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingAddCategory = false
    @State private var editingCategory: Category?
    @State private var selectedCategoryType: CategoryType = .expense
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("分类类型", selection: $selectedCategoryType) {
                    Text("支出").tag(CategoryType.expense)
                    Text("收入").tag(CategoryType.income)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if viewModel.isLoading {
                    ProgressView("加载中...")
                } else {
                    List {
                        ForEach(viewModel.getCategories(by: selectedCategoryType)) { category in
                            CategoryRowView(category: category) {
                                editingCategory = category
                            }
                        }
                        .onDelete(perform: deleteCategories)
                    }
                }
            }
            .navigationTitle("分类管理")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddCategory = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                CategoryEditView(category: nil, categoryType: selectedCategoryType) { name, type, icon in
                    viewModel.addCategory(name: name, type: type, icon: icon)
                }
            }
            .sheet(item: $editingCategory) { category in
                CategoryEditView(category: category) { name, type, icon in
                    var updatedCategory = category
                    updatedCategory.name = name
                    updatedCategory.type = type
                    updatedCategory.icon = icon
                    viewModel.updateCategory(updatedCategory)
                }
            }
        }
        .onAppear {
            viewModel.loadCategories()
        }
        .onChange(of: viewModel.categories) { _, _ in
            // 当分类数据发生变化时，发送通知以便其他视图可以更新
            NotificationCenter.default.post(name: .categoriesDidUpdate, object: nil)
        }
    }
    
    private func deleteCategories(at offsets: IndexSet) {
        let categories = viewModel.getCategories(by: selectedCategoryType)
        for index in offsets {
            let category = categories[index]
            viewModel.deleteCategory(category)
        }
    }
}

struct CategoryRowView: View {
    let category: Category
    let onEdit: () -> Void
    
    var body: some View {
        HStack {
            if let icon = category.icon {
                Image(systemName: icon)
            }
            
            Text(category.name)
                .font(.headline)
            
            Spacer()
        }
        .padding(.vertical, 4)
        .onTapGesture {
            onEdit()
        }
    }
}

struct CategoryEditView: View {
    let category: Category?
    let categoryType: CategoryType?
    var onSave: (String, CategoryType, String?) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var name: String
    @State private var selectedType: CategoryType
    @State private var icon: String = "tag"
    
    init(category: Category?, categoryType: CategoryType? = nil, onSave: @escaping (String, CategoryType, String?) -> Void) {
        self.category = category
        self.categoryType = categoryType
        self.onSave = onSave
        
        _name = State(initialValue: category?.name ?? "")
        _selectedType = State(initialValue: category?.type ?? categoryType ?? .expense)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("分类信息")) {
                    TextField("分类名称", text: $name)
                    
                    Picker("分类类型", selection: $selectedType) {
                        ForEach(CategoryType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .disabled(category != nil) // 不允许修改已有分类的类型
                    
                    Picker("图标", selection: $icon) {
                        ForEach(["tag", "cart", "house", "car", "heart", "gift"], id: \.self) { iconName in
                            HStack {
                                Image(systemName: iconName)
                                Text(iconName)
                            }
                            .tag(iconName)
                        }
                    }
                }
            }
            .navigationTitle(category == nil ? "添加分类" : "编辑分类")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        onSave(name, selectedType, icon.isEmpty ? nil : icon)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - Member Management View
struct MemberManagementView: View {
    @ObservedObject var viewModel: MemberViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingAddMember = false
    @State private var editingMember: Member?
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("加载中...")
                } else {
                    List {
                        ForEach(viewModel.members) { member in
                            MemberRowView(member: member) {
                                editingMember = member
                            }
                            .swipeActions {
                                Button(member.isActive ? "禁用" : "启用") {
                                    viewModel.toggleMemberActive(member)
                                }
                                .tint(member.isActive ? .orange : .green)
                                
                                Button("删除") {
                                    viewModel.deleteMember(member)
                                }
                                .tint(.red)
                            }
                        }
                    }
                }
            }
            .navigationTitle("成员管理")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddMember = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddMember) {
                MemberEditView(member: nil) { name, avatar in
                    viewModel.addMember(name: name, avatar: avatar)
                }
            }
            .sheet(item: $editingMember) { member in
                MemberEditView(member: member) { name, avatar in
                    var updatedMember = member
                    updatedMember.name = name
                    updatedMember.avatar = avatar
                    viewModel.updateMember(updatedMember)
                }
            }
        }
        .onAppear {
            viewModel.loadMembers()
        }
        .onChange(of: viewModel.members) { _, _ in
            // 当成员数据发生变化时，发送通知以便其他视图可以更新
            NotificationCenter.default.post(name: .membersDidUpdate, object: nil)
        }
    }
}

struct MemberRowView: View {
    let member: Member
    let onEdit: () -> Void
    
    var body: some View {
        HStack {
            if let avatar = member.avatar {
                Image(systemName: avatar)
                    .font(.title2)
            } else {
                Image(systemName: "person.circle")
                    .font(.title2)
            }
            
            VStack(alignment: .leading) {
                Text(member.name)
                    .font(.headline)
                
                Text(member.isActive ? "活跃" : "已禁用")
                    .font(.caption)
                    .foregroundColor(member.isActive ? .green : .red)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .onTapGesture {
            onEdit()
        }
    }
}

struct MemberEditView: View {
    let member: Member?
    var onSave: (String, String?) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var name: String
    @State private var avatar: String = "person"
    
    init(member: Member?, onSave: @escaping (String, String?) -> Void) {
        self.member = member
        self.onSave = onSave
        
        _name = State(initialValue: member?.name ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("成员信息")) {
                    TextField("成员姓名", text: $name)
                    
                    Picker("头像", selection: $avatar) {
                        ForEach(["person", "person.2", "person.3", "person.fill", "person.circle"], id: \.self) { iconName in
                            HStack {
                                Image(systemName: iconName)
                                Text(iconName)
                            }
                            .tag(iconName)
                        }
                    }
                }
            }
            .navigationTitle(member == nil ? "添加成员" : "编辑成员")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        onSave(name, avatar)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - Backup & Restore Views
struct BackupView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Text("本地备份功能正在开发中...")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("本地备份")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct RestoreView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Text("本地恢复功能正在开发中...")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("本地恢复")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        presentationMode.wrappedValue.dismiss()
                    }
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

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}