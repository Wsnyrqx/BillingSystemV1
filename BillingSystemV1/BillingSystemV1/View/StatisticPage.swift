import SwiftUI

struct StatisticsPage: View {
    var body: some View {
        VStack {
            Text("📊 Statistik")
                .font(.largeTitle)
                .bold()
            Text("Hier können Grafiken, Analysen usw. rein.")
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
