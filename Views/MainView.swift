import SwiftUI

struct MainView: View {
    @State private var vm = ConverterViewModel()
    @State private var showSettings = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                ResultDisplayView(vm: vm)
                    .frame(maxHeight: .infinity)
                CustomKeyboardView(vm: vm)
                FunctionButtonsView(vm: vm, showSettings: $showSettings)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    MainView()
}
