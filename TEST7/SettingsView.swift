import SwiftUI

struct SettingsView: View {
    @AppStorage("soundEnabled") private var soundEnabled = true

    var body: some View {
        Form {
            Toggle("Sound", isOn: $soundEnabled)
        }
        .navigationTitle("Settings")
    }
}
