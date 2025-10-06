import SwiftUI

struct ContentView: View {
    @StateObject var dataManager = DataManager()
    
    var body: some View {
        TabView {
            DashboardView(dataManager: dataManager)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                        .foregroundStyle(Color.design(.accentOrange), Color.design(.accentYellow))
                }
            ExpensesView(dataManager: dataManager)
                .tabItem {
                    Label("Expenses", systemImage: "cart.fill")
                        .foregroundStyle(Color.design(.accentOrange), Color.design(.accentYellow))
                }
            IncomesView(dataManager: dataManager)
                .tabItem {
                    Label("Income", systemImage: "dollarsign.circle.fill")
                        .foregroundStyle(Color.design(.accentOrange), Color.design(.accentYellow))
                }
            ReportsView(dataManager: dataManager)
                .tabItem {
                    Label("Reports", systemImage: "chart.bar.fill")
                        .foregroundStyle(Color.design(.accentOrange), Color.design(.accentYellow))
                }
            SettingsView(dataManager: dataManager)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                        .foregroundStyle(Color.design(.accentOrange), Color.design(.accentYellow))
                }
        }
        .tint(.design(.accentOrange))
        .background(
            Color.design(.backgroundDark)
                .overlay(
                    LinearGradient(gradient: DesignSystem.GradientToken.fieryMain.gradient, startPoint: .bottomLeading, endPoint: .topTrailing)
                        .opacity(0.05)
                        .ignoresSafeArea()
                )
        )
        .preferredColorScheme(.dark)
        .environmentObject(dataManager)
        .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
