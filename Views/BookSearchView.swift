import SwiftUI
import SwiftData

struct BookSearchView: View {
    @ObservedObject var viewModel: BooksViewModel
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var modelContext
    @State private var manualTitle = ""
    @State private var manualAuthor = ""
    @State private var showingManualEntry = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !showingManualEntry {
                    searchSection
                } else {
                    manualEntrySection
                }
            }
            .navigationTitle("Añadir Libro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(showingManualEntry ? "Buscar" : "Manual") {
                        if showingManualEntry && !manualTitle.isEmpty {
                            viewModel.setModelContext(modelContext)
                            viewModel.addBook(title: manualTitle, author: manualAuthor.isEmpty ? nil : manualAuthor)
                            isPresented = false
                        } else {
                            showingManualEntry.toggle()
                        }
                    }
                    .disabled(showingManualEntry && manualTitle.isEmpty)
                }
            }
        }
    }
    
    private var searchSection: some View {
        VStack(spacing: 16) {
            HStack {
                TextField("Buscar por título...", text: $viewModel.searchQuery)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.search)
                    .onSubmit {
                        viewModel.searchBooks()
                    }
                
                Button {
                    viewModel.searchBooks()
                } label: {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .disabled(viewModel.searchQuery.isEmpty)
            }
            .padding()
            
            if viewModel.isLoading {
                ProgressView("Buscando...")
                    .padding()
            } else if viewModel.searchResults.isEmpty && !viewModel.searchQuery.isEmpty {
                Text("No se encontraron resultados")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                List(viewModel.searchResults, id: \.externalId) { item in
                    SearchResultRow(
                        title: item.title,
                        subtitle: item.author,
                        imageURL: item.coverURL
                    ) {
                        viewModel.setModelContext(modelContext)
                        viewModel.addBook(from: item)
                        isPresented = false
                    }
                }
                .listStyle(.plain)
            }
        }
    }
    
    private var manualEntrySection: some View {
        Form {
            Section("Información del libro") {
                TextField("Título", text: $manualTitle)
                TextField("Autor (opcional)", text: $manualAuthor)
            }
        }
    }
}

struct SearchResultRow: View {
    let title: String
    let subtitle: String
    let imageURL: String?
    let onAdd: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: imageURL ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure, .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay {
                            Image(systemName: "book")
                                .foregroundColor(.secondary)
                        }
                @unknown default:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
            }
            .frame(width: 48, height: 64)
            .cornerRadius(6)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .lineLimit(2)
                
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Button {
                onAdd()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    BookSearchView(viewModel: BooksViewModel(), isPresented: .constant(true))
}
