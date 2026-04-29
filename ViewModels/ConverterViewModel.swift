import Foundation

@Observable
final class ConverterViewModel {
    var inputState = InputState()
    var exchangeRate: Double = ExchangeRate.fallbackRate

    init() {
        Task {
            exchangeRate = await ExchangeRateService.shared.fetchRateIfNeeded()
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

    // MARK: - Conversion results (5 display patterns)

    /// Pattern 1: 数字のみ、通貨は円
    var result1: String { formatJPYPlain(jpyValue) }

    /// Pattern 2: 日本単位、通貨は円
    var result2: String { formatJPYWithUnit(jpyValue) }

    /// Pattern 3: 数字のみ、通貨はドル
    var result3: String { formatUSDPlain(usdValue) }

    /// Pattern 4: 米国単位、通貨はドル
    var result4: String { formatUSDWithUSUnit(usdValue) }

    /// Pattern 5: 日本単位、通貨はドル
    var result5: String { formatUSDWithJPUnit(usdValue) }

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
