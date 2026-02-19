import SwiftUI
import SwiftData

struct BooksListView: View {
    @StateObject private var viewModel = BooksViewModel()
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<ResourceEntity> { $0.type == "book" }, sort: \.lastUpdated, order: .reverse) private var books: [ResourceEntity]
    @State private var showingAddSheet = false
    @State private var wishlistExpanded = true
    @State private var notStartedExpanded = true
    @State private var inProgressExpanded = true
    @State private var completedExpanded = true
    @State private var archivedExpanded = false

    private var wishlistBooks: [ResourceEntity] { books.filter { $0.progressStatus == .wishlist } }
    private var notStartedBooks: [ResourceEntity] { books.filter { $0.progressStatus == .notStarted } }
    private var inProgressBooks: [ResourceEntity] { books.filter { $0.progressStatus == .inProgress } }
    private var completedBooks: [ResourceEntity] { books.filter { $0.progressStatus == .completed } }
    private var archivedBooks: [ResourceEntity] { books.filter { $0.progressStatus == .archived } }

    var body: some View {
        List {
            if books.isEmpty {
                emptyStateView
            } else {
                if !wishlistBooks.isEmpty {
                    Section {
                        DisclosureGroup(isExpanded: $wishlistExpanded) {
                            ForEach(wishlistBooks) { book in
                                bookRow(book)
                            }
                        } label: {
                            Text("Pendientes (\(wishlistBooks.count))")
                        }
                    }
                }

                if !notStartedBooks.isEmpty {
                    Section {
                        DisclosureGroup(isExpanded: $notStartedExpanded) {
                            ForEach(notStartedBooks) { book in
                                bookRow(book)
                            }
                        } label: {
                            Text("Sin empezar (\(notStartedBooks.count))")
                        }
                    }
                }

                if !inProgressBooks.isEmpty {
                    Section {
                        DisclosureGroup(isExpanded: $inProgressExpanded) {
                            ForEach(inProgressBooks) { book in
                                bookRow(book)
                            }
                        } label: {
                            Text("En progreso (\(inProgressBooks.count))")
                        }
                    }
                }

                if !completedBooks.isEmpty {
                    Section {
                        DisclosureGroup(isExpanded: $completedExpanded) {
                            ForEach(completedBooks) { book in
                                bookRow(book)
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            book.progressStatus = .archived
                                            book.lastUpdated = Date()
                                        } label: {
                                            Label("Archivar", systemImage: "archivebox")
                                        }
                                        .tint(.gray)
                                    }
                            }
                        } label: {
                            Text("Completados (\(completedBooks.count))")
                        }
                    }
                }

                if !archivedBooks.isEmpty {
                    Section {
                        DisclosureGroup(isExpanded: $archivedExpanded) {
                            ForEach(archivedBooks) { book in
                                bookRow(book)
                            }
                        } label: {
                            Text("Archivados (\(archivedBooks.count))")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Libros")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            BookSearchView(viewModel: viewModel, isPresented: $showingAddSheet)
        }
    }

    private func bookRow(_ book: ResourceEntity) -> some View {
        NavigationLink(destination: ResourceDetailView(resource: book)) {
            BookRowView(book: book)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                modelContext.delete(book)
            } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "book")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No hay libros")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Toca + para añadir tu primer libro")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .listRowBackground(Color.clear)
    }
}

struct BookRowView: View {
    let book: ResourceEntity

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: book.imageURL ?? "")) { phase in
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

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)

                if let author = book.authorOrCreator, !author.isEmpty {
                    Text(author)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 8) {
                    StatusBadge(status: book.progressStatus)

                    if let rating = book.userRating {
                        RatingView(rating: rating)
                    }
                }

                if book.progressStatus == .inProgress {
                    if let current = book.currentPage, let total = book.totalPages, total > 0 {
                        Text("Pág. \(current)/\(total) (\(Int(min(Double(current) / Double(total), 1.0) * 100))%)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    } else if let pct = book.progressPercentage, pct > 0 {
                        Text("\(Int(pct))%")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }

                dateLabel(start: book.startDate, end: book.endDate)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct BookSearchView: View {
    @ObservedObject var viewModel: BooksViewModel
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
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
                    Button(showingManualEntry ? "Añadir" : "Manual") {
                        if showingManualEntry && !manualTitle.isEmpty {
                            viewModel.addBook(title: manualTitle, author: manualAuthor.isEmpty ? nil : manualAuthor, context: modelContext)
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
                    BookSearchResultRow(
                        title: item.title,
                        subtitle: item.author,
                        imageURL: item.coverURL,
                        onAdd: {
                            viewModel.addBook(from: item, context: modelContext)
                            isPresented = false
                        },
                        onWishlist: {
                            viewModel.addBookToWishlist(from: item, context: modelContext)
                            isPresented = false
                        }
                    )
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

struct BookSearchResultRow: View {
    let title: String
    let subtitle: String
    let imageURL: String?
    let onAdd: () -> Void
    let onWishlist: () -> Void

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
                onWishlist()
            } label: {
                Image(systemName: "bookmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
            }
            .buttonStyle(.plain)

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

struct StatusBadge: View {
    let status: ProgressStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(4)
    }

    private var backgroundColor: Color {
        switch status {
        case .wishlist: return Color.orange.opacity(0.2)
        case .notStarted: return Color.gray.opacity(0.2)
        case .inProgress: return Color.blue.opacity(0.2)
        case .completed: return Color.green.opacity(0.2)
        case .archived: return Color(.systemGray4).opacity(0.5)
        }
    }

    private var foregroundColor: Color {
        switch status {
        case .wishlist: return .orange
        case .notStarted: return .gray
        case .inProgress: return .blue
        case .completed: return .green
        case .archived: return Color(.systemGray)
        }
    }
}

struct RatingView: View {
    let rating: Double

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "star.fill")
                .font(.caption)
                .foregroundColor(.yellow)
            Text(String(format: "%.1f", rating))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

@ViewBuilder
func dateLabel(start: Date?, end: Date?) -> some View {
    let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.locale = Locale(identifier: "es")
        return f
    }()

    if let s = start, let e = end {
        Text("\(formatter.string(from: s)) - \(formatter.string(from: e))")
            .font(.caption2)
            .foregroundColor(.secondary)
    } else if let s = start {
        Text("Desde \(formatter.string(from: s))")
            .font(.caption2)
            .foregroundColor(.secondary)
    }
}

#Preview {
    NavigationStack {
        BooksListView()
    }
    .modelContainer(DataStore.shared.modelContainer)
}
