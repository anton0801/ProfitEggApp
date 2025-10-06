import SwiftUI

struct DashboardView: View {
    @ObservedObject var dataManager: DataManager
    @State private var period = "month"
    @State private var showToast = false
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        NavigationView {
            dashboardContent
                .navigationTitle("EggProfit Dashboard")
                .navigationBarTitleDisplayMode(.large)
                .toolbarBackground(Color.fieryGradient.opacity(0.2), for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .foregroundStyle(Color.design(.textPrimary))
                .overlay(PremiumToast(message: "Data Updated", show: $showToast))
        }
    }
    
    @ViewBuilder
    private var dashboardContent: some View {
        ZStack {
            Color.design(.backgroundDark)
                .overlay(Color.fieryGradient.opacity(0.05))
                .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: DesignSystem.Spacing.xl) {
                    kpiCard
                    periodCard
                    herdCard
                    dynamicsCard
                    profitEatersCard
                }
                .padding(DesignSystem.Spacing.l)
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .preference(key: ScrollOffsetKey.self, value: geo.frame(in: .global).minY)
                    }
                )
            }
            .onPreferenceChange(ScrollOffsetKey.self) { offset in
                scrollOffset = offset
            }
        }
    }
    
    @ViewBuilder
    private var kpiCard: some View {
        PremiumCard(title: "Cost per Egg", delay: 0.1) {
            HStack {
                VStack(alignment: .leading) {
                    Text("\(dataManager.kpiCache?.costPerEgg ?? 0, specifier: "%.2f") \(dataManager.settings.currency)")
                        .font(.nunito(size: 28, weight: .bold))
                        .foregroundColor(.design(.textPrimary))
                    if (dataManager.kpiCache?.costPerEgg ?? 0) > 5 {
                        Text("🔥 Rising")
                            .font(.inter(size: 12, weight: .medium))
                            .foregroundColor(.design(.alertRed))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.design(.alertRed).opacity(0.2))
                            .cornerRadius(DesignSystem.Radius.small)
                    }
                }
                Spacer()
                Image(systemName: "flame.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.design(.accentOrange))
                    .fieryShadow(.iconSoft)
            }
        }
    }
    
    @ViewBuilder
    private var periodCard: some View {
        PremiumCard(title: "Revenue & Profit", delay: 0.2) {
            Picker("Period", selection: $period) {
                Text("Week").tag("week")
                Text("Month").tag("month")
            }
            .pickerStyle(.segmented)
            .tint(.design(.accentOrange))
            .padding(DesignSystem.Spacing.s)
            
            HStack {
                VStack {
                    Text("Revenue")
                        .font(.inter(size: 12, weight: .medium))
                        .foregroundColor(.design(.textSecondary))
                    Text("\(dataManager.kpiCache?.revenue ?? 0, specifier: "%.2f")")
                        .font(.nunito(size: 20, weight: .bold))
                        .foregroundColor(.design(.successLime))
                }
                Spacer()
                VStack {
                    Text("Profit")
                        .font(.inter(size: 12, weight: .medium))
                        .foregroundColor(.design(.textSecondary))
                    Text("\(dataManager.kpiCache?.profit ?? 0, specifier: "%.2f")")
                        .font(.nunito(size: 20, weight: .bold))
                        .foregroundColor(.design(.successLime))
                }
            }
        }
    }
    
    @ViewBuilder
    private var herdCard: some View {
        PremiumCard(title: "Herd Overview", delay: 0.3) {
            HStack {
                Image(systemName: "figure.walk")
                    .font(.system(size: 30))
                    .foregroundColor(.design(.accentYellow))
                    .fieryShadow(.iconSoft)
                VStack(alignment: .leading) {
                    Text("Hens: \(dataManager.settings.hensCount)")
                        .font(.nunito(size: 16, weight: .medium))
                    Text("Eggs/Day: \(Int(dataManager.settings.avgLaidPerDay * Double(dataManager.settings.hensCount)))")
                        .font(.inter(size: 14, weight: .regular))
                        .foregroundColor(.design(.textSecondary))
                }
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private var dynamicsCard: some View {
        PremiumCard(title: "Cost Dynamics (7 Days)", delay: 0.4) {
            EnhancedLineChart(data: [1.2, 1.5, 1.3, 1.8, 2.0, 1.7, 1.9])
                .padding(DesignSystem.Spacing.s)
        }
    }
    
    @ViewBuilder
    private var profitEatersCard: some View {
        PremiumCard(title: "Profit Killers (Top 3)", delay: 0.5) {
            VStack(spacing: DesignSystem.Spacing.m) {
                ForEach(["Feed: 50%", "Electricity: 30%", "Water: 20%"], id: \.self) { item in
                    HStack {
                        Circle()
                            .fill(Color.design(.accentOrange))
                            .frame(width: 12, height: 12)
                        Text(item)
                            .font(.inter(size: 14, weight: .medium))
                            .foregroundColor(.design(.textPrimary))
                        Spacer()
                        Image(systemName: "arrow.right")
                            .foregroundColor(.design(.textSecondary))
                    }
                }
            }
        }
    }
}

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
