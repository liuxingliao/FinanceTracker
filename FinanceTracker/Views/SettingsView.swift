import SwiftUI
import Combine
import UniformTypeIdentifiers
import ObjectiveC

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
                        Text("刘星燎")
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
                Text(FormatterUtils.formatCurrency(account.balance))
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
    @State private var backupStatus: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var createdBackupURL: URL?
    @State private var showCleanConfirmation = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("点击下方按钮创建新的备份文件")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Button(action: createBackup) {
                    Text("创建备份")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                if let backupURL = createdBackupURL {
                    VStack(spacing: 10) {
                        Text("备份已创建:")
                            .font(.headline)
                        
                        Text(backupURL.lastPathComponent)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button(action: exportBackup) {
                            Text("导出备份文件")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.green)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                }
                
                Button(action: {
                    showCleanConfirmation = true
                }) {
                    Text("清理备份文件")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Text(backupStatus)
                    .font(.caption)
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
            .alert("提示", isPresented: $showAlert) {
                Button("确定") { }
            } message: {
                Text(alertMessage)
            }
            .alert("确认清理", isPresented: $showCleanConfirmation) {
                Button("取消") { }
                Button("确认清理") {
                    cleanBackupFiles()
                }
            } message: {
                Text("确定要清理默认路径下的所有备份文件吗？此操作不可撤销。")
            }
        }
    }
    
    private func createBackup() {
        backupStatus = "正在创建备份..."
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let backupURL = BackupService.shared.createBackup() {
                DispatchQueue.main.async {
                    self.createdBackupURL = backupURL
                    self.backupStatus = "备份已创建: \(backupURL.lastPathComponent)"
                    self.alertMessage = "备份文件已生成，点击导出可将其保存到您选择的位置"
                    self.showAlert = true
                }
            } else {
                DispatchQueue.main.async {
                    self.backupStatus = "备份创建失败"
                    self.alertMessage = "无法创建备份文件，请重试"
                    self.showAlert = true
                }
            }
        }
    }
    
    private func exportBackup() {
        guard let backupURL = createdBackupURL else { return }
        
        BackupService.shared.exportBackupFile(backupURL) { success in
            DispatchQueue.main.async {
                if success {
                    self.alertMessage = "备份文件已导出"
                } else {
                    self.alertMessage = "导出操作已取消或失败"
                }
                self.showAlert = true
            }
        }
    }
    
    private func cleanBackupFiles() {
        let success = BackupService.shared.cleanDefaultBackupDirectory()
        
        if success {
            // 如果当前显示的备份文件是我们刚刚清理掉的，需要清除它
            if let currentBackupURL = createdBackupURL,
               let documentsDir = BackupService.shared.getDocumentsDirectory(),
               currentBackupURL.deletingLastPathComponent() == documentsDir {
                createdBackupURL = nil
            }
            
            backupStatus = "备份文件已清理"
            alertMessage = "默认路径下的备份文件已成功清理"
        } else {
            backupStatus = "清理失败"
            alertMessage = "清理备份文件时发生错误"
        }
        showAlert = true
    }
}

struct RestoreView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var backups: [URL] = []
    @State private var selectedBackup: URL?
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showRestoreConfirmation = false
    @State private var selectedRestoreDirectory: URL?
    @State private var importStatus = ""
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Button(action: selectSingleBackupFile) {
                        Text("导入文件")
                            .font(.body)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    
                    Button(action: refreshBackups) {
                        Text("刷新")
                            .font(.body)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            .background(Color.green)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                if !importStatus.isEmpty {
                    Text(importStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                
                // 显示当前选择的目录
                if let selectedDirectory = selectedRestoreDirectory {
                    Text("当前路径: \(selectedDirectory.path)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                if backups.isEmpty {
                    VStack {
                        Text("暂无可用备份文件，请先导入文件或刷新列表")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .padding()
                        
                        // 添加一个测试按钮，用于检查文档目录
                        Button(action: checkDocumentsDirectory) {
                            Text("检查文档目录")
                                .font(.body)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                                .background(Color.orange)
                                .cornerRadius(8)
                        }
                    }
                } else {
                    List(backups, id: \.self) { backup in
                        Button(action: {
                            selectedBackup = backup
                            showRestoreConfirmation = true
                        }) {
                            VStack(alignment: .leading) {
                                Text(backup.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "_", with: " "))
                                    .font(.headline)
                                Text("创建时间: \(getFileCreationDate(backup))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                
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
            .onAppear {
                // 默认使用文档目录
                selectedRestoreDirectory = BackupService.shared.getDocumentsDirectory()
                loadBackups()
            }
            .alert("确认恢复", isPresented: $showRestoreConfirmation) {
                Button("取消") { }
                Button("确认恢复") {
                    if let backup = selectedBackup {
                        restoreBackup(backup)
                    }
                }
            } message: {
                Text("确定要从该备份恢复数据吗？这将覆盖当前的所有数据。")
            }
            .alert("提示", isPresented: $showAlert) {
                Button("确定") { 
                    if alertMessage == "数据已成功恢复" {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func selectSingleBackupFile() {
        // 创建文档选择器，现在支持XLS文件
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.data]) // 使用.data支持更多文件类型
        documentPicker.allowsMultipleSelection = false
        
        // 获取顶层视图控制器
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            importStatus = "无法获取窗口"
            return
        }
        
        guard let topViewController = getTopViewController(from: window.rootViewController) else {
            importStatus = "无法获取顶层视图控制器"
            return
        }
        
        // 创建一个强引用的委托实例
        let pickerDelegate = SingleFileDocumentPickerDelegate { url in
            // 注意：这里不能使用 [weak self]，因为 SwiftUI View 是结构体
            DispatchQueue.main.async {
                // 直接使用 self，因为这是在 SwiftUI View 中
                self.importStatus = "选择了文件: \(url.lastPathComponent)\n路径: \(url.path)"
                
                // 检查文件是否存在
                if FileManager.default.fileExists(atPath: url.path) {
                    self.importStatus += "\n文件存在"
                } else {
                    self.importStatus += "\n文件不存在"
                }
                
                // 导入选择的备份文件到应用文档目录
                self.importStatus += "\n正在导入文件..."
                DispatchQueue.global(qos: .userInitiated).async {
                    if let importedURL = BackupService.shared.importBackupFile(from: url) {
                        DispatchQueue.main.async {
                            // 直接使用 self，因为这是在 SwiftUI View 中
                            self.importStatus = "文件导入成功: \(importedURL.lastPathComponent)\n保存路径: \(importedURL.path)"
                            // 导入成功后自动刷新列表
                            self.loadBackups()
                        }
                    } else {
                        DispatchQueue.main.async {
                            // 直接使用 self，因为这是在 SwiftUI View 中
                            self.importStatus = "文件导入失败\n请检查文件权限和格式"
                        }
                    }
                }
            }
        }
        
        // 保持委托的强引用
        documentPicker.delegate = pickerDelegate
        
        // 创建一个静态键值用于关联对象
        struct StaticKeys {
            static var pickerDelegateKey = 0
        }
        
        objc_setAssociatedObject(documentPicker, &StaticKeys.pickerDelegateKey, pickerDelegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        // 展示文档选择器
        topViewController.present(documentPicker, animated: true)
    }
    
    // 获取顶层视图控制器的辅助函数
    private func getTopViewController(from viewController: UIViewController?) -> UIViewController? {
        guard let viewController = viewController else { return nil }
        
        var topViewController = viewController
        while let presentedViewController = topViewController.presentedViewController {
            topViewController = presentedViewController
        }
        
        return topViewController
    }

    // 用于保持委托引用的键
    private var pickerDelegateKey = 0
    
    private func refreshBackups() {
        loadBackups()
        importStatus = "列表已刷新"
    }
    
    private func checkDocumentsDirectory() {
        if let documentsDir = BackupService.shared.getDocumentsDirectory() {
            importStatus = "文档目录: \(documentsDir.path)"
            
            // 检查目录是否存在
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: documentsDir.path) {
                importStatus += "\n目录存在"
                
                // 尝试列出目录内容
                do {
                    let contents = try fileManager.contentsOfDirectory(atPath: documentsDir.path)
                    importStatus += "\n文件数量: \(contents.count)"
                    
                    // 查找备份文件，现在查找.csv和.json扩展名的文件（向后兼容）
                    let backupFiles = contents.filter { 
                        ($0.hasPrefix("FinanceTracker_backup_") && $0.hasSuffix(".csv")) ||
                        ($0.hasPrefix("FinanceTracker_backup_") && $0.hasSuffix(".json"))
                    }
                    importStatus += "\n备份文件数量: \(backupFiles.count)"
                    
                    // 显示前几个备份文件名
                    if !backupFiles.isEmpty {
                        let displayFiles = backupFiles.prefix(5) // 只显示前5个
                        importStatus += "\n备份文件列表:"
                        for file in displayFiles {
                            importStatus += "\n  - \(file)"
                        }
                    }
                } catch {
                    importStatus += "\n读取目录失败: \(error.localizedDescription)"
                }
            } else {
                importStatus += "\n目录不存在"
                
                // 尝试创建目录
                do {
                    try fileManager.createDirectory(at: documentsDir, withIntermediateDirectories: true, attributes: nil)
                    importStatus += "\n已创建目录"
                } catch {
                    importStatus += "\n创建目录失败: \(error.localizedDescription)"
                }
            }
        } else {
            importStatus = "无法获取文档目录"
        }
    }
    
    private func loadBackups() {
        if let directory = selectedRestoreDirectory {
            backups = BackupService.shared.getAvailableBackups(inDirectory: directory)
            importStatus = "找到 \(backups.count) 个备份文件"
        }
    }
    
    private func restoreBackup(_ backupURL: URL) {
        DispatchQueue.global(qos: .userInitiated).async {
            let success = BackupService.shared.restoreFromBackup(backupURL: backupURL)
            
            DispatchQueue.main.async {
                if success {
                    alertMessage = "数据已成功恢复"
                } else {
                    alertMessage = "恢复数据失败"
                }
                showAlert = true
            }
        }
    }
    
    private func getFileCreationDate(_ url: URL) -> String {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let creationDate = attributes[.creationDate] as? Date {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                return formatter.string(from: creationDate)
            }
        } catch {
            print("无法获取文件创建日期: \(error)")
        }
        return "未知"
    }
}

class SingleFileDocumentPickerDelegate: NSObject, UIDocumentPickerDelegate {
    private let completion: (URL) -> Void
    
    init(completion: @escaping (URL) -> Void) {
        self.completion = completion
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let selectedURL = urls.first {
            completion(selectedURL)
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        // 用户取消选择
    }
}

class RestoreDocumentPickerDelegate: NSObject, UIDocumentPickerDelegate {
    private let completion: (URL) -> Void
    
    init(completion: @escaping (URL) -> Void) {
        self.completion = completion
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let selectedURL = urls.first {
            completion(selectedURL)
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        // 用户取消选择
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
