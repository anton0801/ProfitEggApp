import SwiftUI

struct ExpensesView: View {
    @ObservedObject var dataManager: DataManager
    @State private var newExpense = Expense(category: "feed", amount: 0, date: Date())
    @State private var showAdd = false
    @State private var showToast = false
    @State private var noteInput = ""
    
    let categories = ["feed", "electricity/heating", "bedding", "water", "veterinary/vaccines", "depreciation", "other"]
    let categoryIcons = ["leaf.fill", "bolt.fill", "leaf.fill", "drop.fill", "cross.fill", "wrench.fill", "ellipsis"]
    
    var body: some View {
        NavigationView {
            expensesContent
                .navigationTitle("Expenses")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        FieryButton(title: "Add Expense") {
                            showAdd = true
                        }
                    }
                }
                .foregroundStyle(Color.design(.textPrimary))
                .sheet(isPresented: $showAdd) {
                    addExpenseSheet
                }
                .overlay(PremiumToast(message: "Expense Saved!", show: $showToast))
        }
    }
    
    @ViewBuilder
    private var expensesContent: some View {
        ZStack {
            Color.design(.backgroundDark)
                .overlay(Color.fieryGradient.opacity(0.05))
                .ignoresSafeArea()
            
            if dataManager.expenses.isEmpty {
                PremiumEmptyState(message: "No expenses yet. Track your costs to see insights!", icon: "tray.and.arrow.down.fill") {
                    showAdd = true
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: DesignSystem.Spacing.m) {
                        PremiumCard(title: "Expenses Breakdown", delay: 0.1) {
                            EnhancedBarChart(categories: categories, values: [50.0, 30.0, 20.0, 10.0, 5.0, 5.0, 5.0])
                        }
                        
                        ForEach(dataManager.expenses) { expense in
                            expenseRow(expense: expense)
                        }
                    }
                    .padding(DesignSystem.Spacing.l)
                }
            }
        }
    }
    
    @ViewBuilder
    private func expenseRow(expense: Expense) -> some View {
        HStack {
            Image(systemName: categoryIcons[categories.firstIndex(of: expense.category) ?? 0])
                .font(.system(size: 24))
                .foregroundColor(.design(.accentOrange))
                .fieryShadow(.iconSoft)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(expense.category.capitalized)
                    .font(.inter(size: 16, weight: .medium))
                    .foregroundColor(.design(.textPrimary))
                Text("\(expense.amount, specifier: "%.2f") \(dataManager.settings.currency)")
                    .font(.nunito(size: 18, weight: .bold))
                    .foregroundColor(.design(.successLime))
                Text(expense.date, style: .date)
                    .font(.inter(size: 12, weight: .regular))
                    .foregroundColor(.design(.textSecondary))
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
    private var addExpenseSheet: some View {
        NavigationView {
            Form {
                Section("Details") {
                    Picker("Category", selection: $newExpense.category) {
                        ForEach(categories, id: \.self) { cat in
                            HStack {
                                Image(systemName: categoryIcons[categories.firstIndex(of: cat) ?? 0])
                                Text(cat.capitalized)
                            }
                            .tag(cat)
                        }
                    }
                    .pickerStyle(.wheel)
                    
                    TextField("Amount", value: $newExpense.amount, format: .currency(code: dataManager.settings.currency))
                        .keyboardType(.decimalPad)
                    
                    DatePicker("Date", selection: $newExpense.date, displayedComponents: .date)
                    
                    TextField("Note", text: $noteInput)
                    
                    HStack {
                        TextField("Quantity", value: $newExpense.quantity, format: .number)
                            .keyboardType(.decimalPad)
                        TextField("Unit Cost", value: $newExpense.unitCost, format: .currency(code: dataManager.settings.currency))
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .navigationTitle("New Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    FieryButton(title: "Save") {
                        newExpense.note = noteInput.isEmpty ? nil : noteInput
                        if newExpense.amount > 0 {
                            dataManager.expenses.append(newExpense)
                            dataManager.saveData()
                            showAdd = false
                            showToast = true
                        }
                    }
                }
            }
            .tint(.design(.accentOrange))
        }
    }
}
