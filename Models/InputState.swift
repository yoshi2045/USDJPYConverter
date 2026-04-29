import Foundation

struct InputState {
    /// Numeric string as typed (e.g. "10", "1.5"). Never empty; "0" when cleared.
    var rawNumber: String = "0"
    /// Selected unit (nil = plain number, no unit applied)
    var unit: UnitType? = nil

    var displayNumber: String { rawNumber }

    var isEmpty: Bool { rawNumber == "0" }
}
