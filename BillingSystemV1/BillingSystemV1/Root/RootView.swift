import SwiftUI

enum Page {
    case main
    case settings
    case statistics
}

struct RootView: View {
    @State private var selectedPage: Page = .main
    @State private var isSidebarVisible: Bool = true

    var body: some View {
        HStack(spacing: 0) {
            if isSidebarVisible {
                Sidebar(selectedPage: $selectedPage, isSidebarVisible: $isSidebarVisible)
            }

            Divider()

            Group {
                switch selectedPage {
                case .main:
                    ContentView()
                case .settings:
                    SettingsPage()
                case .statistics:
                    StatisticsPage()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
