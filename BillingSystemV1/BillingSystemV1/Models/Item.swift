import SwiftUI

struct Item: Identifiable, Codable, Equatable, Hashable {
    var id = UUID()
    let name: String
    let price: Double
    let date: String
}

