import SwiftUI

struct FunctionButtonsView: View {
    let vm: ConverterViewModel
    @Binding var showSettings: Bool

    var body: some View {
        HStack(spacing: 0) {
            funcButton(icon: "doc.on.clipboard", label: "ペースト") {
                vm.pasteFromClipboard()
            }
            funcButton(icon: "mic", label: "音声") {
                // dummy — not implemented
            }
            .disabled(true)
            .opacity(0.4)
            funcButton(icon: "gearshape", label: "設定") {
                showSettings = true
            }
        }
        .frame(height: 60)
        .background(Color(white: 0.08))
    }

    private func funcButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(label)
                    .font(.caption2)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
    }
}
