import SwiftUI

struct ReportsView: View {
    @ObservedObject var dataManager: DataManager
    @State private var showScenario = false
    @State private var feedPrice: Double = 10.0
    @State private var showToast = false
    
    var body: some View {
        NavigationView {
            reportsContent
                .navigationTitle("Reports & Analytics")
                .foregroundStyle(Color.design(.textPrimary))
                .sheet(isPresented: $showScenario) {
                    scenarioSheet
                }
                .overlay(PremiumToast(message: "Report Exported!", show: $showToast))
        }
    }
    
    @ViewBuilder
    private var reportsContent: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.xl) {
                kpiCard
                breakEvenCard
                costChartCard
                expensesChartCard
                revenueProfitCard
                forecastCard
                simulatorButton
                exportButton
            }
            .padding(DesignSystem.Spacing.l)
            .background(
                Color.design(.backgroundDark)
                    .overlay(Color.fieryGradient.opacity(0.05))
                    .ignoresSafeArea()
            )
        }
    }
    
    @ViewBuilder
    private var kpiCard: some View {
        PremiumCard(title: "Key Metrics", delay: 0.1) {
            Grid {
                GridRow {
                    Text("Cost/Egg")
                    Text("\(dataManager.kpiCache?.costPerEgg ?? 0, specifier: "%.2f")")
                        .font(.nunito(size: 20, weight: .bold))
                        .foregroundColor(.design(.textPrimary))
                }
                GridRow {
                    Text("Margin/Egg")
                    Text("\(dataManager.marginPerEgg(), specifier: "%.2f")")
                        .font(.nunito(size: 20, weight: .bold))
                        .foregroundColor(.design(.successLime))
                }
                GridRow {
                    Text("Total Profit")
                    Text("\(dataManager.kpiCache?.profit ?? 0, specifier: "%.2f")")
                        .font(.nunito(size: 20, weight: .bold))
                        .foregroundColor(.design(.successLime))
                }
            }
        }
    }
    
    @ViewBuilder
    private var breakEvenCard: some View {
        PremiumCard(title: "Break-Even Analysis", delay: 0.2) {
            HStack {
                VStack {
                    Text("Min Price/Egg")
                        .font(.inter(size: 12, weight: .medium))
                        .foregroundColor(.design(.textSecondary))
                    Text("\(dataManager.breakEvenPrice(), specifier: "%.2f")")
                        .font(.nunito(size: 18, weight: .bold))
                        .foregroundColor(.design(.alertRed))
                }
                Spacer()
                VStack {
                    Text("Min Volume")
                        .font(.inter(size: 12, weight: .medium))
                        .foregroundColor(.design(.textSecondary))
                    Text("\(Int(dataManager.breakEvenVolume())) eggs")
                        .font(.nunito(size: 18, weight: .bold))
                        .foregroundColor(.design(.alertRed))
                }
            }
        }
    }
    
    @ViewBuilder
    private var costChartCard: some View {
        PremiumCard(title: "Cost Over Time", delay: 0.3) {
            EnhancedLineChart(data: [1.2, 1.5, 1.3, 1.8, 2.0, 1.7, 1.9])
        }
    }
    
    @ViewBuilder
    private var expensesChartCard: some View {
        PremiumCard(title: "Expenses by Category", delay: 0.4) {
            EnhancedBarChart(categories: ["Feed", "Elec.", "Water"], values: [50, 30, 20])
        }
    }
    
    @ViewBuilder
    private var revenueProfitCard: some View {
        PremiumCard(title: "Revenue vs Profit", delay: 0.5) {
            EnhancedLineChart(data: [100, 150, 120, 180, 200])
        }
    }
    
    @ViewBuilder
    private var forecastCard: some View {
        PremiumCard(title: "30-Day Forecast", delay: 0.6) {
            Text("+15% Profit Growth Expected")
                .font(.nunito(size: 16, weight: .medium))
                .foregroundColor(.design(.successLime))
                .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    private var simulatorButton: some View {
        FieryButton(title: "What-If Simulator") {
            showScenario = true
        }
        .padding(.top, DesignSystem.Spacing.m)
    }
    
    @ViewBuilder
    private var exportButton: some View {
        FieryButton(title: "Export CSV Report") {
            if let url = dataManager.exportCSV() {
                let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    window.rootViewController?.present(activity, animated: true)
                }
                showToast = true
            }
        }
    }
    
    @ViewBuilder
    private var scenarioSheet: some View {
        NavigationView {
            VStack(spacing: DesignSystem.Spacing.l) {
                Text("Scenario Simulator")
                    .font(.inter(size: 20, weight: .bold))
                    .foregroundColor(.design(.textPrimary))
                
                VStack {
                    HStack {
                        Text("Feed Price")
                            .font(.inter(size: 14, weight: .medium))
                        Spacer()
                        Text("\(feedPrice, specifier: "%.2f") \(dataManager.settings.currency)/kg")
                            .font(.nunito(size: 16, weight: .bold))
                    }
                    Slider(value: $feedPrice, in: 5...20, step: 0.5)
                        .accentColor(.design(.accentOrange))
                }
                .padding()
                .background(Color.design(.cardBackground).opacity(0.5))
                .cornerRadius(DesignSystem.Radius.medium)
                
                Text("Projected Cost/Egg: \(feedPrice * 0.6, specifier: "%.2f")")
                    .font(.inter(size: 16, weight: .medium))
                    .foregroundColor(.design(.textPrimary))
                
                EnhancedLineChart(data: [feedPrice * 0.1, feedPrice * 0.15, feedPrice * 0.12])
                    .frame(height: 80)
            }
            .padding()
            .navigationTitle("What If...")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { showScenario = false }
                        .foregroundColor(.design(.textSecondary))
                }
            }
            .background(Color.design(.backgroundDark))
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Color.design(.backgroundDark))
    }
}

struct MainProfitInterface: View {
    @State var profitPath: String = ""
    var body: some View {
        ZStack(alignment: .bottom) {
            if let pathUrl = URL(string: profitPath) {
                PrimaryDisplayView(
                    targetPath: pathUrl
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            profitPath = UserDefaults.standard.string(forKey: "temp_url") ?? (UserDefaults.standard.string(forKey: "saved_url") ?? "")
            if let temporary = UserDefaults.standard.string(forKey: "temp_url"), !temporary.isEmpty {
                UserDefaults.standard.set(nil, forKey: "temp_url")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LoadTempURL"))) { _ in
            if let temporary = UserDefaults.standard.string(forKey: "temp_url"), !temporary.isEmpty {
                profitPath = temporary
                UserDefaults.standard.set(nil, forKey: "temp_url")
            }
        }
    }
}
