import Foundation

class CSVProcessor {
    /// 将备份数据导出为CSV格式
    /// - Parameters:
    ///   - backupData: 备份数据
    ///   - fileURL: 目标文件URL
    /// - Returns: 是否成功
    static func exportToCSV(backupData: BackupData, to fileURL: URL) -> Bool {
        do {
            var csvContent = "FinanceTracker Backup Data\n"
            csvContent += "Exported on: \(Date())\n\n"
            
            // 导出账户数据
            csvContent += "Accounts\n"
            csvContent += "ID,Name,Type,Balance\n"
            for account in backupData.accounts {
                csvContent += "\"\(account.id)\",\"\(account.name)\",\"\(account.type.rawValue)\",\(account.balance)\n"
            }
            
            csvContent += "\n"
            
            // 导出分类数据
            csvContent += "Categories\n"
            csvContent += "ID,Name,Type,Icon,ParentID\n"
            for category in backupData.categories {
                let parentId = category.parentId?.uuidString ?? ""
                csvContent += "\"\(category.id)\",\"\(category.name)\",\"\(category.type.rawValue)\",\"\(category.icon ?? "")\",\"\(parentId)\"\n"
            }
            
            csvContent += "\n"
            
            // 导出成员数据
            csvContent += "Members\n"
            csvContent += "ID,Name,Avatar,IsActive\n"
            for member in backupData.members {
                csvContent += "\"\(member.id)\",\"\(member.name)\",\"\(member.avatar ?? "")\",\(member.isActive)\n"
            }
            
            csvContent += "\n"
            
            // 导出交易数据
            csvContent += "Transactions\n"
            csvContent += "ID,Date,Type,Amount,Description,AccountId,CategoryId,MemberId\n"
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            for transaction in backupData.transactions {
                let dateString = dateFormatter.string(from: transaction.date)
                let categoryId = transaction.categoryId.uuidString
                let memberId = transaction.memberId?.uuidString ?? ""
                csvContent += "\"\(transaction.id)\",\"\(dateString)\",\"\(transaction.type.rawValue)\",\(transaction.amount),\"\(transaction.note ?? "")\",\"\(transaction.accountId)\",\"\(categoryId)\",\"\(memberId)\"\n"
            }
            
            csvContent += "\n"
            
            // 导出借贷数据
            csvContent += "Loans\n"
            csvContent += "ID,Date,Type,Amount,Description,IsSettled,AccountId,MemberId\n"
            for loan in backupData.loans {
                let dateString = dateFormatter.string(from: loan.date)
                let memberId = loan.memberId?.uuidString ?? ""
                csvContent += "\"\(loan.id)\",\"\(dateString)\",\"\(loan.type.rawValue)\",\(loan.amount),\"\(loan.note ?? "")\",\(loan.isSettled),\"\(loan.accountId)\",\"\(memberId)\"\n"
            }
            
            csvContent += "\n"
            
            // 导出收入分配数据
            csvContent += "Income Allocations\n"
            csvContent += "ID,AccountId,Percentage,LastModified\n"
            for allocation in backupData.allocations {
                let dateString = dateFormatter.string(from: allocation.lastModified)
                csvContent += "\"\(allocation.id)\",\"\(allocation.accountId)\",\(allocation.percentage),\"\(dateString)\"\n"
            }
            
            // 写入CSV文件
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return true
        } catch {
            print("导出CSV失败: \(error)")
            return false
        }
    }
    
    /// 从CSV文件导入备份数据
    /// - Parameter fileURL: CSV文件URL
    /// - Returns: 备份数据，如果失败则返回nil
    static func importFromCSV(fileURL: URL) -> BackupData? {
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)
            
            var accounts: [Account] = []
            var categories: [Category] = []
            var members: [Member] = []
            var transactions: [Transaction] = []
            var loans: [Loan] = []
            var allocations: [IncomeAllocation] = []
            
            var currentSection = ""
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            
            for line in lines {
                if line.isEmpty { continue }
                
                if !line.contains(",") && !line.hasPrefix("\"") && !line.hasPrefix("FinanceTracker") && !line.hasPrefix("Exported on:") {
                    // 这是一个章节标题
                    currentSection = line.trimmingCharacters(in: .whitespaces)
                    continue
                }
                
                if line == "ID,Name,Type,Balance" && currentSection == "Accounts" {
                    continue // 跳过标题行
                }
                
                if line == "ID,Name,Type,Icon,ParentID" && currentSection == "Categories" {
                    continue // 跳过标题行
                }
                
                if line == "ID,Name,Avatar,IsActive" && currentSection == "Members" {
                    continue // 跳过标题行
                }
                
                if line == "ID,Date,Type,Amount,Description,AccountId,CategoryId,MemberId" && currentSection == "Transactions" {
                    continue // 跳过标题行
                }
                
                if line == "ID,Date,Type,Amount,Description,IsSettled,AccountId,MemberId" && currentSection == "Loans" {
                    continue // 跳过标题行
                }
                
                if line == "ID,AccountId,Percentage,LastModified" && currentSection == "Income Allocations" {
                    continue // 跳过标题行
                }
                
                let values = parseCSVLine(line)
                
                switch currentSection {
                case "Accounts":
                    if values.count >= 4 {
                        if let id = UUID(uuidString: values[0]),
                           let balance = Decimal(string: values[3]) {
                            let account = Account(
                                id: id,
                                name: values[1],
                                type: AccountType.allCases.first { $0.rawValue == values[2] } ?? .cash,
                                balance: balance
                            )
                            accounts.append(account)
                        }
                    }
                    
                case "Categories":
                    if values.count >= 5 {
                        if let id = UUID(uuidString: values[0]) {
                            let parentId = values[4].isEmpty ? nil : UUID(uuidString: values[4])
                            let category = Category(
                                id: id,
                                name: values[1],
                                type: CategoryType.allCases.first { $0.rawValue == values[2] } ?? .expense,
                                icon: values[3].isEmpty ? nil : values[3],
                                parentId: parentId
                            )
                            categories.append(category)
                        }
                    }
                    
                case "Members":
                    if values.count >= 4 {
                        if let id = UUID(uuidString: values[0]),
                           let isActive = Bool(values[3]) {
                            let member = Member(
                                id: id,
                                name: values[1],
                                avatar: values[2].isEmpty ? nil : values[2],
                                isActive: isActive
                            )
                            members.append(member)
                        }
                    }
                    
                case "Transactions":
                    if values.count >= 8 {
                        if let id = UUID(uuidString: values[0]),
                           let date = dateFormatter.date(from: values[1]),
                           let amount = Decimal(string: values[3]),
                           let accountId = UUID(uuidString: values[5]),
                           let typeId = TransactionType(rawValue: values[2]) {
                            let categoryId = UUID(uuidString: values[6])
                            let memberId = values[7].isEmpty ? nil : UUID(uuidString: values[7])
                            
                            let transaction = Transaction(
                                id: id,
                                amount: amount,
                                type: typeId,
                                accountId: accountId,
                                categoryId: categoryId ?? UUID(),
                                memberId: memberId,
                                date: date,
                                note: values[4].isEmpty ? nil : values[4]
                            )
                            transactions.append(transaction)
                        }
                    }
                    
                case "Loans":
                    if values.count >= 8 {
                        if let id = UUID(uuidString: values[0]),
                           let date = dateFormatter.date(from: values[1]),
                           let amount = Decimal(string: values[3]),
                           let isSettled = Bool(values[5]),
                           let accountId = UUID(uuidString: values[6]),
                           let typeId = LoanType(rawValue: values[2]) {
                            let memberId = values[7].isEmpty ? nil : UUID(uuidString: values[7])
                            
                            let loan = Loan(
                                id: id,
                                type: typeId,
                                amount: amount,
                                accountId: accountId,
                                memberId: memberId,
                                personName: values[4],
                                date: date,
                                note: values[4].isEmpty ? nil : values[4],
                                isSettled: isSettled
                            )
                            loans.append(loan)
                        }
                    }
                    
                case "Income Allocations":
                    if values.count >= 4 {
                        if let id = UUID(uuidString: values[0]),
                           let accountId = UUID(uuidString: values[1]),
                           let percentage = Int(values[2]),
                           let lastModified = dateFormatter.date(from: values[3]) {
                            
                            let allocation = IncomeAllocation(
                                id: id,
                                accountId: accountId,
                                percentage: percentage,
                                lastModified: lastModified
                            )
                            allocations.append(allocation)
                        }
                    }
                default:
                    break
                }
            }
            
            let backupData = BackupData(
                accounts: accounts,
                transactions: transactions,
                categories: categories,
                loans: loans,
                allocations: allocations,
                members: members
            )
            
            return backupData
        } catch {
            print("从CSV导入失败: \(error)")
            return nil
        }
    }
    
    /// 解析CSV行
    /// - Parameter line: CSV行
    /// - Returns: 值数组
    private static func parseCSVLine(_ line: String) -> [String] {
        var values: [String] = []
        var currentValue = ""
        var insideQuotes = false
        
        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                values.append(currentValue)
                currentValue = ""
            } else {
                currentValue.append(char)
            }
        }
        
        values.append(currentValue)
        return values
    }
}