import Foundation

struct SharedCredential: Codable, Equatable {
    let recordIdentifier: String
    var serviceName: String
    var domains: [String]
    var loginURL: String?
    var username: String
    var password: String
    var totpSecret: String?
    var monthlyPrice: Decimal?
    var currency: String?
    var billingCycle: String?
    var renewalDate: Date?
    var paymentMethod: String?
    var cancelURL: String?
    var updatedAt: Date

    init(
        recordIdentifier: String = UUID().uuidString,
        serviceName: String,
        domains: [String] = [],
        loginURL: String? = nil,
        username: String,
        password: String,
        totpSecret: String? = nil,
        monthlyPrice: Decimal? = nil,
        currency: String? = nil,
        billingCycle: String? = nil,
        renewalDate: Date? = nil,
        paymentMethod: String? = nil,
        cancelURL: String? = nil,
        updatedAt: Date = Date()
    ) {
        self.recordIdentifier = recordIdentifier
        self.serviceName = serviceName
        self.domains = domains
        self.loginURL = loginURL
        self.username = username
        self.password = password
        self.totpSecret = totpSecret
        self.monthlyPrice = monthlyPrice
        self.currency = currency
        self.billingCycle = billingCycle
        self.renewalDate = renewalDate
        self.paymentMethod = paymentMethod
        self.cancelURL = cancelURL
        self.updatedAt = updatedAt
    }
}
