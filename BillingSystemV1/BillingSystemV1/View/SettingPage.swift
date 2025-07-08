import SwiftUI

struct SettingsPage: View {
    @State private var companyName = ""
    @State private var iban = ""
    
    var body: some View {
        VStack {
            Text("⚙️ Einstellungen")
                .font(.largeTitle)
                .bold()
            TextField("Company Name", text: $companyName).textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 250)
                .frame(maxWidth: .infinity, alignment: .center)
            TextField("IBAN", text:$iban).textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 250)
            Button(action: {
                // Submit-Aktion
            }) {
                Text("Submit")
                    .frame(maxWidth: .infinity, maxHeight: 1)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(6)
            }
            .frame(width: 250)
            .buttonStyle(PlainButtonStyle())

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
