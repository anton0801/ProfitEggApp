import SwiftUI

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
                
                Button("Import from CSV") {
                    // File picker logic
                }
                .foregroundColor(.design(.textSecondary))
            }
            .listRowBackground(Color.design(.cardBackground).opacity(0.3))
            
            Section("Notifications") {
                Toggle("Low Margin Alerts", isOn: .constant(true))
                Toggle("Expense Spike Warnings", isOn: .constant(true))
                    .tint(.design(.accentOrange))
            }
            .listRowBackground(Color.design(.cardBackground).opacity(0.3))
        }
        .scrollContentBackground(.hidden)
        .background(Color.design(.backgroundDark))
    }
}
