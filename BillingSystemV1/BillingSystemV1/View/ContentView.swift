//Update 4

import SwiftUI
import AppKit
import PDFKit

struct ContentView: View {
    @State private var name = ""
    @State private var price = ""
    @State private var dateString = ""
    @State private var date = Date()
    @State private var showCalendar = false

    @State private var items: [Item] = []
    @State private var selectedItem: Item? = nil
    @State private var loadedFileURL: URL? = nil



    var totalCost: Double {
        items.reduce(0) { $0 + $1.price }
    }

    var body: some View {
        HStack {
            VStack(spacing: 16) {
                Text("Neues Item")
                    .font(.title2)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .center)

                TextField("Name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 250)
                    .frame(maxWidth: .infinity, alignment: .center)

                TextField("Preis", text: $price)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 250)
                    .frame(maxWidth: .infinity, alignment: .center)

                VStack(spacing: 8) {
                    HStack {
                        Text("Datum: \(dateString.isEmpty ? "–" : dateString)")
                        Button {
                            showCalendar.toggle()
                        } label: {
                            Image(systemName: "calendar")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)

                    if showCalendar {
                        DatePicker("Datum auswählen", selection: $date, displayedComponents: [.date])
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .onChange(of: date) { newDate in
                                dateString = formatDate(newDate)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }.frame(width: 250)

                Divider()
                VStack{
                    Text("Filtering & Editing")
                        .font(.title2)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .center)
                    Menu("Basics"){
                        Section("Add | Delete | Edit"){
                            Button("Add") {addItem()}.font(.title3).keyboardShortcut(.return,modifiers: [])
                            Button("Clear"){clearList()}.font(.title3).keyboardShortcut("c",modifiers: [.command])
                            if let selected = selectedItem {
                                Button("Delete") {
                                    removeItem(selected)
                                }
                                .font(.title2)
                                .keyboardShortcut(.delete, modifiers: [.command])
                            }
                            if let selected = selectedItem {
                                Button("Edit") {
                                    editItem(selected)
                                }
                            }
                            
                        }
                        Section("Save | Export"){
                            Button("Export PDF") {
                                printList()
                            }
                            .font(.title3)
                            .keyboardShortcut("p", modifiers: [.command])
                            Button("Save Reciept") {
                                saveJSON(items: items)
                            }
                            .font(.title3)
                            .keyboardShortcut("s", modifiers: [.command])
                        }
                        Section("Open | Refresh"){
                            Button("Open Receipt") {
                                openJSON()
                            }
                            .font(.title3)
                            .keyboardShortcut("o", modifiers: [.command])
                            Button("↻ Refresh") {
                                items = loadItemsFromFile()
                            }
                            .font(.title3)
                            .keyboardShortcut("r",modifiers: [.command])
                        }
                    }.font(.title3).frame(width: 250)
    
                    Menu("Sortieren") {
                        Section("Name") {
                            Button("A → Z") { sortItemsByName(ascending: true) }
                            Button("Z → A") { sortItemsByName(ascending: false) }
                        }
                        Section("Preis") {
                            Button("Günstig → Teuer") { sortItemsByPrice(ascending: true) }
                            Button("Teuer → Günstig") { sortItemsByPrice(ascending: false) }
                        }
                        Section("Datum") {
                            Button("Alt → Neu") { sortItemsByDate(ascending: true) }
                            Button("Neu → Alt") { sortItemsByDate(ascending: false) }
                        }
                    }.font(.title3).frame(width: 250)

                    Spacer()
                }
                .padding()
                .frame(width: 250)
            }
                
            Divider()
            
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
                            if selectedItem == item {
                                selectedItem = nil  // Toggle aus
                            } else {
                                selectedItem = item  // Neues Item selektieren
                            }
                        }
                    }
                }
                .padding()

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

    func saveJSON(items: [Item]) {
        let savePanel = NSSavePanel()
        savePanel.title = "JSON-Datei speichern"
        savePanel.message = "Wähle einen Dateinamen und Speicherort"
        savePanel.allowedFileTypes = ["json"]
        savePanel.nameFieldStringValue = "items.json"
        savePanel.canCreateDirectories = true

        // Standardordner: ~/Documents/BillingSystem/JSON
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let defaultFolder = documentsURL.appendingPathComponent("BillingSystem/JSON")
        
        if !fileManager.fileExists(atPath: defaultFolder.path) {
            do {
                try fileManager.createDirectory(at: defaultFolder, withIntermediateDirectories: true)
            } catch {
                print("❌ Fehler beim Erstellen des JSON-Ordners: \(error)")
                return
            }
        }

        savePanel.directoryURL = defaultFolder

        savePanel.begin { result in
            guard result == .OK, let url = savePanel.url else {
                print("❌ Speichern abgebrochen oder fehlgeschlagen.")
                return
            }

            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let data = try encoder.encode(items)
                try data.write(to: url)
                print("✅ JSON gespeichert unter: \(url.path)")
            } catch {
                print("❌ Fehler beim Schreiben der Datei: \(error)")
            }
        }
    }
    
    func openJSON() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Rechnung laden"
        openPanel.allowedFileTypes = ["json"]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false

        let defaultFolder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("BillingSystem/JSON")
        openPanel.directoryURL = defaultFolder

        openPanel.begin { result in
            guard result == .OK, let url = openPanel.url else {
                print("❌ Laden abgebrochen")
                return
            }

            do {
                let data = try Data(contentsOf: url)
                let decodedItems = try JSONDecoder().decode([Item].self, from: data)
                self.items = decodedItems
                self.loadedFileURL = url
                print("✅ JSON geladen von: \(url.path)")
            } catch {
                print("❌ Fehler beim Laden oder Dekodieren: \(error)")
            }
        }
    }


    func addItem() {
        guard !name.isEmpty, !price.isEmpty, !dateString.isEmpty,
              let preis = Double(price) else {
            print("❌ Ungültige Eingabe")
            return
        }

        let newItem = Item(name: name, price: preis, date: dateString)
        items.append(newItem)

        // Direkt ins aktuell geladene File schreiben
        if let fileURL = loadedFileURL {
            do {
                let data = try JSONEncoder().encode(items)
                try data.write(to: fileURL)
                print("✅ Item gespeichert in: \(fileURL.lastPathComponent)")
            } catch {
                print("❌ Fehler beim Speichern in geladene Datei: \(error)")
            }
        } else {
            saveItemsToFile(items) // fallback
        }

        name = ""
        price = ""
        dateString = ""
        selectedItem = nil
    }


    func clearList() {
        items.removeAll()
        saveItemsToFile(items)
        selectedItem = nil
    }

    func removeItem(_ item: Item) {
        items.removeAll { $0.id == item.id }
        selectedItem = nil
        saveItemsToFile(items)
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    func getItemsFileURL() -> URL {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let billingFolder = documentsURL.appendingPathComponent("BillingSystem")
        let jsonFolder = billingFolder.appendingPathComponent("JSON")

        // Ordner anlegen, falls sie noch nicht existieren
        if !fileManager.fileExists(atPath: jsonFolder.path) {
            do {
                try fileManager.createDirectory(at: jsonFolder, withIntermediateDirectories: true)
            } catch {
                print("❌ Fehler beim Erstellen des JSON-Ordners: \(error)")
            }
        }

        return jsonFolder.appendingPathComponent("items.json")
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

                text.append(NSAttributedString(string: "-----------------------------------------------\n", attributes: [
                    .font: NSFont.systemFont(ofSize: 12)
                ]))

                // 🔹 Items
                text.append(NSAttributedString(string: "\n", attributes: [:])) // Leerzeile

                let monospacedFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)

                for item in items {
                    let name = item.name
                    let price = String(format: "%.2f", item.price)
                    let date = item.date

                    // Dynamische Padding-Berechnung (z.B. auf 14 Zeichen fixieren)
                    let namePadding = String(repeating: " ", count: max(0, 14 - name.count))
                    let pricePadding = String(repeating: " ", count: max(0, 8 - price.count))

                    let line = "\(name)\(namePadding)€\(pricePadding)\(price)   \(date)\n"

                    text.append(NSAttributedString(string: line, attributes: [
                        .font: monospacedFont
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
   
    
    //MARK: --- Sort name ---
    func sortItemsByName(ascending: Bool = true) {
        if ascending {
            items.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } else {
            items.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        }
        saveItemsToFile(items)
    }

    //MARK: --- Sort date ---
    func sortItemsByDate(ascending: Bool = true) {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"

        items.sort {
            guard
                let d1 = formatter.date(from: $0.date),
                let d2 = formatter.date(from: $1.date)
            else {
                return false
            }
            return ascending ? d1 < d2 : d1 > d2
        }

        saveItemsToFile(items)
    }

    //MARK: --- Sort price ---
    func sortItemsByPrice(ascending: Bool = true) {
        if ascending {
            items.sort { $0.price < $1.price }
        } else {
            items.sort { $0.price > $1.price }
        }
        saveItemsToFile(items)
    }
    
    func editItem(_ selected: Item) {
        name = selected.name
        price = String(format: "%.2f", selected.price) // Double → String
        dateString = selected.date                     // String bleibt String
        if let parsedDate = parseDate(from: selected.date) {
            date = parsedDate                          // String → Date
        }
    }
    func parseDate(from string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.date(from: string)
    }

}

#Preview {
    ContentView()
}
