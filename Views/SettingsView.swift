import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("clipboardAutoRead") private var clipboardAutoRead = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("クリップボード自動読み取り", isOn: $clipboardAutoRead)
                } footer: {
                    Text("アプリ起動時・フォアグラウンド復帰時にクリップボードの数値を自動で読み込みます。")
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完了") { dismiss() }
                }
            }
        }
    }
}
