import SwiftUI

struct ExportCSVView: View {
    let csvData: String
    @Environment(\.dismiss) private var dismiss
    @State private var shareURL: URL?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if let url = shareURL {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 48))
                            .foregroundStyle(.green)

                        Text("CSV listo para exportar")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("\(csvData.components(separatedBy: "\n").count - 1) libros")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        ShareLink(item: url) {
                            Label("Compartir CSV", systemImage: "square.and.arrow.up")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                } else {
                    ProgressView("Generando CSV...")
                }
            }
            .navigationTitle("Exportar a CSV")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                generateFile()
                Analytics.track("export_started")
            }
        }
    }

    private func generateFile() {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("trackhobbies_books.csv")
        do {
            try csvData.write(to: tempURL, atomically: true, encoding: .utf8)
            shareURL = tempURL
        } catch {
            print("Error generating CSV: \(error)")
        }
    }
}
