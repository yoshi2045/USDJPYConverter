import Foundation

final class ExchangeRateService {
    static let shared = ExchangeRateService()

    private let apiURL = "https://open.er-api.com/v6/latest/USD"
    private let cacheDuration: TimeInterval = 86_400  // 24 hours

    private init() {}

    /// Returns the current USD/JPY rate. Uses cache when fresh; falls back to last saved or 150.
    func fetchRateIfNeeded() async -> Double {
        if let cached = UserDefaultsManager.shared.loadExchangeRate(),
           Date().timeIntervalSince(cached.fetchedAt) < cacheDuration {
            return cached.rate
        }
        if let fresh = await fetchFromAPI() {
            let exchangeRate = ExchangeRate(rate: fresh, fetchedAt: Date())
            UserDefaultsManager.shared.saveExchangeRate(exchangeRate)
            return fresh
        }
        return UserDefaultsManager.shared.loadExchangeRate()?.rate ?? ExchangeRate.fallbackRate
    }

    private func fetchFromAPI() async -> Double? {
        guard let url = URL(string: apiURL) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(ERAPIResponse.self, from: data)
            return response.rates["JPY"]
        } catch {
            return nil
        }
    }
}

private struct ERAPIResponse: Decodable {
    let rates: [String: Double]
}
