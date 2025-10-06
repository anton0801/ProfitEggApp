import Foundation

struct Expense: Identifiable, Codable {
    let id: UUID
    var category: String
    var amount: Double
    var unitCost: Double?
    var quantity: Double?
    var date: Date
    var note: String?

    enum CodingKeys: String, CodingKey {
        case id
        case category
        case amount
        case unitCost
        case quantity
        case date
        case note
    }

    init(id: UUID = UUID(), category: String, amount: Double, unitCost: Double? = nil, quantity: Double? = nil, date: Date, note: String? = nil) {
        self.id = id
        self.category = category
        self.amount = amount.isFinite ? amount : 0 // Guard against NaN/Infinity
        self.unitCost = unitCost?.isFinite ?? true ? unitCost : nil
        self.quantity = quantity?.isFinite ?? true ? quantity : nil
        self.date = date
        self.note = note
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        category = try container.decode(String.self, forKey: .category)
        amount = try container.decode(Double.self, forKey: .amount)
        unitCost = try container.decodeIfPresent(Double.self, forKey: .unitCost)
        quantity = try container.decodeIfPresent(Double.self, forKey: .quantity)
        date = try container.decode(Date.self, forKey: .date)
        note = try container.decodeIfPresent(String.self, forKey: .note)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(category, forKey: .category)
        try container.encode(amount, forKey: .amount)
        try container.encodeIfPresent(unitCost, forKey: .unitCost)
        try container.encodeIfPresent(quantity, forKey: .quantity)
        try container.encode(date, forKey: .date)
        try container.encodeIfPresent(note, forKey: .note)
    }
}

struct Income: Identifiable, Codable {
    let id: UUID
    var quantity: Double
    var pricePerUnit: Double
    var channel: String
    var date: Date
    var buyer: String?

    enum CodingKeys: String, CodingKey {
        case id
        case quantity
        case pricePerUnit
        case channel
        case date
        case buyer
    }

    init(id: UUID = UUID(), quantity: Double, pricePerUnit: Double, channel: String, date: Date, buyer: String? = nil) {
        self.id = id
        self.quantity = quantity.isFinite ? quantity : 0 // Guard against NaN/Infinity
        self.pricePerUnit = pricePerUnit.isFinite ? pricePerUnit : 0
        self.channel = channel
        self.date = date
        self.buyer = buyer
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        quantity = try container.decode(Double.self, forKey: .quantity)
        pricePerUnit = try container.decode(Double.self, forKey: .pricePerUnit)
        channel = try container.decode(String.self, forKey: .channel)
        date = try container.decode(Date.self, forKey: .date)
        buyer = try container.decodeIfPresent(String.self, forKey: .buyer)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(quantity, forKey: .quantity)
        try container.encode(pricePerUnit, forKey: .pricePerUnit)
        try container.encode(channel, forKey: .channel)
        try container.encode(date, forKey: .date)
        try container.encodeIfPresent(buyer, forKey: .buyer)
    }
}

struct AppSettings: Codable {
    var currency: String = "$"
    var priceMode: String = "unit" // or "dozen"
    var hensCount: Int = 10
    var avgLaidPerDay: Double = 0.8
    var defaultPeriod: String = "month" // week, month
}

struct KPI: Codable {
    var period: String
    var eggsCount: Double
    var costPerEgg: Double
    var revenue: Double
    var profit: Double
}
