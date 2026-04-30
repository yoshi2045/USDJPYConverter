import Testing
import Foundation
@testable import USDJPYConverter

// MARK: - UnitType tests

struct UnitTypeTests {
    @Test func multipliers() {
        #expect(UnitType.K.multiplier == 1_000)
        #expect(UnitType.M.multiplier == 1_000_000)
        #expect(UnitType.B.multiplier == 1_000_000_000)
        #expect(UnitType.T.multiplier == 1_000_000_000_000)
        #expect(UnitType.Q.multiplier == Decimal(string: "1000000000000000")!)
        #expect(UnitType.man.multiplier == 10_000)
        #expect(UnitType.oku.multiplier == 100_000_000)
        #expect(UnitType.cho.multiplier == 1_000_000_000_000)
        #expect(UnitType.kei.multiplier == Decimal(string: "10000000000000000")!)
    }

    @Test func jpFlag() {
        #expect(UnitType.man.isJP == true)
        #expect(UnitType.kei.isJP == true)
        #expect(UnitType.M.isJP == false)
        #expect(UnitType.Q.isJP == false)
    }

    @Test func displayLabels() {
        #expect(UnitType.M.displayLabel == "M")
        #expect(UnitType.man.displayLabel == "万")
        #expect(UnitType.kei.displayLabel == "京")
    }
}

// MARK: - ConverterViewModel input tests

@MainActor
struct ConverterViewModelInputTests {
    @Test func appendDigitBasic() {
        let vm = ConverterViewModel()
        vm.appendDigit("5")
        #expect(vm.inputState.rawNumber == "5")
        vm.appendDigit("3")
        #expect(vm.inputState.rawNumber == "53")
    }

    @Test func leadingZeroReplaced() {
        let vm = ConverterViewModel()
        vm.appendDigit("0")  // stays 0
        #expect(vm.inputState.rawNumber == "0")
        vm.appendDigit("5")  // 0 → 5
        #expect(vm.inputState.rawNumber == "5")
    }

    @Test func doubleZeroIgnored() {
        let vm = ConverterViewModel()
        vm.appendDigit("0")
        vm.appendDigit("0")
        #expect(vm.inputState.rawNumber == "0")
    }

    @Test func decimalPoint() {
        let vm = ConverterViewModel()
        vm.appendDigit("1")
        vm.appendDigit(".")
        vm.appendDigit("5")
        #expect(vm.inputState.rawNumber == "1.5")
    }

    @Test func duplicateDecimalIgnored() {
        let vm = ConverterViewModel()
        vm.appendDigit("1")
        vm.appendDigit(".")
        vm.appendDigit(".")  // should be ignored
        vm.appendDigit("5")
        #expect(vm.inputState.rawNumber == "1.5")
    }

    @Test func deleteLastCharacter() {
        let vm = ConverterViewModel()
        vm.appendDigit("1")
        vm.appendDigit("2")
        vm.deleteLastCharacter()
        #expect(vm.inputState.rawNumber == "1")
        vm.deleteLastCharacter()
        #expect(vm.inputState.rawNumber == "0")
    }

    @Test func clearAll() {
        let vm = ConverterViewModel()
        vm.appendDigit("9")
        vm.toggleUnit(.M)
        vm.clearAll()
        #expect(vm.inputState.rawNumber == "0")
        #expect(vm.inputState.unit == nil)
    }

    @Test func toggleUnitOnOff() {
        let vm = ConverterViewModel()
        vm.toggleUnit(.M)
        #expect(vm.inputState.unit == .M)
        vm.toggleUnit(.M)  // toggle off
        #expect(vm.inputState.unit == nil)
    }

    @Test func toggleUnitSwitch() {
        let vm = ConverterViewModel()
        vm.toggleUnit(.M)
        vm.toggleUnit(.B)
        #expect(vm.inputState.unit == .B)
    }

    @Test func maxValueBlocked() {
        let vm = ConverterViewModel()
        // Input 9999 — should be allowed
        for d in ["9", "9", "9", "9"] { vm.appendDigit(d) }
        #expect(vm.inputState.rawNumber == "9999")
        // 5th digit would make it 99995 > 9999 — should be blocked
        vm.appendDigit("5")
        #expect(vm.inputState.rawNumber == "9999")
    }
}

// MARK: - ConverterViewModel conversion tests

@MainActor
struct ConverterViewModelConversionTests {
    @Test func result3NoUnit() {
        let vm = ConverterViewModel()
        vm.exchangeRate = 150.0
        vm.appendDigit("1")
        vm.appendDigit("0")
        vm.appendDigit("0")
        // 100 USD → result3 = "$100.00"
        #expect(vm.result3 == "$100.00")
    }

    @Test func result1WithMUnit() {
        let vm = ConverterViewModel()
        vm.exchangeRate = 150.0
        vm.appendDigit("1")
        vm.toggleUnit(.M)
        // 1M USD * 150 = 150,000,000 JPY → result1 = "150,000,000円"
        #expect(vm.result1 == "150,000,000円")
    }

    @Test func result2WithMUnit() {
        let vm = ConverterViewModel()
        vm.exchangeRate = 150.0
        vm.appendDigit("1")
        vm.toggleUnit(.M)
        // 1M USD * 150 = 150M JPY = 1.5億円
        #expect(vm.result2 == "1.5億円")
    }

    @Test func result4WithBUnit() {
        let vm = ConverterViewModel()
        vm.exchangeRate = 150.0
        vm.appendDigit("2")
        vm.toggleUnit(.B)
        // 2B USD → result4 = "$2B"
        #expect(vm.result4 == "$2B")
    }

    @Test func result5WithManUnit() {
        let vm = ConverterViewModel()
        vm.exchangeRate = 150.0
        vm.appendDigit("1")
        vm.toggleUnit(.man)
        // 1万 USD = $10,000 → result5 = "$1万"
        #expect(vm.result5 == "$1万")
    }

    @Test func fallbackRateUsed() {
        let vm = ConverterViewModel()
        // default exchangeRate = 150
        #expect(vm.exchangeRate == ExchangeRate.fallbackRate)
    }

    @Test func emptyInputShowsPlaceholder() {
        let vm = ConverterViewModel()
        // Initial state: rawNumber == "0" → all results show "---"
        #expect(vm.result1 == "---")
        #expect(vm.result3 == "---")
    }

    @Test func nonZeroInputShowsValue() {
        let vm = ConverterViewModel()
        vm.exchangeRate = 150.0
        vm.appendDigit("1")
        #expect(vm.result3 != "---")
        #expect(vm.result1 != "---")
    }
}

// MARK: - Paste parsing tests

struct PasteParsingTests {
    @Test func plainNumber() throws {
        let result = try #require(ConverterViewModel.parsePastedText("1234"))
        #expect(result.0 == "1234")
        #expect(result.1 == nil)
    }

    @Test func numberWithCommas() throws {
        let result = try #require(ConverterViewModel.parsePastedText("1,234"))
        #expect(result.0 == "1234")
        #expect(result.1 == nil)
    }

    @Test func dollarSignStripped() throws {
        let result = try #require(ConverterViewModel.parsePastedText("$1234"))
        #expect(result.0 == "1234")
    }

    @Test func yenSignStripped() throws {
        let result = try #require(ConverterViewModel.parsePastedText("¥1234"))
        #expect(result.0 == "1234")
    }

    @Test func usSuffixUppercase() throws {
        let result = try #require(ConverterViewModel.parsePastedText("1.5M"))
        #expect(result.0 == "1.5")
        #expect(result.1 == .M)
    }

    @Test func usSuffixLowercase() throws {
        let result = try #require(ConverterViewModel.parsePastedText("1.5m"))
        #expect(result.0 == "1.5")
        #expect(result.1 == .M)
    }

    @Test func jpSuffixMan() throws {
        let result = try #require(ConverterViewModel.parsePastedText("100万"))
        #expect(result.0 == "100")
        #expect(result.1 == .man)
    }

    @Test func jpSuffixOku() throws {
        let result = try #require(ConverterViewModel.parsePastedText("2.5億"))
        #expect(result.0 == "2.5")
        #expect(result.1 == .oku)
    }

    @Test func dollarWithSuffix() throws {
        let result = try #require(ConverterViewModel.parsePastedText("$2.5B"))
        #expect(result.0 == "2.5")
        #expect(result.1 == .B)
    }

    @Test func autoScaleThousands() throws {
        let result = try #require(ConverterViewModel.parsePastedText("10000"))
        #expect(result.0 == "10")
        #expect(result.1 == .K)
    }

    @Test func autoScaleMillions() throws {
        let result = try #require(ConverterViewModel.parsePastedText("1000000"))
        #expect(result.0 == "1")
        #expect(result.1 == .M)
    }

    @Test func autoScaleWithCommas() throws {
        let result = try #require(ConverterViewModel.parsePastedText("1,000,000"))
        #expect(result.0 == "1")
        #expect(result.1 == .M)
    }

    @Test func invalidTextReturnsNil() {
        #expect(ConverterViewModel.parsePastedText("abc") == nil)
    }

    @Test func emptyStringReturnsNil() {
        #expect(ConverterViewModel.parsePastedText("") == nil)
    }

    @Test func whitespaceOnlyReturnsNil() {
        #expect(ConverterViewModel.parsePastedText("   ") == nil)
    }

    @Test func maxBoundary() throws {
        // 9999 is valid without scaling
        let result = try #require(ConverterViewModel.parsePastedText("9999"))
        #expect(result.0 == "9999")
        #expect(result.1 == nil)
    }
}
