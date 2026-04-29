import Foundation

final class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    private let defaults = UserDefaults.standard

    private enum Key: String {
        case exchangeRate
        case exchangeRateFetchedAt
    }

    private init() {}

    func saveExchangeRate(_ rate: ExchangeRate) {
        defaults.set(rate.rate, forKey: Key.exchangeRate.rawValue)
        defaults.set(rate.fetchedAt, forKey: Key.exchangeRateFetchedAt.rawValue)
    }

    func loadExchangeRate() -> ExchangeRate? {
        guard
            let fetchedAt = defaults.object(forKey: Key.exchangeRateFetchedAt.rawValue) as? Date,
            defaults.double(forKey: Key.exchangeRate.rawValue) > 0
        else { return nil }
        let rate = defaults.double(forKey: Key.exchangeRate.rawValue)
        return ExchangeRate(rate: rate, fetchedAt: fetchedAt)
    }
}
