import Foundation
import UserNotifications

class DataManager: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var incomes: [Income] = []
    @Published var settings: AppSettings = AppSettings()
    @Published var kpiCache: KPI?
    
    private let expensesKey = "expenses"
    private let incomesKey = "incomes"
    private let settingsKey = "settings"
    private let kpiKey = "kpi"
    private let serialQueue = DispatchQueue(label: "com.eggprofit.datamanager.serial")
    
    init() {
        loadData()
        scheduleNotifications()
    }
    
    func saveData() {
        serialQueue.async {
            do {
                let encodedExpenses = try JSONEncoder().encode(self.expenses)
                UserDefaults.standard.set(encodedExpenses, forKey: self.expensesKey)
                print("Expenses saved successfully: \(self.expenses.count) items")
            } catch {
                print("Failed to encode expenses: \(error)")
                DispatchQueue.main.async {
                    self.expenses = self.expenses.filter { expense in
                        guard !expense.amount.isNaN, !expense.amount.isInfinite else { return false }
                        if let unitCost = expense.unitCost, unitCost.isNaN || unitCost.isInfinite { return false }
                        if let quantity = expense.quantity, quantity.isNaN || quantity.isInfinite { return false }
                        return true
                    }
                }
            }
            
            do {
                let encodedIncomes = try JSONEncoder().encode(self.incomes)
                UserDefaults.standard.set(encodedIncomes, forKey: self.incomesKey)
                print("Incomes saved successfully: \(self.incomes.count) items")
            } catch {
                print("Failed to encode incomes: \(error)")
                DispatchQueue.main.async {
                    self.incomes = self.incomes.filter { income in
                        guard !income.quantity.isNaN, !income.quantity.isInfinite,
                              !income.pricePerUnit.isNaN, !income.pricePerUnit.isInfinite else { return false }
                        return true
                    }
                }
            }
            
            do {
                let encodedSettings = try JSONEncoder().encode(self.settings)
                UserDefaults.standard.set(encodedSettings, forKey: self.settingsKey)
                print("Settings saved successfully")
            } catch {
                print("Failed to encode settings: \(error)")
            }
            
            do {
                let encodedKPI = try JSONEncoder().encode(self.kpiCache)
                UserDefaults.standard.set(encodedKPI, forKey: self.kpiKey)
                print("KPI saved successfully")
            } catch {
                print("Failed to encode KPI: \(error)")
            }
            
            DispatchQueue.main.async {
                self.calculateKPI()
            }
        }
    }
    
    func loadData() {
        if let data = UserDefaults.standard.data(forKey: expensesKey),
           let decoded = try? JSONDecoder().decode([Expense].self, from: data) {
            expenses = decoded
            print("Loaded \(expenses.count) expenses")
        }
        if let data = UserDefaults.standard.data(forKey: incomesKey),
           let decoded = try? JSONDecoder().decode([Income].self, from: data) {
            incomes = decoded
            print("Loaded \(incomes.count) incomes")
        }
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = decoded
            print("Loaded settings")
        }
        if let data = UserDefaults.standard.data(forKey: kpiKey),
           let decoded = try? JSONDecoder().decode(KPI.self, from: data) {
            kpiCache = decoded
            print("Loaded KPI")
        }
    }
    
    func calculateKPI(for period: DateInterval? = nil) {
        let now = Date()
        let startDate: Date
        switch settings.defaultPeriod {
        case "week": startDate = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        case "quarter": startDate = Calendar.current.date(byAdding: .month, value: -3, to: now)!
        default: startDate = Calendar.current.date(byAdding: .month, value: -1, to: now)!
        }
        let interval = DateInterval(start: period?.start ?? startDate, end: period?.end ?? now)
        
        let periodExpenses = expenses.filter { interval.contains($0.date) }
        let totalExpenses = periodExpenses.reduce(0) { $0 + $1.amount }
        
        let periodIncomes = incomes.filter { interval.contains($0.date) }
        let totalRevenue = periodIncomes.reduce(0) { $0 + ($1.quantity * $1.pricePerUnit) }
        
        let totalEggs = Double(settings.hensCount) * settings.avgLaidPerDay * Double(interval.duration / 86400) // approx
        
        let costPerEgg = totalEggs > 0 ? totalExpenses / totalEggs : 0
        let profit = totalRevenue - totalExpenses
        
        kpiCache = KPI(period: settings.defaultPeriod, eggsCount: totalEggs, costPerEgg: costPerEgg, revenue: totalRevenue, profit: profit)
        saveData()
    }
    
    func marginPerEgg() -> Double {
        guard let kpi = kpiCache else { return 0 }
        let avgSalePrice = incomes.isEmpty ? 0 : incomes.reduce(0) { $0 + $1.pricePerUnit } / Double(incomes.count)
        return avgSalePrice - kpi.costPerEgg
    }
    
    func breakEvenPrice() -> Double {
        guard let kpi = kpiCache else { return 0 }
        return kpi.costPerEgg
    }
    
    func breakEvenVolume() -> Double {
        guard let kpi = kpiCache else { return 0 }
        let avgSalePrice = incomes.isEmpty ? 0 : incomes.reduce(0) { $0 + $1.pricePerUnit } / Double(incomes.count)
        return avgSalePrice > 0 ? kpi.revenue / avgSalePrice : 0
    }
    
    func scheduleNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        if let kpi = kpiCache, kpi.costPerEgg > 5 {
            let content = UNMutableNotificationContent()
            content.title = "Cost per egg exceeded threshold!"
            content.body = "Check your expenses!"
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    func exportCSV() -> URL? {
        let csvString = "ID,Category,Amount,Date\n" + expenses.map { "\($0.id),\($0.category),\($0.amount),\($0.date)" }.joined(separator: "\n")
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("expenses.csv")
        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            print("CSV exported to: \(fileURL)")
            return fileURL
        } catch {
            print("Failed to export CSV: \(error)")
            return nil
        }
    }
    
    func backupToiCloud() {
        NSUbiquitousKeyValueStore.default.set(UserDefaults.standard.dictionaryRepresentation(), forKey: "allData")
        NSUbiquitousKeyValueStore.default.synchronize()
        print("iCloud backup completed")
    }
}
