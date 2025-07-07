import SwiftUI
import AppKit
import PDFKit

struct Item: Identifiable, Codable, Equatable, Hashable {
    var id = UUID()
    let name: String
    let price: Double
    let date: String
}

struct ContentView: View {
    @State private var name = ""
    @State private var price = ""
    @State private var date = ""

    @State private var items: [Item] = []
    @State private var selectedItem: Item? = nil

    var totalCost: Double {
        items.reduce(0) { $0 + $1.price }
    }

    var body: some View {
        HStack {
            // 🔹 Linke Seite: Eingabe + Buttons
            VStack(alignment: .leading, spacing: 16) {
                Text("Neues Item")
                    .font(.title2)
                    .bold()

                TextField("Name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 250)

                TextField("Preis", text: $price)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 250)

                TextField("Datum", text: $date)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 250)

                HStack {
                    Button("+") {
                        addItem()
                    }
                    .font(.title3)

                    Button("Print") {
                        printList()
                    }
                    .font(.title3)
                }

                if let selected = selectedItem {
                    Button("-") {
                        removeItem(selected)
                    }
                    .font(.title2)
                }

                Spacer()
            }
            .padding()

            Divider()

            // 🔹 Rechte Seite: Liste + Total Overlay
            ZStack(alignment: .bottomTrailing) {
                VStack(alignment: .leading) {
                    Text("Items")
                        .font(.title2)
                        .bold()
                        .padding(.bottom, 5)

                    List(items, id: \.id, selection: $selectedItem) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name).bold()
                            Text("€ \(item.price, specifier: "%.2f")")
                            Text("Gekauft am: \(item.date)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                        .background(item == selectedItem ? Color.blue.opacity(0.1) : Color.clear)
                        .onTapGesture {
                            selectedItem = item
                        }
                    }
                }
                .padding()

                // Total Cost Anzeige unten rechts
                Text("Total: € \(totalCost, specifier: "%.2f")")
                    .font(.title2)
                    .bold()
                    .padding()
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(10)
                    .padding(.trailing, 16)
                    .padding(.bottom, 12)
            }
        }
        .onAppear {
            items = loadItemsFromFile()
        }
        .frame(minWidth: 800, minHeight: 500)
    }

    // MARK: - Funktionen

    func addItem() {
        guard !name.isEmpty, !price.isEmpty, !date.isEmpty,
              let preis = Double(price) else {
            print("❌ Ungültige Eingabe")
            return
        }

        let newItem = Item(name: name, price: preis, date: date)
        items.append(newItem)
        saveItemsToFile(items)

        name = ""
        price = ""
        date = ""
        selectedItem = nil
    }

    func removeItem(_ item: Item) {
        items.removeAll { $0.id == item.id }
        selectedItem = nil
        saveItemsToFile(items)
    }

    func printList() {
        let savePanel = NSSavePanel()
        savePanel.allowedFileTypes = ["pdf"]
        savePanel.nameFieldStringValue = "Rechnung.pdf"
        savePanel.canCreateDirectories = true
        savePanel.title = "Rechnung speichern unter"

        savePanel.begin { result in
            guard result == .OK, let url = savePanel.url else {
                print("❌ Speichern abgebrochen")
                return
            }

            let pdfDocument = PDFDocument()
            let pageBounds = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // DIN A4

            let text = NSMutableAttributedString()

            // 🔹 Kopfzeile
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            let currentDate = formatter.string(from: Date())

            let header = """

            RECHNUNG
            Datum: \(currentDate)

            --------------------------------------------

            """
            text.append(NSAttributedString(string: header, attributes: [
                .font: NSFont.systemFont(ofSize: 13)
            ]))

            // 🔹 Tabellenkopf
            let tableHeader = String(format: "%-25@ %-10@ %-12@\n", "Name", "Preis", "Datum")
            text.append(NSAttributedString(string: tableHeader, attributes: [
                .font: NSFont.boldSystemFont(ofSize: 13)
            ]))

            text.append(NSAttributedString(string: "--------------------------------------------\n", attributes: [
                .font: NSFont.systemFont(ofSize: 12)
            ]))

            // 🔹 Items
            for item in items {
                let line = String(format: "%-25@ €%-9.2f %-12@\n", item.name, item.price, item.date)
                text.append(NSAttributedString(string: line, attributes: [
                    .font: NSFont.systemFont(ofSize: 12)
                ]))
            }

            text.append(NSAttributedString(string: "\n", attributes: [:]))

            // 🔹 Total
            let totalLine = "Gesamtsumme: € \(String(format: "%.2f", totalCost))"
            text.append(NSAttributedString(string: totalLine, attributes: [
                .font: NSFont.boldSystemFont(ofSize: 14)
            ]))

            // 🔹 TextView für PDF-Erstellung
            let textView = NSTextView(frame: pageBounds)
            textView.textStorage?.setAttributedString(text)
            textView.drawsBackground = false

            let rep = textView.bitmapImageRepForCachingDisplay(in: textView.bounds)!
            textView.cacheDisplay(in: textView.bounds, to: rep)

            let image = NSImage(size: textView.bounds.size)
            image.addRepresentation(rep)

            if let pdfPage = PDFPage(image: image) {
                pdfDocument.insert(pdfPage, at: 0)
                if pdfDocument.write(to: url) {
                    print("✅ Rechnung gespeichert: \(url.path)")
                    NSWorkspace.shared.open(url)
                } else {
                    print("❌ PDF konnte nicht gespeichert werden")
                }
            } else {
                print("❌ PDF-Seite konnte nicht erstellt werden")
            }
        }
    }

    func getItemsFileURL() -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("items.json")
    }

    func saveItemsToFile(_ items: [Item]) {
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: getItemsFileURL())
        } catch {
            print("Fehler beim Speichern: \(error)")
        }
    }

    func loadItemsFromFile() -> [Item] {
        let url = getItemsFileURL()
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([Item].self, from: data)
        } catch {
            print("Fehler beim Laden: \(error)")
            return []
        }
    }
}

#Preview {
    ContentView()
}
