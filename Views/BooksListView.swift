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
        ZStack {
            MeshBackgroundView()

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
                                SectionHeader(status: .wishlist, count: wishlistBooks.count)
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
                                SectionHeader(status: .notStarted, count: notStartedBooks.count)
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
                                SectionHeader(status: .inProgress, count: inProgressBooks.count)
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
                                                withAnimation {
                                                    book.progressStatus = .archived
                                                    book.lastUpdated = Date()
                                                }
                                            } label: {
                                                Label("Archivar", systemImage: "archivebox")
                                            }
                                            .tint(ProgressStatus.archived.color)
                                        }
                                }
                            } label: {
                                SectionHeader(status: .completed, count: completedBooks.count)
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
                                SectionHeader(status: .archived, count: archivedBooks.count)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
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
                withAnimation {
                    modelContext.delete(book)
                }
            } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.fill")
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.bookColor.opacity(0.4))

            VStack(spacing: 6) {
                Text("No hay libros")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("Toca + para añadir tu primer libro")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
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
            ResourceThumbnail(url: book.imageURL, icon: "book.fill", color: AppTheme.bookColor)

            VStack(alignment: .leading, spacing: 5) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)

                if let author = book.authorOrCreator, !author.isEmpty {
                    Text(author)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 6) {
                    StatusBadge(status: book.progressStatus)

                    if let rating = book.userRating {
                        RatingView(rating: rating)
                    }

                    if book.reviewComment != nil && !(book.reviewComment ?? "").isEmpty {
                        Image(systemName: "text.quote")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                if book.progressStatus == .inProgress {
                    if let current = book.currentPage, let total = book.totalPages, total > 0 {
                        ProgressRow(
                            text: "Pág. \(current)/\(total)",
                            value: min(Double(current) / Double(total), 1.0)
                        )
                    } else if let pct = book.progressPercentage, pct > 0 {
                        ProgressRow(text: "\(Int(pct))%", value: pct / 100)
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
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Buscar por título...", text: $viewModel.searchQuery)
                        .submitLabel(.search)
                        .onSubmit {
                            viewModel.searchBooks()
                        }
                }
                .padding(10)
                .background(Color(.tertiarySystemFill))
                .cornerRadius(10)

                if !viewModel.searchQuery.isEmpty {
                    Button("Buscar") {
                        viewModel.searchBooks()
                    }
                    .fontWeight(.medium)
                }
            }
            .padding()

            if viewModel.isLoading {
                Spacer()
                ProgressView("Buscando...")
                Spacer()
            } else if viewModel.searchResults.isEmpty && !viewModel.searchQuery.isEmpty {
                Spacer()
                Text("No se encontraron resultados")
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                List(viewModel.searchResults, id: \.externalId) { item in
                    SearchResultRow(
                        title: item.title,
                        subtitle: item.author,
                        imageURL: item.coverURL,
                        icon: "book.fill",
                        color: AppTheme.bookColor,
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

// MARK: - Shared Components

struct SectionHeader: View {
    let status: ProgressStatus
    let count: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: status.icon)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 26, height: 26)
                .background(status.color, in: RoundedRectangle(cornerRadius: 6, style: .continuous))

            Text(status.sectionTitle)
                .font(.subheadline)
                .fontWeight(.semibold)

            Spacer()

            Text("\(count)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct ResourceThumbnail: View {
    let url: String?
    let icon: String
    let color: Color

    var body: some View {
        AsyncImage(url: URL(string: url ?? "")) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure, .empty:
                Rectangle()
                    .fill(AppTheme.placeholderFill)
                    .overlay {
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundStyle(color.opacity(0.5))
                    }
            @unknown default:
                Rectangle()
                    .fill(AppTheme.placeholderFill)
            }
        }
        .frame(width: AppTheme.thumbnailSize.width, height: AppTheme.thumbnailSize.height)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.thumbnailRadius, style: .continuous))
        .shadow(color: AppTheme.subtleShadow, radius: 4, y: 2)
    }
}

struct StatusBadge: View {
    let status: ProgressStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundColor(status.color)
            .background(status.color.opacity(0.12))
            .clipShape(Capsule())
    }
}

struct RatingView: View {
    let rating: Double

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "star.fill")
                .font(.caption2)
                .foregroundColor(.yellow)
            Text(String(format: "%.1f", rating))
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }
}

struct ProgressRow: View {
    let text: String
    let value: Double

    var body: some View {
        HStack(spacing: 6) {
            ProgressView(value: min(value, 1.0))
                .tint(value >= 1.0 ? .green : AppTheme.accent)
                .frame(width: 60)
            Text(text)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct SearchResultRow: View {
    let title: String
    let subtitle: String
    let imageURL: String?
    let icon: String
    let color: Color
    let onAdd: () -> Void
    let onWishlist: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ResourceThumbnail(url: imageURL, icon: icon, color: color)

            VStack(alignment: .leading, spacing: 3) {
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
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.orange)
            }
            .buttonStyle(.plain)

            Button {
                onAdd()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.green)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
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
