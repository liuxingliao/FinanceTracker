import SwiftUI

struct StatisticsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("统计功能正在开发中...")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                // 这里将在后续添加图表和统计数据展示
                // 可以显示月度收支对比、分类支出占比等
                
                Spacer()
            }
            .navigationTitle("统计分析")
        }
    }
}

struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsView()
    }
}