import Foundation
import UIKit
import UniformTypeIdentifiers

class BackupService {
    static let shared = BackupService()
    
    private init() {}
    
    /// 创建备份文件
    /// - Parameter backupDirectory: 备份目录URL，如果为nil则使用默认文档目录
    /// - Returns: 备份文件的URL，如果失败则返回nil
    func createBackup(inDirectory backupDirectory: URL? = nil) -> URL? {
        let targetDirectory = backupDirectory ?? getDocumentsDirectory()
        
        guard let targetDirectory = targetDirectory else {
            return nil
        }
        
        // 获取所有数据
        let dataService = PersistentDataService()
        
        do {
            let backupData = BackupData(
                accounts: try dataService.getAllAccounts(),
                transactions: try dataService.getAllTransactions(),
                categories: try dataService.getAllCategories(),
                loans: try dataService.getAllLoans(),
                allocations: try dataService.getAllAllocations(),
                members: try dataService.getAllMembers()
            )
            
            let jsonEncoder = JSONEncoder()
            jsonEncoder.outputFormatting = .prettyPrinted
            let data = try jsonEncoder.encode(backupData)
            
            // 创建备份文件名（带时间戳）
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let timestamp = dateFormatter.string(from: Date())
            let fileName = "FinanceTracker_backup_\(timestamp).json"
            
            let backupURL = targetDirectory.appendingPathComponent(fileName)
            
            // 检查是否可以写入目标目录
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: targetDirectory.path) {
                // 尝试写入文件
                try data.write(to: backupURL)
            } else {
                // 如果目录不存在，尝试创建它
                try fileManager.createDirectory(at: targetDirectory, withIntermediateDirectories: true, attributes: nil)
                try data.write(to: backupURL)
            }
            
            return backupURL
        } catch let error as NSError {
            print("备份创建失败: \(error)")
            return nil
        } catch {
            print("备份创建失败: \(error)")
            return nil
        }
    }
    
    /// 从指定的备份文件恢复数据
    /// - Parameter backupURL: 备份文件的URL
    /// - Returns: 是否成功恢复
    func restoreFromBackup(backupURL: URL) -> Bool {
        do {
            // 对于具有安全范围的URL，我们需要先将其保存到应用的文档目录
            let data: Data
            if backupURL.startAccessingSecurityScopedResource() {
                defer { backupURL.stopAccessingSecurityScopedResource() }
                data = try Data(contentsOf: backupURL)
            } else {
                data = try Data(contentsOf: backupURL)
            }
            
            let jsonDecoder = JSONDecoder()
            let backupData = try jsonDecoder.decode(BackupData.self, from: data)
            
            // 替换现有数据
            // 注意：由于PersistentDataService是基于UserDefaults的，我们需要重新初始化它
            // 这里我们直接操作UserDefaults
            
            // 清除现有数据
            UserDefaults.standard.removeObject(forKey: "FinanceTracker.Accounts")
            UserDefaults.standard.removeObject(forKey: "FinanceTracker.Transactions")
            UserDefaults.standard.removeObject(forKey: "FinanceTracker.Categories")
            UserDefaults.standard.removeObject(forKey: "FinanceTracker.Loans")
            UserDefaults.standard.removeObject(forKey: "FinanceTracker.Allocations")
            UserDefaults.standard.removeObject(forKey: "FinanceTracker.Members")
            
            // 保存新数据
            let jsonEncoder = JSONEncoder()
            
            if let accountsData = try? jsonEncoder.encode(backupData.accounts) {
                UserDefaults.standard.set(accountsData, forKey: "FinanceTracker.Accounts")
            }
            
            if let transactionsData = try? jsonEncoder.encode(backupData.transactions) {
                UserDefaults.standard.set(transactionsData, forKey: "FinanceTracker.Transactions")
            }
            
            if let categoriesData = try? jsonEncoder.encode(backupData.categories) {
                UserDefaults.standard.set(categoriesData, forKey: "FinanceTracker.Categories")
            }
            
            if let loansData = try? jsonEncoder.encode(backupData.loans) {
                UserDefaults.standard.set(loansData, forKey: "FinanceTracker.Loans")
            }
            
            if let allocationsData = try? jsonEncoder.encode(backupData.allocations) {
                UserDefaults.standard.set(allocationsData, forKey: "FinanceTracker.Allocations")
            }
            
            if let membersData = try? jsonEncoder.encode(backupData.members) {
                UserDefaults.standard.set(membersData, forKey: "FinanceTracker.Members")
            }
            
            // 发送通知以刷新UI
            NotificationCenter.default.post(name: .accountsDidUpdate, object: nil)
            NotificationCenter.default.post(name: .transactionsDidUpdate, object: nil)
            
            return true
        } catch {
            print("从备份恢复失败: \(error)")
            return false
        }
    }
    
    /// 将外部备份文件导入到应用的文档目录
    /// - Parameter externalURL: 外部备份文件的URL
    /// - Returns: 导入后的文件URL，如果失败则返回nil
    func importBackupFile(from externalURL: URL) -> URL? {
        guard let documentsDirectory = getDocumentsDirectory() else {
            print("无法获取文档目录")
            return nil
        }
        
        do {
            // 获取外部文件的数据
            let data: Data
            if externalURL.startAccessingSecurityScopedResource() {
                defer { externalURL.stopAccessingSecurityScopedResource() }
                data = try Data(contentsOf: externalURL)
            } else {
                data = try Data(contentsOf: externalURL)
            }
            
            // 创建目标文件名（保持原始文件名）
            let fileName = externalURL.lastPathComponent
            
            // 确保文件名以FinanceTracker_backup_开头，如果不是则添加前缀
            let finalFileName = fileName.hasPrefix("FinanceTracker_backup_") ? fileName : "FinanceTracker_backup_imported_\(fileName)"
            let targetURL = documentsDirectory.appendingPathComponent(finalFileName)
            
            // 写入数据到应用文档目录
            try data.write(to: targetURL)
            
            print("成功导入文件到: \(targetURL.path)")
            return targetURL
        } catch {
            print("导入备份文件失败: \(error)")
            return nil
        }
    }
    
    /// 获取指定目录下的所有可用备份文件
    /// - Parameter directory: 指定目录URL，如果为nil则使用默认文档目录
    /// - Returns: 备份文件URL数组
    func getAvailableBackups(inDirectory directory: URL? = nil) -> [URL] {
        let targetDirectory = directory ?? getDocumentsDirectory()
        
        guard let targetDirectory = targetDirectory else {
            return []
        }
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: targetDirectory, includingPropertiesForKeys: nil)
            let backupFiles = fileURLs.filter { $0.pathExtension == "json" && $0.lastPathComponent.contains("FinanceTracker_backup_") }
            return backupFiles.sorted { $0.lastPathComponent > $1.lastPathComponent } // 按文件名排序，最新的在前
        } catch {
            print("获取备份文件列表失败: \(error)")
            return []
        }
    }
    
    /// 清理默认路径下的所有备份文件
    /// - Returns: 是否成功清理
    func cleanDefaultBackupDirectory() -> Bool {
        guard let documentsDirectory = getDocumentsDirectory() else {
            return false
        }
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            let backupFiles = fileURLs.filter { $0.pathExtension == "json" && $0.lastPathComponent.contains("FinanceTracker_backup_") }
            
            for backupFile in backupFiles {
                try FileManager.default.removeItem(at: backupFile)
            }
            
            return true
        } catch {
            print("清理备份文件失败: \(error)")
            return false
        }
    }
    
    /// 获取文档目录
    /// - Returns: 文档目录URL
    func getDocumentsDirectory() -> URL? {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    /// 将备份文件导出到用户选择的位置
    /// - Parameters:
    ///   - backupURL: 要导出的备份文件URL
    ///   - completion: 完成回调
    func exportBackupFile(_ backupURL: URL, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            let activityVC = UIActivityViewController(activityItems: [backupURL], applicationActivities: nil)
            
            // 查找顶层视图控制器
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                completion(false)
                return
            }
            
            var topViewController = window.rootViewController
            while let presentedViewController = topViewController?.presentedViewController {
                topViewController = presentedViewController
            }
            
            activityVC.completionWithItemsHandler = { (_, completed, _, _) in
                completion(completed)
            }
            
            topViewController?.present(activityVC, animated: true)
        }
    }
}

/// 备份数据结构
struct BackupData: Codable {
    let accounts: [Account]
    let transactions: [Transaction]
    let categories: [Category]
    let loans: [Loan]
    let allocations: [IncomeAllocation]
    let members: [Member]
}