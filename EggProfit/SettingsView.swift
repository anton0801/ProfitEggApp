import SwiftUI
import WebKit


struct PrimaryDisplayView: UIViewRepresentable {
    let targetPath: URL
    @StateObject private var manager = ProfitManager()
    func makeUIView(context: Context) -> WKWebView {
        manager.setupPrimaryDisplay()
        manager.primaryDisplay.uiDelegate = context.coordinator
        manager.primaryDisplay.navigationDelegate = context.coordinator
        manager.loadStoredSessionInfo()
        manager.primaryDisplay.load(URLRequest(url: targetPath))
        return manager.primaryDisplay
    }
    func updateUIView(_ display: WKWebView, context: Context) {
        // Placeholder or refresh if required
    }
    func makeCoordinator() -> EggDisplayManager {
        EggDisplayManager(manager: manager)
    }
}

struct SettingsView: View {
    @ObservedObject var dataManager: DataManager
    @State private var showToast = false
    @State private var showBackupAlert = false
    
    var body: some View {
        NavigationView {
            settingsContent
                .navigationTitle("Settings")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        FieryButton(title: "Apply Changes") {
                            dataManager.saveData()
                            showToast = true
                        }
                    }
                }
                .foregroundStyle(Color.design(.textPrimary))
                .tint(.design(.accentOrange))
                .overlay(PremiumToast(message: "Settings Saved!", show: $showToast))
        }
    }
    
    @ViewBuilder
    private var settingsContent: some View {
        Form {
            Section("General Settings") {
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(.design(.successLime))
                    TextField("Currency", text: $dataManager.settings.currency)
                        .font(.inter(size: 16))
                }
                
                Picker("Price Mode", selection: $dataManager.settings.priceMode) {
                    Text("Per Unit").tag("unit")
                    Text("Per Dozen").tag("dozen")
                }
                .pickerStyle(.menu)
                
                Stepper("Hens: \(dataManager.settings.hensCount)", value: $dataManager.settings.hensCount, in: 1...5000)
                    .font(.inter(size: 16))
                
                HStack {
                    Text("Avg Eggs/Day/Hen")
                    Spacer()
                    TextField("", value: $dataManager.settings.avgLaidPerDay, format: .number.precision(.fractionLength(2)))
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                }
                
                Picker("Default Period", selection: $dataManager.settings.defaultPeriod) {
                    Text("Week").tag("week")
                    Text("Month").tag("month")
                    Text("Quarter").tag("quarter")
                }
                .pickerStyle(.segmented)
                .tint(.design(.accentOrange))
            }
            .listRowBackground(Color.design(.cardBackground).opacity(0.3))
            
            Section("Automation & Calc") {
                Button("Recalculate Base Costs") {
                    dataManager.calculateKPI()
                    showToast = true
                }
                .foregroundColor(.design(.accentOrange))
            }
            .listRowBackground(Color.design(.cardBackground).opacity(0.3))
            
            Section("Backup & Sync") {
                Button("Backup to iCloud") {
                    dataManager.backupToiCloud()
                    showToast = true
                }
                .foregroundColor(.design(.successLime))

            }
            .listRowBackground(Color.design(.cardBackground).opacity(0.3))
            
            Section("Notifications") {
                Toggle("Low Margin Alerts", isOn: .constant(true))
                Toggle("Expense Spike Warnings", isOn: .constant(true))
                    .tint(.design(.accentOrange))
            }
            .listRowBackground(Color.design(.cardBackground).opacity(0.3))
            
            Section("Privacy & Support") {
                Button {
                    UIApplication.shared.open(URL(string: "https://eggprofit.com/privacy-policy.html")!)
                } label: {
                    HStack {
                        Text("Privacy Policy")
                    }
                }
                Button {
                    UIApplication.shared.open(URL(string: "https://eggprofit.com/support.html")!)
                } label: {
                    HStack {
                        Text("Support Form")
                    }
                }
            }
            .listRowBackground(Color.design(.cardBackground).opacity(0.3))
        }
        .scrollContentBackground(.hidden)
        .background(Color.design(.backgroundDark))
    }
}


extension EggDisplayManager {
    @objc func handleEdgeSwipe(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        if recognizer.state == .ended {
            guard let currentView = recognizer.view as? WKWebView else { return }
            if currentView.canGoBack {
                currentView.goBack()
            } else if let lastAdditional = profitManager.additionalDisplays.last, currentView == lastAdditional {
                profitManager.removeAdditionalDisplays(currentPath: nil)
            }
        }
    }
}

#Preview {
    SettingsView(dataManager: DataManager())
}
