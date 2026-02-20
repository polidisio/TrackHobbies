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

    @State private var searchText = ""
    @State private var showingFilters = false
    @State private var selectedStatuses: Set<ProgressStatus> = []
    @State private var minimumRating: Double? = nil
    @State private var datePreset: DatePreset = .all

    private var hasActiveFilters: Bool {
        !searchText.isEmpty || !selectedStatuses.isEmpty || minimumRating != nil || datePreset != .all
    }

    private var filteredBooks: [ResourceEntity] {
        books.filter { book in
            let matchesText = searchText.isEmpty ||
                book.title.localizedCaseInsensitiveContains(searchText) ||
                (book.authorOrCreator ?? "").localizedCaseInsensitiveContains(searchText)
            let matchesStatus = selectedStatuses.isEmpty || selectedStatuses.contains(book.progressStatus)
            let matchesRating = minimumRating == nil || (book.userRating ?? 0) >= minimumRating!
            let matchesDate = datePreset.matches(book.startDate ?? book.lastUpdated)
            return matchesText && matchesStatus && matchesRating && matchesDate
        }
    }

    private var wishlistBooks: [ResourceEntity] { filteredBooks.filter { $0.progressStatus == .wishlist } }
    private var notStartedBooks: [ResourceEntity] { filteredBooks.filter { $0.progressStatus == .notStarted } }
    private var inProgressBooks: [ResourceEntity] { filteredBooks.filter { $0.progressStatus == .inProgress } }
    private var completedBooks: [ResourceEntity] { filteredBooks.filter { $0.progressStatus == .completed } }
    private var archivedBooks: [ResourceEntity] { filteredBooks.filter { $0.progressStatus == .archived } }

    var body: some View {
        ZStack {
            MeshBackgroundView()

            List {
                if books.isEmpty {
                    emptyStateView
                } else {
                    if showingFilters {
                        Section {
                            FilterBarView(
                                selectedStatuses: $selectedStatuses,
                                minimumRating: $minimumRating,
                                datePreset: $datePreset
                            )
                        }
                        .listRowBackground(Color.clear)
                    }

                    if hasActiveFilters {
                        if filteredBooks.isEmpty {
                            noResultsView
                        } else {
                            Section {
                                HStack {
                                    Text("\(filteredBooks.count) resultado\(filteredBooks.count == 1 ? "" : "s")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Button("Limpiar filtros") {
                                        withAnimation {
                                            searchText = ""
                                            selectedStatuses = []
                                            minimumRating = nil
                                            datePreset = .all
                                        }
                                    }
                                    .font(.caption)
                                }
                            }
                            .listRowBackground(Color.clear)

                            Section {
                                ForEach(filteredBooks) { book in
                                    bookRow(book)
                                }
                            }
                        }
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
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .searchable(text: $searchText, prompt: "Buscar por título, autor...")
        }
        .navigationTitle("Libros")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showingFilters.toggle()
                        }
                    } label: {
                        Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .foregroundStyle(hasActiveFilters ? AppTheme.accent : .secondary)
                    }

                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
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

    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(.secondary.opacity(0.5))

            Text("Sin resultados")
                .font(.headline)

            Button("Limpiar filtros") {
                withAnimation {
                    searchText = ""
                    selectedStatuses = []
                    minimumRating = nil
                    datePreset = .all
                }
            }
            .font(.subheadline)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
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

// MARK: - Filter Components

enum DatePreset: String, CaseIterable {
    case all = "Todos"
    case thisWeek = "Esta semana"
    case thisMonth = "Este mes"
    case thisYear = "Este año"
    case olderThanYear = "Hace 1+ año"

    func matches(_ date: Date?) -> Bool {
        guard self != .all else { return true }
        guard let date = date else { return false }
        let calendar = Calendar.current
        let now = Date()
        switch self {
        case .all:
            return true
        case .thisWeek:
            return calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
        case .thisMonth:
            return calendar.isDate(date, equalTo: now, toGranularity: .month)
        case .thisYear:
            return calendar.isDate(date, equalTo: now, toGranularity: .year)
        case .olderThanYear:
            guard let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: now) else { return false }
            return date < oneYearAgo
        }
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .foregroundColor(isSelected ? .white : .primary)
                .background(isSelected ? AppTheme.accent : Color(.tertiarySystemFill))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct FilterBarView: View {
    @Binding var selectedStatuses: Set<ProgressStatus>
    @Binding var minimumRating: Double?
    @Binding var datePreset: DatePreset

    private let ratingOptions: [(String, Double?)] = [
        ("Todos", nil),
        ("2+", 2),
        ("3+", 3),
        ("4+", 4),
        ("4.5+", 4.5)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            filterSection(title: "Estado", icon: "circle.dashed") {
                FlowLayout(spacing: 6) {
                    FilterChip(
                        label: "Todos",
                        isSelected: selectedStatuses.isEmpty,
                        action: { withAnimation { selectedStatuses = [] } }
                    )
                    ForEach(ProgressStatus.allCases, id: \.self) { status in
                        FilterChip(
                            label: status.displayName,
                            isSelected: selectedStatuses.contains(status),
                            action: {
                                withAnimation {
                                    if selectedStatuses.contains(status) {
                                        selectedStatuses.remove(status)
                                    } else {
                                        selectedStatuses.insert(status)
                                    }
                                }
                            }
                        )
                    }
                }
            }

            filterSection(title: "Rating", icon: "star.fill") {
                FlowLayout(spacing: 6) {
                    ForEach(ratingOptions, id: \.0) { option in
                        FilterChip(
                            label: option.0,
                            isSelected: minimumRating == option.1,
                            action: { withAnimation { minimumRating = option.1 } }
                        )
                    }
                }
            }

            filterSection(title: "Fecha", icon: "calendar") {
                FlowLayout(spacing: 6) {
                    ForEach(DatePreset.allCases, id: \.self) { preset in
                        FilterChip(
                            label: preset.rawValue,
                            isSelected: datePreset == preset,
                            action: { withAnimation { datePreset = preset } }
                        )
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func filterSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
            content()
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalHeight = y + rowHeight
        }

        return (positions, CGSize(width: maxWidth, height: totalHeight))
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
