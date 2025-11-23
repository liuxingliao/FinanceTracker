import Foundation
import Combine

class CategoryViewModel: ObservableObject {
    @Published var categories: [Category] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let dataService: DataServiceProtocol
    
    init(dataService: DataServiceProtocol = PersistentDataService()) {
        self.dataService = dataService
        loadCategories()
    }
    
    /// 加载所有分类
    func loadCategories() {
        isLoading = true
        do {
            categories = try dataService.getAllCategories()
        } catch {
            errorMessage = "加载分类失败: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    /// 添加新分类
    func addCategory(name: String, type: CategoryType, icon: String?) {
        let newCategory = Category(name: name, type: type, icon: icon)
        do {
            try dataService.addCategory(newCategory)
            loadCategories() // 重新加载分类列表
        } catch {
            errorMessage = "添加分类失败: \(error.localizedDescription)"
        }
    }
    
    /// 更新分类
    func updateCategory(_ category: Category) {
        do {
            try dataService.updateCategory(category)
            loadCategories() // 重新加载分类列表
        } catch {
            errorMessage = "更新分类失败: \(error.localizedDescription)"
        }
    }
    
    /// 删除分类
    func deleteCategory(_ category: Category) {
        do {
            try dataService.deleteCategory(category)
            loadCategories() // 重新加载分类列表
        } catch {
            errorMessage = "删除分类失败: \(error.localizedDescription)"
        }
    }
    
    /// 根据类型筛选分类
    func getCategories(by type: CategoryType) -> [Category] {
        return categories.filter { $0.type == type }
    }
    
    /// 获取收入分类
    func getIncomeCategories() -> [Category] {
        return getCategories(by: .income)
    }
    
    /// 获取支出分类
    func getExpenseCategories() -> [Category] {
        return getCategories(by: .expense)
    }
}