import SwiftUI

struct ResultDisplayView: View {
    let vm: ConverterViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            usdSection
            separator
            jpySection
            rateRow
            Spacer()
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Sections

    private var usdSection: some View {
        VStack(alignment: .trailing, spacing: 8) {
            sectionLabel("USD")
            resultRow(vm.result3)
            resultRow(vm.result4)
            resultRow(vm.result5)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 16)
    }

    private var separator: some View {
        Rectangle()
            .fill(Color(white: 0.25))
            .frame(height: 1)
    }

    private var jpySection: some View {
        VStack(alignment: .trailing, spacing: 8) {
            sectionLabel("JPY")
            resultRow(vm.result1)
            resultRow(vm.result2)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
    }

    private var rateRow: some View {
        Text(vm.rateLabel)
            .font(.caption2)
            .foregroundStyle(Color(white: 0.3))
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.top, 12)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(Color(white: 0.45))
            .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func resultRow(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 28, weight: .light, design: .monospaced))
            .foregroundStyle(.white)
            .minimumScaleFactor(0.3)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }
}
