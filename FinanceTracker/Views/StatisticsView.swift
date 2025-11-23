import SwiftUI

struct StatisticsView: View {
    @StateObject private var viewModel = TransactionViewModel()
    @State private var selectedPeriod: Period = .month
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    
    enum Period: String, CaseIterable {
        case day = "天"
        case week = "周"
        case month = "月"
        case year = "年"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 时间选择器
                    timeSelector
                    
                    // 图表展示
                    if !viewModel.isLoading {
                        // 趋势图表
                        trendChartView
                        
                        // 统计摘要
                        statisticsSummaryView
                        
                        // 收入支出排行榜
                        rankingsView
                        
                        // 借贷统计
                        loanStatisticsView
                    } else {
                        ProgressView("加载中...")
                    }
                }
                .padding()
            }
            .navigationTitle("统计分析")
        }
        .onAppear {
            viewModel.loadData()
        }
    }
    
    private var timeSelector: some View {
        VStack(spacing: 10) {
            Picker("周期", selection: $selectedPeriod) {
                ForEach(Period.allCases, id: \.self) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            HStack {
                Picker("年份", selection: $selectedYear) {
                    ForEach(2020...Calendar.current.component(.year, from: Date()), id: \.self) { year in
                        Text("\(year)年").tag(year)
                    }
                }
                
                if selectedPeriod != .year {
                    Picker("月份", selection: $selectedMonth) {
                        ForEach(1...12, id: \.self) { month in
                            Text("\(month)月").tag(month)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var trendChartView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("资金趋势")
                .font(.title2)
                .fontWeight(.bold)
            
            // 曲线图表
            let trendData = getTrendData()
            if !trendData.isEmpty {
                CurveChartView(data: trendData)
                    .frame(height: 200)
            } else {
                Text("暂无数据")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
    
    private var statisticsSummaryView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("统计摘要")
                .font(.title2)
                .fontWeight(.bold)
            
            let summary = calculateSummary()
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                SummaryCard(title: "总收入", value: formatCurrency(summary.totalIncome), color: .green)
                SummaryCard(title: "总支出", value: formatCurrency(summary.totalExpense), color: .red)
                SummaryCard(title: "净收入", value: formatCurrency(summary.netIncome), color: summary.netIncome >= 0 ? .green : .red)
                SummaryCard(title: "借入", value: formatCurrency(summary.totalBorrowIn), color: .red)
                SummaryCard(title: "借出", value: formatCurrency(summary.totalBorrowOut), color: .green)
                SummaryCard(title: "净存款", value: formatCurrency(summary.netSavings), color: summary.netSavings >= 0 ? .green : .red)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
    
    private var rankingsView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("收支排行榜")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack {
                VStack(alignment: .leading, spacing: 10) {
                    Text("收入排行")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    let incomeRankings = getIncomeRankings()
                    ForEach(incomeRankings.indices, id: \.self) { index in
                        RankingItem(rank: index + 1, item: incomeRankings[index].category, amount: incomeRankings[index].amount, color: .green)
                    }
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("支出排行")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    let expenseRankings = getExpenseRankings()
                    ForEach(expenseRankings.indices, id: \.self) { index in
                        RankingItem(rank: index + 1, item: expenseRankings[index].category, amount: expenseRankings[index].amount, color: .red)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
    
    private var loanStatisticsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("借贷统计")
                .font(.title2)
                .fontWeight(.bold)
            
            let loanStats = calculateLoanStatistics()
            HStack {
                VStack {
                    Text("借入总额")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(loanStats.totalBorrowIn))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                
                VStack {
                    Text("借出总额")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(loanStats.totalBorrowOut))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                VStack {
                    Text("净借贷")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(loanStats.netLoans))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(loanStats.netLoans >= 0 ? .green : .red)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
    
    // 辅助视图和计算方法
    struct SummaryCard: View {
        let title: String
        let value: String
        let color: Color
        
        var body: some View {
            VStack(spacing: 5) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    struct RankingItem: View {
        let rank: Int
        let item: String
        let amount: Decimal
        let color: Color
        
        var body: some View {
            HStack {
                Text("\(rank)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                Text(item)
                    .font(.caption)
                    .lineLimit(1)
                
                Spacer()
                
                Text(Self.formatCurrency(amount))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
        }
        
        static func formatCurrency(_ amount: Decimal) -> String {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = Locale.current
            return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "\(amount)"
        }
    }
    
    struct TrendDataPoint {
        let label: String
        let income: Decimal
        let expense: Decimal
        let maxValue: Decimal
        
        // 添加辅助方法将Decimal转换为CGFloat
        func incomeCGFloat() -> CGFloat {
            return CGFloat(NSDecimalNumber(decimal: income).doubleValue)
        }
        
        func expenseCGFloat() -> CGFloat {
            return CGFloat(NSDecimalNumber(decimal: expense).doubleValue)
        }
        
        func maxValueCGFloat() -> CGFloat {
            return CGFloat(NSDecimalNumber(decimal: maxValue).doubleValue)
        }
    }
    
    // 获取趋势数据
    private func getTrendData() -> [TrendDataPoint] {
        var data: [TrendDataPoint] = []
        let records = filterRecordsByPeriod()
        
        switch selectedPeriod {
        case .day:
            // 按小时分组
            let grouped = Dictionary(grouping: records) { record -> Int in
                if let transaction = record as? Transaction {
                    return Calendar.current.component(.hour, from: transaction.date)
                } else if let loan = record as? Loan {
                    return Calendar.current.component(.hour, from: loan.date)
                }
                return 0
            }
            
            var maxValue: Decimal = 0
            for hour in 0..<24 {
                let hourRecords = grouped[hour] ?? []
                let stats = calculateStatistics(for: hourRecords)
                maxValue = max(maxValue, stats.totalIncome, stats.totalExpense)
            }
            
            for hour in 0..<24 {
                let hourRecords = grouped[hour] ?? []
                let stats = calculateStatistics(for: hourRecords)
                data.append(TrendDataPoint(
                    label: "\(hour)时",
                    income: stats.totalIncome,
                    expense: stats.totalExpense,
                    maxValue: maxValue
                ))
            }
            
        case .week:
            // 按星期几分组
            let grouped = Dictionary(grouping: records) { record -> Int in
                if let transaction = record as? Transaction {
                    return Calendar.current.component(.weekday, from: transaction.date)
                } else if let loan = record as? Loan {
                    return Calendar.current.component(.weekday, from: loan.date)
                }
                return 0
            }
            
            let weekdays = ["日", "一", "二", "三", "四", "五", "六"]
            var maxValue: Decimal = 0
            for day in 1...7 {
                let dayRecords = grouped[day] ?? []
                let stats = calculateStatistics(for: dayRecords)
                maxValue = max(maxValue, stats.totalIncome, stats.totalExpense)
            }
            
            for day in 1...7 {
                let dayRecords = grouped[day] ?? []
                let stats = calculateStatistics(for: dayRecords)
                data.append(TrendDataPoint(
                    label: "星期\(weekdays[day-1])",
                    income: stats.totalIncome,
                    expense: stats.totalExpense,
                    maxValue: maxValue
                ))
            }
            
        case .month:
            // 按日期分组
            let grouped = Dictionary(grouping: records) { record -> Int in
                if let transaction = record as? Transaction {
                    return Calendar.current.component(.day, from: transaction.date)
                } else if let loan = record as? Loan {
                    return Calendar.current.component(.day, from: loan.date)
                }
                return 0
            }
            
            let daysInMonth = Calendar.current.range(of: .day, in: .month, for: getDateFromSelection())?.count ?? 30
            var maxValue: Decimal = 0
            for day in 1...daysInMonth {
                let dayRecords = grouped[day] ?? []
                let stats = calculateStatistics(for: dayRecords)
                maxValue = max(maxValue, stats.totalIncome, stats.totalExpense)
            }
            
            for day in 1...daysInMonth {
                let dayRecords = grouped[day] ?? []
                let stats = calculateStatistics(for: dayRecords)
                data.append(TrendDataPoint(
                    label: "\(day)日",
                    income: stats.totalIncome,
                    expense: stats.totalExpense,
                    maxValue: maxValue
                ))
            }
            
        case .year:
            // 按月份分组
            let grouped = Dictionary(grouping: records) { record -> Int in
                if let transaction = record as? Transaction {
                    return Calendar.current.component(.month, from: transaction.date)
                } else if let loan = record as? Loan {
                    return Calendar.current.component(.month, from: loan.date)
                }
                return 0
            }
            
            var maxValue: Decimal = 0
            for month in 1...12 {
                let monthRecords = grouped[month] ?? []
                let stats = calculateStatistics(for: monthRecords)
                maxValue = max(maxValue, stats.totalIncome, stats.totalExpense)
            }
            
            for month in 1...12 {
                let monthRecords = grouped[month] ?? []
                let stats = calculateStatistics(for: monthRecords)
                data.append(TrendDataPoint(
                    label: "\(month)月",
                    income: stats.totalIncome,
                    expense: stats.totalExpense,
                    maxValue: maxValue
                ))
            }
        }
        
        return data
    }
    
    // 计算统计摘要
    private func calculateSummary() -> (totalIncome: Decimal, totalExpense: Decimal, netIncome: Decimal, totalBorrowIn: Decimal, totalBorrowOut: Decimal, netSavings: Decimal) {
        let records = filterRecordsByPeriod()
        let stats = calculateStatistics(for: records)
        
        // 计算净存款 = 总收入 - 总支出 + 借入 - 借出
        let netSavings = stats.totalIncome - stats.totalExpense + stats.totalBorrowIn - stats.totalBorrowOut
        
        return (
            totalIncome: stats.totalIncome,
            totalExpense: stats.totalExpense,
            netIncome: stats.netIncome,
            totalBorrowIn: stats.totalBorrowIn,
            totalBorrowOut: stats.totalBorrowOut,
            netSavings: netSavings
        )
    }
    
    // 获取收入排行
    private func getIncomeRankings() -> [(category: String, amount: Decimal)] {
        let records = filterRecordsByPeriod()
        var incomeByCategory: [String: Decimal] = [:]
        
        for record in records {
            if let transaction = record as? Transaction, transaction.type == .income {
                let categoryName = viewModel.getCategoryName(withId: transaction.categoryId) ?? "未知分类"
                incomeByCategory[categoryName, default: 0] += transaction.amount
            } else if let loan = record as? Loan, loan.type == .borrowIn {
                incomeByCategory["借入", default: 0] += loan.amount
            }
        }
        
        return incomeByCategory.map { (category: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
            .prefix(10)
            .map { $0 }
    }
    
    // 获取支出排行
    private func getExpenseRankings() -> [(category: String, amount: Decimal)] {
        let records = filterRecordsByPeriod()
        var expenseByCategory: [String: Decimal] = [:]
        
        for record in records {
            if let transaction = record as? Transaction, transaction.type == .expense {
                let categoryName = viewModel.getCategoryName(withId: transaction.categoryId) ?? "未知分类"
                expenseByCategory[categoryName, default: 0] += transaction.amount
            } else if let loan = record as? Loan, loan.type == .borrowOut {
                expenseByCategory["借出", default: 0] += loan.amount
            }
        }
        
        return expenseByCategory.map { (category: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
            .prefix(10)
            .map { $0 }
    }
    
    // 计算借贷统计
    private func calculateLoanStatistics() -> (totalBorrowIn: Decimal, totalBorrowOut: Decimal, netLoans: Decimal) {
        let records = filterRecordsByPeriod()
        var totalBorrowIn: Decimal = 0
        var totalBorrowOut: Decimal = 0
        
        for record in records {
            if let loan = record as? Loan {
                switch loan.type {
                case .borrowIn:
                    totalBorrowIn += loan.amount
                case .borrowOut:
                    totalBorrowOut += loan.amount
                }
            }
        }
        
        let netLoans = totalBorrowIn - totalBorrowOut
        return (totalBorrowIn, totalBorrowOut, netLoans)
    }
    
    // 根据选定的时间段过滤记录
    private func filterRecordsByPeriod() -> [Any] {
        let targetDate = getDateFromSelection()
        var filteredRecords: [Any] = []
        
        // 添加交易记录
        for transaction in viewModel.transactions {
            if isDate(transaction.date, inPeriodOf: targetDate) {
                filteredRecords.append(transaction)
            }
        }
        
        // 添加贷款记录
        for loan in viewModel.loans {
            if isDate(loan.date, inPeriodOf: targetDate) {
                filteredRecords.append(loan)
            }
        }
        
        return filteredRecords
    }
    
    // 获取选定的时间
    private func getDateFromSelection() -> Date {
        var components = DateComponents()
        components.year = selectedYear
        components.month = selectedMonth
        
        return Calendar.current.date(from: components) ?? Date()
    }
    
    // 检查日期是否在选定的时间段内
    private func isDate(_ date: Date, inPeriodOf targetDate: Date) -> Bool {
        let calendar = Calendar.current
        
        switch selectedPeriod {
        case .day:
            return calendar.isDate(date, equalTo: targetDate, toGranularity: .day)
        case .week:
            return calendar.isDate(date, equalTo: targetDate, toGranularity: .weekOfYear)
        case .month:
            return calendar.isDate(date, equalTo: targetDate, toGranularity: .month) &&
                   calendar.component(.year, from: date) == calendar.component(.year, from: targetDate)
        case .year:
            return calendar.component(.year, from: date) == selectedYear
        }
    }
    
    // 计算记录统计数据
    private func calculateStatistics(for records: [Any]) -> (totalIncome: Decimal, totalExpense: Decimal, netIncome: Decimal, totalBorrowIn: Decimal, totalBorrowOut: Decimal) {
        var totalIncome: Decimal = 0
        var totalExpense: Decimal = 0
        var totalBorrowIn: Decimal = 0
        var totalBorrowOut: Decimal = 0
        
        for record in records {
            if let transaction = record as? Transaction {
                switch transaction.type {
                case .income:
                    totalIncome += transaction.amount
                case .expense:
                    totalExpense += transaction.amount
                }
            } else if let loan = record as? Loan {
                switch loan.type {
                case .borrowIn:
                    totalBorrowIn += loan.amount
                case .borrowOut:
                    totalBorrowOut += loan.amount
                }
            }
        }
        
        let netIncome = totalIncome - totalExpense
        return (totalIncome, totalExpense, netIncome, totalBorrowIn, totalBorrowOut)
    }
    
    // 格式化货币
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "\(amount)"
    }
}

struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsView()
    }
}

// 曲线图表视图
struct CurveChartView: View {
    let data: [StatisticsView.TrendDataPoint]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 网格线
                GridLines(size: geometry.size)
                
                // 收入曲线
                if data.contains(where: { $0.income > 0 }) {
                    CurveLine(
                        data: data.map { point in
                            return PointInfo(
                                x: CGFloat(data.firstIndex(where: { $0.label == point.label }) ?? 0) / CGFloat(data.count - 1),
                                y: point.incomeCGFloat() / getMaxValue().cgFloat()
                            )
                        },
                        color: .green,
                        size: geometry.size
                    )
                }
                
                // 支出曲线
                if data.contains(where: { $0.expense > 0 }) {
                    CurveLine(
                        data: data.map { point in
                            return PointInfo(
                                x: CGFloat(data.firstIndex(where: { $0.label == point.label }) ?? 0) / CGFloat(data.count - 1),
                                y: point.expenseCGFloat() / getMaxValue().cgFloat()
                            )
                        },
                        color: .red,
                        size: geometry.size
                    )
                }
                
                // 图例
                HStack {
                    LegendItem(color: .green, text: "收入")
                    LegendItem(color: .red, text: "支出")
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
        }
    }
    
    // 获取最大值用于归一化
    private func getMaxValue() -> Decimal {
        var maxValue: Decimal = 0
        for point in data {
            maxValue = max(maxValue, point.income, point.expense)
        }
        return maxValue > 0 ? maxValue : 1
    }
}

// 网格线
struct GridLines: View {
    let size: CGSize
    
    var body: some View {
        ZStack {
            // 水平线
            ForEach(0..<5) { index in
                Path { path in
                    let y = CGFloat(index) * (size.height - 40) / 4
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }
                .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
            }
            
            // 垂直线
            ForEach(0..<5) { index in
                Path { path in
                    let x = CGFloat(index) * size.width / 4
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height - 40))
                }
                .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
            }
        }
    }
}

// 点信息
struct PointInfo {
    let x: CGFloat  // 0.0 - 1.0
    let y: CGFloat  // 0.0 - 1.0 (已归一化)
}

// 曲线线条
struct CurveLine: View {
    let data: [PointInfo]
    let color: Color
    let size: CGSize
    
    var body: some View {
        Path { path in
            if !data.isEmpty {
                let startY = size.height - 40 - (data[0].y * (size.height - 40))
                path.move(to: CGPoint(x: 0, y: startY))
                
                for i in 1..<data.count {
                    let x = CGFloat(i) / CGFloat(data.count - 1) * size.width
                    let y = size.height - 40 - (data[i].y * (size.height - 40))
                    
                    // 使用二次贝塞尔曲线创建平滑曲线
                    let prevX = CGFloat(i - 1) / CGFloat(data.count - 1) * size.width
                    let prevY = size.height - 40 - (data[i - 1].y * (size.height - 40))
                    
                    let controlX = (prevX + x) / 2
                    let controlY = (prevY + y) / 2
                    
                    path.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: controlX, y: controlY))
                }
            }
        }
        .stroke(color, lineWidth: 2)
        
        // 绘制数据点
        ForEach(data.indices, id: \.self) { index in
            let point = data[index]
            let x = CGFloat(index) / CGFloat(data.count - 1) * size.width
            let y = size.height - 40 - (point.y * (size.height - 40))
            
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .position(x: x, y: y)
        }
    }
}

// 图例项
struct LegendItem: View {
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// 扩展Decimal以支持CGFloat转换
extension Decimal {
    func cgFloat() -> CGFloat {
        return CGFloat(NSDecimalNumber(decimal: self).doubleValue)
    }
}
