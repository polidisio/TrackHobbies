import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct BooksListView: View {
    @StateObject private var viewModel = BooksViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var resourceToDelete: ResourceEntity?
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
    @State private var showingImportSheet = false
    @State private var showingFilePicker = false
    @State private var showingEnrichmentOption = false
    @State private var pendingImportBooks: [GoodreadsCSVBook] = []
    @State private var enrichWithGoogleBooks = true
    @State private var showingExportSheet = false
    @State private var csvExportData: String = ""

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
                                    Text("\(filteredBooks.count) resultados")
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
        .confirmDelete($resourceToDelete)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    Button {
                        showingFilePicker = true
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                            .accessibilityLabel("Importar CSV de Goodreads")
                    }

                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showingFilters.toggle()
                        }
                    } label: {
                        Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .foregroundStyle(hasActiveFilters ? AppTheme.accent : .secondary)
                            .accessibilityLabel("Filtros")
                            .accessibilityValue(hasActiveFilters ? "activos" : "")
                    }

                    Button {
                        csvExportData = CSVExporter.exportFromEntities(books)
                        showingExportSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .accessibilityLabel("Exportar CSV")
                    }
                    .disabled(books.isEmpty)

                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .accessibilityLabel("Añadir libro")
                    }
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                if !books.isEmpty {
                    Text("\(books.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Capsule())
                }
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .sheet(isPresented: $showingAddSheet) {
            BookSearchView(viewModel: viewModel, isPresented: $showingAddSheet)
        }
        .sheet(isPresented: $showingEnrichmentOption) {
            NavigationStack {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Image(systemName: "books.vertical")
                            .font(.system(size: 48))
                            .foregroundStyle(AppTheme.bookColor)

                        Text("Importar \(pendingImportBooks.count) libros")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("¿Deseas enriquecer los datos con portadas y descripciones de Google Books?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    VStack(spacing: 12) {
                        Toggle(isOn: $enrichWithGoogleBooks) {
                            HStack {
                                Image(systemName: "photo.artframe")
                                    .foregroundStyle(.blue)
                                Text("Buscar portadas y descripciones")
                            }
                        }
                        .tint(AppTheme.accent)

                        if enrichWithGoogleBooks {
                            Text("Se usará el ISBN para buscar información adicional")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                    if viewModel.isImporting {
                        VStack(spacing: 8) {
                            ProgressView(value: viewModel.importProgress)
                            Text("Importando...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }

                    Spacer()
                }
                .padding()
                .navigationTitle("Importar desde Goodreads")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancelar") {
                            pendingImportBooks = []
                            showingEnrichmentOption = false
                        }
                        .disabled(viewModel.isImporting)
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button("Importar") {
                            confirmImport()
                            showingEnrichmentOption = false
                        }
                        .disabled(viewModel.isImporting)
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportCSVView(csvData: csvExportData)
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            if url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }
                do {
                    let csvContent = try String(contentsOf: url, encoding: .utf8)
                    let books = GoodreadsImporter.parse(csvContent: csvContent)
                    pendingImportBooks = books
                    showingEnrichmentOption = true
                } catch {
                    print("Error reading file: \(error)")
                }
            }
        case .failure(let error):
            print("Error selecting file: \(error)")
        }
    }

    private func confirmImport() {
        viewModel.importBooks(pendingImportBooks, context: modelContext, enrichWithGoogleBooks: enrichWithGoogleBooks)
        pendingImportBooks = []
    }

    private func bookRow(_ book: ResourceEntity) -> some View {
        NavigationLink(destination: ResourceDetailView(resource: book)) {
            BookRowView(book: book)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                resourceToDelete = book
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

            .accessibilityHidden(true)

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
                            .accessibilityLabel("Tiene reseña")
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
        .accessibilityElement(children: .combine)
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
            .task(id: viewModel.searchQuery) { await viewModel.searchBooks() }
            .onDisappear { viewModel.clearSearch() }
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
                }
                .padding(10)
                .background(Color(.tertiarySystemFill))
                .cornerRadius(10)
            }
            .padding()

            if viewModel.isLoading {
                Spacer()
                ProgressView("Buscando...")
                Spacer()
            } else if let message = viewModel.errorMessage {
                SearchErrorView(message: message) { Task { await viewModel.searchBooks() } }
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

enum DatePreset: CaseIterable {
    case all, thisWeek, thisMonth, thisYear, olderThanYear

    var label: String {
        switch self {
        case .all: return String(localized: "Todos")
        case .thisWeek: return String(localized: "Esta semana")
        case .thisMonth: return String(localized: "Este mes")
        case .thisYear: return String(localized: "Este año")
        case .olderThanYear: return String(localized: "Hace 1+ año")
        }
    }

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
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct FilterBarView: View {
    @Binding var selectedStatuses: Set<ProgressStatus>
    @Binding var minimumRating: Double?
    @Binding var datePreset: DatePreset

    private let ratingOptions: [(String, Double?)] = [
        (String(localized: "Todos"), nil),
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
                        label: String(localized: "Todos"),
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
                            label: preset.label,
                            isSelected: datePreset == preset,
                            action: { withAnimation { datePreset = preset } }
                        )
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func filterSection<Content: View>(title: LocalizedStringKey, icon: String, @ViewBuilder content: () -> Content) -> some View {
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
                .accessibilityHidden(true)

            Text(status.sectionTitle)
                .font(.subheadline)
                .fontWeight(.semibold)

            Spacer()

            Text("\(count)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
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
        .accessibilityHidden(true)
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Nota \(rating.formatted(.number.precision(.fractionLength(0...2)))) de 5")
    }
}

struct ProgressRow: View {
    let text: LocalizedStringKey
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progreso")
        .accessibilityValue(text)
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
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Guardar «\(title)» en pendientes")

            Button {
                onAdd()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.green)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Añadir «\(title)»")
        }
        .padding(.vertical, 4)
    }
}

@ViewBuilder
func dateLabel(start: Date?, end: Date?) -> some View {
    if let s = start, let e = end {
        Text("\(s.formatted(date: .abbreviated, time: .omitted)) - \(e.formatted(date: .abbreviated, time: .omitted))")
            .font(.caption2)
            .foregroundColor(.secondary)
    } else if let s = start {
        Text("Desde \(s.formatted(date: .abbreviated, time: .omitted))")
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
