import SwiftUI

struct StatisticsPage: View {
    var body: some View {
        VStack {
            Text("🗂️ Saved Reciepts")
                .font(.largeTitle)
                .bold()
            Text("Hier können Grafiken, Analysen usw. rein.")
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
