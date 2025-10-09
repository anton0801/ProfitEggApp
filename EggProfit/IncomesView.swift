import SwiftUI

struct IncomesView: View {
    @ObservedObject var dataManager: DataManager
    @State private var newIncome = Income(quantity: 0, pricePerUnit: 0, channel: "market", date: Date())
    @State private var showAdd = false
    @State private var showToast = false
    @State private var toastMessage = "Income Saved!"
    @State private var buyerInput = ""
    @State private var priceInput = "" // String binding для цены
    
    let channels = ["market", "wholesale", "friends/neighbors"]
    let channelIcons = ["building.2.fill", "arrow.down.circle.fill", "person.2.fill"]
    
    var body: some View {
        NavigationView {
            incomesContent
                .navigationTitle("Income")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        FieryButton(title: "Add Income") {
                            showAdd = true
                        }
                    }
                }
                .foregroundStyle(Color.design(.textPrimary))
                .sheet(isPresented: $showAdd) {
                    addIncomeSheet
                }
                .overlay(PremiumToast(message: toastMessage, show: $showToast))
        }
    }
    
    @ViewBuilder
    private var incomesContent: some View {
        ZStack {
            Color.design(.backgroundDark)
                .overlay(Color.fieryGradient.opacity(0.05))
                .ignoresSafeArea()
            
            if dataManager.incomes.isEmpty {
                PremiumEmptyState(message: "No income tracked. Log your sales to calculate profits!", icon: "arrow.up.circle.fill") {
                    showAdd = true
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: DesignSystem.Spacing.m) {
                        PremiumCard(title: "Income Sources", delay: 0.1) {
                            EnhancedBarChart(categories: channels, values: [40.0, 35.0, 25.0])
                        }
                        
                        ForEach(dataManager.incomes) { income in
                            incomeRow(income: income)
                        }
                    }
                    .padding(DesignSystem.Spacing.l)
                }
            }
        }
    }
    
    @ViewBuilder
    private func incomeRow(income: Income) -> some View {
        HStack {
            Image(systemName: channelIcons[channels.firstIndex(of: income.channel) ?? 0])
                .font(.system(size: 24))
                .foregroundColor(.design(.successLime))
                .fieryShadow(.iconSoft)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(income.channel.capitalized)
                    .font(.inter(size: 16, weight: .medium))
                    .foregroundColor(.design(.textPrimary))
                Text("Qty: \(Int(income.quantity)) eggs")
                    .font(.inter(size: 14, weight: .regular))
                    .foregroundColor(.design(.textSecondary))
                Text("Price/Unit: \(income.pricePerUnit, specifier: "%.2f") \(dataManager.settings.currency)")
                    .font(.nunito(size: 16, weight: .bold))
                    .foregroundColor(.design(.successLime))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.design(.textSecondary))
        }
        .padding()
        .background(Color.design(.cardBackground).opacity(0.5))
        .cornerRadius(DesignSystem.Radius.medium)
        .gradientBorder(.cardBorder)
        .padding(.horizontal, DesignSystem.Spacing.s)
    }
    
    @ViewBuilder
    private var addIncomeSheet: some View {
        NavigationView {
            Form {
                Section("Sale Details") {
                    Picker("Channel", selection: $newIncome.channel) {
                        ForEach(channels, id: \.self) { ch in
                            HStack {
                                Image(systemName: channelIcons[channels.firstIndex(of: ch) ?? 0])
                                Text(ch.capitalized)
                            }
                            .tag(ch)
                        }
                    }
                    
                    TextField("Eggs Quantity", value: $newIncome.quantity, format: .number)
                        .keyboardType(.numberPad)
                    
                    TextField("Price per \(dataManager.settings.priceMode) (\(dataManager.settings.currency))", text: $priceInput)
                        .keyboardType(.decimalPad)
                    
                    DatePicker("Date", selection: $newIncome.date, displayedComponents: .date)
                    
                    TextField("Buyer", text: $buyerInput)
                }
            }
            .navigationTitle("New Income")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    FieryButton(title: "Save") {
                        let price = Double(priceInput) ?? newIncome.pricePerUnit
                        newIncome.pricePerUnit = price
                        
                        newIncome.buyer = buyerInput.isEmpty ? nil : buyerInput
                        
                        // Валидация входных данных
                        if newIncome.quantity.isNaN || newIncome.quantity.isInfinite ||
                           newIncome.pricePerUnit.isNaN || newIncome.pricePerUnit.isInfinite {
                            toastMessage = "Invalid input values!"
                            showToast = true
                        } else {
                            if newIncome.quantity == 0 || newIncome.pricePerUnit == 0 {
                                toastMessage = "Warning: Quantity or price is zero."
                            } else {
                                toastMessage = "Income Saved!"
                            }
                            
                            // Сохраняем доход
                            dataManager.incomes.append(newIncome)
                            dataManager.saveData()
                            showAdd = false
                            showToast = true
                            
                            // Сбрасываем поля для следующего ввода
                            newIncome = Income(quantity: 0, pricePerUnit: 0, channel: "market", date: Date())
                            priceInput = ""
                            buyerInput = ""
                        }
                    }
                }
            }
            .tint(.design(.successLime))
        }
    }
}
