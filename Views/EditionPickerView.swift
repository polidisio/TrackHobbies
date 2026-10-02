import SwiftUI

/// Busca ediciones del libro en Google Books (vía Worker) para elegir la tuya y copiar sus páginas.
struct EditionPickerView: View {
    let title: String
    let author: String?
    let onPick: (GoogleBookItem) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var editions: [GoogleBookItem] = []
    @State private var loading = true
    @State private var error: String?

    var body: some View {
        NavigationStack {
            List {
                if loading {
                    ProgressView()
                } else if let error {
                    Text(error).foregroundStyle(.secondary)
                } else if editions.isEmpty {
                    Text("No se encontraron ediciones con páginas.").foregroundStyle(.secondary)
                }
                ForEach(editions, id: \.externalId) { edition in
                    Button {
                        onPick(edition)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(edition.title).foregroundStyle(.primary)
                            Text("\(edition.author) · \(edition.numberOfPages ?? 0) págs.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Elegir edición")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
            }
            .task {
                do {
                    editions = try await GoogleBooksService.shared.searchEditions(title: title, author: author)
                        .filter { ($0.numberOfPages ?? 0) > 0 }
                } catch {
                    self.error = error.localizedDescription
                }
                loading = false
            }
        }
    }
}
