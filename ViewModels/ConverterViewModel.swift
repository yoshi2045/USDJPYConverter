import Foundation
import UIKit

@Observable
final class ConverterViewModel {
    var inputState = InputState()
    var exchangeRate: Double = ExchangeRate.fallbackRate
    var isLoading = true
    private(set) var rateFetchedAt: Date? = nil

    init() {
        Task {
            exchangeRate = await ExchangeRateService.shared.fetchRateIfNeeded()
            rateFetchedAt = UserDefaultsManager.shared.loadExchangeRate()?.fetchedAt
            isLoading = false
        }
    }

    // MARK: - Input handling

    func appendDigit(_ digit: String) {
        let current = inputState.rawNumber

        if digit == "." {
            guard !current.contains(".") else { return }
            inputState.rawNumber = (current == "0" ? "0" : current) + "."
            return
        }

        if current == "0" {
            if digit == "0" { return }
            inputState.rawNumber = digit
        } else {
            let next = current + digit
            guard !isOverMax(next) else { return }
            inputState.rawNumber = next
        }
    }

    func deleteLastCharacter() {
        if inputState.rawNumber.count <= 1 {
            inputState.rawNumber = "0"
            return
        }
        inputState.rawNumber.removeLast()
    }

    func clearAll() {
        inputState.rawNumber = "0"
        inputState.unit = nil
    }

    func toggleUnit(_ unit: UnitType) {
        inputState.unit = (inputState.unit == unit) ? nil : unit
    }

    // MARK: - Paste from clipboard

    func pasteFromClipboard() {
        guard let text = UIPasteboard.general.string else { return }
        guard let (number, unit) = Self.parsePastedText(text) else { return }
        inputState.rawNumber = number
        inputState.unit = unit
    }

    // MARK: - Conversion results (5 display patterns)

    var result1: String { inputState.isEmpty ? "---" : formatJPYPlain(jpyValue) }
    var result2: String { inputState.isEmpty ? "---" : formatJPYWithUnit(jpyValue) }
    var result3: String { inputState.isEmpty ? "---" : formatUSDPlain(usdValue) }
    var result4: String { inputState.isEmpty ? "---" : formatUSDWithUSUnit(usdValue) }
    var result5: String { inputState.isEmpty ? "---" : formatUSDWithJPUnit(usdValue) }

    var rateLabel: String {
        if isLoading { return "レート取得中…" }
        let rate = String(format: "%.2f", exchangeRate)
        let suffix = rateFetchedAt == nil ? " ※推定値" : ""
        return "1 USD ≈ ¥\(rate)\(suffix)"
    }

    // MARK: - Private

    private var usdValue: Decimal {
        let base = Decimal(string: inputState.rawNumber) ?? 0
        guard let unit = inputState.unit else { return base }
        return base * unit.multiplier
    }

    private var jpyValue: Decimal {
        let rateDecimal = Decimal(string: String(format: "%.6f", exchangeRate)) ?? Decimal(150)
        return usdValue * rateDecimal
    }

    private func isOverMax(_ raw: String) -> Bool {
        let intPart = raw.split(separator: ".").first.map(String.init) ?? raw
        return (Int(intPart) ?? 0) > 9999
    }

    // MARK: - Paste parsing

    static func parsePastedText(_ text: String) -> (String, UnitType?)? {
        var s = text.trimmingCharacters(in: .whitespacesAndNewlines)
        s = s.filter { !"$¥￥ ".contains($0) }
        s = s.replacingOccurrences(of: ",", with: "")
        guard !s.isEmpty else { return nil }

        let unitMap: [(String, UnitType)] = [
            ("京", .kei), ("兆", .cho), ("億", .oku), ("万", .man), ("千", .sen),
            ("Q", .Q), ("T", .T), ("B", .B), ("M", .M), ("K", .K)
        ]
        var detectedUnit: UnitType? = nil
        for (suffix, unitType) in unitMap {
            if s.uppercased().hasSuffix(suffix.uppercased()) {
                s = String(s.dropLast(suffix.count))
                detectedUnit = unitType
                break
            }
        }

        guard !s.isEmpty, let value = Decimal(string: s) else { return nil }

        let intPart = s.split(separator: ".").first.map(String.init) ?? s
        if (Int(intPart) ?? 0) <= 9999 {
            return (s, detectedUnit)
        }
        // Integer part exceeds max — auto-scale to nearest US unit (only when no explicit suffix)
        if detectedUnit == nil, let (scaled, unit) = autoScale(value) {
            return (scaled, unit)
        }
        return nil
    }

    private static func autoScale(_ value: Decimal) -> (String, UnitType)? {
        let scales: [(Decimal, UnitType)] = [
            (Decimal(string: "1000000000000000")!, .Q),
            (Decimal(string: "1000000000000")!, .T),
            (Decimal(1_000_000_000), .B),
            (Decimal(1_000_000), .M),
            (Decimal(1_000), .K),
        ]
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 4
        formatter.minimumFractionDigits = 0
        formatter.usesGroupingSeparator = false

        for (threshold, unit) in scales {
            if value >= threshold {
                let scaled = value / threshold
                guard let str = formatter.string(from: scaled as NSDecimalNumber) else { continue }
                let intPart = str.split(separator: ".").first.map(String.init) ?? str
                if (Int(intPart) ?? 0) <= 9999 { return (str, unit) }
            }
        }
        return nil
    }

    // MARK: - Formatters

    private func formatJPYPlain(_ value: Decimal) -> String {
        let handler = NSDecimalNumberHandler(
            roundingMode: .down, scale: 0,
            raiseOnExactness: false, raiseOnOverflow: false,
            raiseOnUnderflow: false, raiseOnDivideByZero: false
        )
        let rounded = (value as NSDecimalNumber).rounding(accordingToBehavior: handler)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return (formatter.string(from: rounded) ?? "0") + "円"
    }

    private func formatJPYWithUnit(_ value: Decimal) -> String {
        let kei = Decimal(string: "10000000000000000")!
        let cho = Decimal(string: "1000000000000")!
        let oku = Decimal(100_000_000)
        let man = Decimal(10_000)

        if value >= kei      { return shortDecimal(value / kei) + "京円" }
        else if value >= cho { return shortDecimal(value / cho) + "兆円" }
        else if value >= oku { return shortDecimal(value / oku) + "億円" }
        else if value >= man { return shortDecimal(value / man) + "万円" }
        return formatJPYPlain(value)
    }

    private func formatUSDPlain(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return "$" + (formatter.string(from: value as NSDecimalNumber) ?? "0.00")
    }

    private func formatUSDWithUSUnit(_ value: Decimal) -> String {
        let Q = Decimal(string: "1000000000000000")!
        let T = Decimal(string: "1000000000000")!
        let B = Decimal(1_000_000_000)
        let M = Decimal(1_000_000)
        let K = Decimal(1_000)

        if value >= Q      { return "$" + shortDecimal(value / Q) + "Q" }
        else if value >= T { return "$" + shortDecimal(value / T) + "T" }
        else if value >= B { return "$" + shortDecimal(value / B) + "B" }
        else if value >= M { return "$" + shortDecimal(value / M) + "M" }
        else if value >= K { return "$" + shortDecimal(value / K) + "K" }
        return formatUSDPlain(value)
    }

    private func formatUSDWithJPUnit(_ value: Decimal) -> String {
        let kei = Decimal(string: "10000000000000000")!
        let cho = Decimal(string: "1000000000000")!
        let oku = Decimal(100_000_000)
        let man = Decimal(10_000)

        if value >= kei      { return "$" + shortDecimal(value / kei) + "京" }
        else if value >= cho { return "$" + shortDecimal(value / cho) + "兆" }
        else if value >= oku { return "$" + shortDecimal(value / oku) + "億" }
        else if value >= man { return "$" + shortDecimal(value / man) + "万" }
        return formatUSDPlain(value)
    }

    /// Formats a Decimal with up to 2 fraction digits, no trailing zeros.
    private func shortDecimal(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: value as NSDecimalNumber) ?? "0"
    }
}
