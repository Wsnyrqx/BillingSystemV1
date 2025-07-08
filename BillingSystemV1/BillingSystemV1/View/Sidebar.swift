import SwiftUI

struct Sidebar: View {
    @Binding var selectedPage: Page
    @Binding var isSidebarVisible: Bool

    var body: some View {
        VStack(spacing: 32) {
            Button(action: {
                selectedPage = .main
            }) {
                Text("🏠 Home")
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: {
                selectedPage = .settings
            }) {
                Text("⚙️ Einstellungen")
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: {
                selectedPage = .statistics
            }) {
                Text("📊 Statistik")
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 12)
        .frame(width: 200)
        .background(Color.gray.opacity(0.1))
    }
}
