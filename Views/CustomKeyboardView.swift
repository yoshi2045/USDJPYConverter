import SwiftUI

struct CustomKeyboardView: View {
    let vm: ConverterViewModel

    private let layout: [[KeySpec]] = [
        [.digit("1"), .digit("2"), .digit("3"), .unit(.Q),   .unit(.kei)],
        [.digit("4"), .digit("5"), .digit("6"), .unit(.T),   .unit(.cho)],
        [.digit("7"), .digit("8"), .digit("9"), .unit(.B),   .unit(.oku)],
        [.digit("0"), .decimal,    .delete,     .unit(.M),   .unit(.man)],
    ]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(layout.indices, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(layout[row].indices, id: \.self) { col in
                        makeKey(layout[row][col])
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func makeKey(_ spec: KeySpec) -> some View {
        switch spec {
        case .digit(let d):
            DigitKey(label: d) { vm.appendDigit(d) }
        case .decimal:
            DigitKey(label: ".") { vm.appendDigit(".") }
        case .delete:
            DeleteKey(vm: vm)
        case .unit(let u):
            UnitKey(unit: u, vm: vm)
        }
    }
}

// MARK: - Key spec

private enum KeySpec {
    case digit(String)
    case decimal
    case delete
    case unit(UnitType)
}

// MARK: - Shared button style

private struct KeyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

// MARK: - Digit / decimal key

private struct DigitKey: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 64)
                .background(Color(white: 0.2))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(KeyButtonStyle())
    }
}

// MARK: - Delete key (tap = delete 1 char, long press = clear all)

private struct DeleteKey: View {
    let vm: ConverterViewModel
    @State private var longPressActivated = false

    var body: some View {
        Image(systemName: "delete.left")
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(Color(white: 0.2))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
            .onLongPressGesture(
                minimumDuration: 0.5,
                perform: {
                    longPressActivated = true
                    vm.clearAll()
                },
                onPressingChanged: { isPressing in
                    if !isPressing && !longPressActivated {
                        vm.deleteLastCharacter()
                    }
                    if !isPressing { longPressActivated = false }
                }
            )
    }
}

// MARK: - Unit key (toggleable)

private struct UnitKey: View {
    let unit: UnitType
    let vm: ConverterViewModel

    var body: some View {
        let selected = vm.inputState.unit == unit
        Button { vm.toggleUnit(unit) } label: {
            Text(unit.displayLabel)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(selected ? Color.black : Color.white)
                .frame(maxWidth: .infinity, minHeight: 64)
                .background(selected ? Color.orange : Color(white: 0.14))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(KeyButtonStyle())
    }
}
