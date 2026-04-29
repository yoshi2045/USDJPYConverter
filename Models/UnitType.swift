import Foundation

enum UnitType: String, CaseIterable, Codable {
    // US units
    case K, M, B, T, Q
    // JP units (sen is clipboard-only, not on keyboard)
    case sen, man, oku, cho, kei

    var multiplier: Decimal {
        switch self {
        case .K, .sen: return 1_000
        case .M:       return 1_000_000
        case .B:       return 1_000_000_000
        case .T:       return 1_000_000_000_000
        case .Q:       return Decimal(string: "1000000000000000")!
        case .man:     return 10_000
        case .oku:     return 100_000_000
        case .cho:     return 1_000_000_000_000
        case .kei:     return Decimal(string: "10000000000000000")!
        }
    }

    var displayLabel: String {
        switch self {
        case .K:   return "K"
        case .M:   return "M"
        case .B:   return "B"
        case .T:   return "T"
        case .Q:   return "Q"
        case .sen: return "千"
        case .man: return "万"
        case .oku: return "億"
        case .cho: return "兆"
        case .kei: return "京"
        }
    }

    var isJP: Bool {
        switch self {
        case .sen, .man, .oku, .cho, .kei: return true
        default: return false
        }
    }

    /// Units shown on the custom keyboard (excludes K and sen which are clipboard-only)
    static let keyboardUSUnits: [UnitType] = [.Q, .T, .B, .M]
    static let keyboardJPUnits: [UnitType] = [.kei, .cho, .oku, .man]
}
