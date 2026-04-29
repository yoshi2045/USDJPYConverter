import Foundation

struct ExchangeRate: Codable {
    let rate: Double
    let fetchedAt: Date

    static let fallbackRate: Double = 150.0
}
