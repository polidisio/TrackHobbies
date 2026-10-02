import SwiftUI

/// Atribución de las fuentes de datos. TVmaze (CC BY-SA) exige citarlo con enlace desde la app.
struct CreditsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Créditos").font(.headline)
            Link("Libros: Google Books", destination: URL(string: "https://books.google.com")!)
            Link("Series: datos de TVmaze.com", destination: URL(string: "https://www.tvmaze.com")!)
            Link("Juegos: datos de IGDB.com", destination: URL(string: "https://www.igdb.com")!)
        }
        .font(.footnote)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
