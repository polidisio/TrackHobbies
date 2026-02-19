import SwiftUI
import SwiftData

struct SeriesListView: View {
    @StateObject private var viewModel = SeriesViewModel()
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<ResourceEntity> { $0.type == "series" }, sort: \.lastUpdated, order: .reverse) private var series: [ResourceEntity]
    @State private var showingAddSheet = false
    @State private var wishlistExpanded = true
    @State private var notStartedExpanded = true
    @State private var inProgressExpanded = true
    @State private var completedExpanded = true
    @State private var archivedExpanded = false

    private var wishlistSeries: [ResourceEntity] { series.filter { $0.progressStatus == .wishlist } }
    private var notStartedSeries: [ResourceEntity] { series.filter { $0.progressStatus == .notStarted } }
    private var inProgressSeries: [ResourceEntity] { series.filter { $0.progressStatus == .inProgress } }
    private var completedSeries: [ResourceEntity] { series.filter { $0.progressStatus == .completed } }
    private var archivedSeries: [ResourceEntity] { series.filter { $0.progressStatus == .archived } }

    var body: some View {
        List {
            if series.isEmpty {
                emptyStateView
            } else {
                if !wishlistSeries.isEmpty {
                    Section {
                        DisclosureGroup(isExpanded: $wishlistExpanded) {
                            ForEach(wishlistSeries) { serie in
                                seriesRow(serie)
                            }
                        } label: {
                            Text("Pendientes (\(wishlistSeries.count))")
                        }
                    }
                }

                if !notStartedSeries.isEmpty {
                    Section {
                        DisclosureGroup(isExpanded: $notStartedExpanded) {
                            ForEach(notStartedSeries) { serie in
                                seriesRow(serie)
                            }
                        } label: {
                            Text("Sin empezar (\(notStartedSeries.count))")
                        }
                    }
                }

                if !inProgressSeries.isEmpty {
                    Section {
                        DisclosureGroup(isExpanded: $inProgressExpanded) {
                            ForEach(inProgressSeries) { serie in
                                seriesRow(serie)
                            }
                        } label: {
                            Text("En progreso (\(inProgressSeries.count))")
                        }
                    }
                }

                if !completedSeries.isEmpty {
                    Section {
                        DisclosureGroup(isExpanded: $completedExpanded) {
                            ForEach(completedSeries) { serie in
                                seriesRow(serie)
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            serie.progressStatus = .archived
                                            serie.lastUpdated = Date()
                                        } label: {
                                            Label("Archivar", systemImage: "archivebox")
                                        }
                                        .tint(.gray)
                                    }
                            }
                        } label: {
                            Text("Completados (\(completedSeries.count))")
                        }
                    }
                }

                if !archivedSeries.isEmpty {
                    Section {
                        DisclosureGroup(isExpanded: $archivedExpanded) {
                            ForEach(archivedSeries) { serie in
                                seriesRow(serie)
                            }
                        } label: {
                            Text("Archivados (\(archivedSeries.count))")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Series")
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
            SeriesSearchView(viewModel: viewModel, isPresented: $showingAddSheet)
        }
    }

    private func seriesRow(_ serie: ResourceEntity) -> some View {
        NavigationLink(destination: ResourceDetailView(resource: serie)) {
            SeriesRowView(serie: serie)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                modelContext.delete(serie)
            } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tv")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No hay series")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Toca + para añadir tu primera serie")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .listRowBackground(Color.clear)
    }
}

struct SeriesRowView: View {
    let serie: ResourceEntity

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: serie.imageURL ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure, .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay {
                            Image(systemName: "tv")
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
                Text(serie.title)
                    .font(.headline)
                    .lineLimit(2)

                if let summary = serie.summary, !summary.isEmpty {
                    Text(summary.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    StatusBadge(status: serie.progressStatus)

                    if let rating = serie.userRating {
                        RatingView(rating: rating)
                    }
                }

                if serie.progressStatus == .inProgress {
                    if let season = serie.currentSeason, let episode = serie.currentEpisode {
                        let seasonText = serie.totalSeasons != nil ? "T\(season)/\(serie.totalSeasons!)" : "T\(season)"
                        let episodeText = "E\(episode)"
                        Text("\(seasonText) \(episodeText)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    } else if let season = serie.currentSeason {
                        let seasonText = serie.totalSeasons != nil ? "T\(season)/\(serie.totalSeasons!)" : "T\(season)"
                        Text(seasonText)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct SeriesSearchView: View {
    @ObservedObject var viewModel: SeriesViewModel
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    @State private var manualTitle = ""
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
            .navigationTitle("Añadir Serie")
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
                            viewModel.addSeries(title: manualTitle, context: modelContext)
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
                        viewModel.searchSeries()
                    }

                Button {
                    viewModel.searchSeries()
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
                List(viewModel.searchResults, id: \.title) { item in
                    SeriesSearchResultRow(
                        title: item.title,
                        imageURL: item.imageURL,
                        onAdd: {
                            viewModel.addSeries(from: item, context: modelContext)
                            isPresented = false
                        },
                        onWishlist: {
                            viewModel.addSeriesToWishlist(from: item, context: modelContext)
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
            Section("Información de la serie") {
                TextField("Título", text: $manualTitle)
            }
        }
    }
}

struct SeriesSearchResultRow: View {
    let title: String
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
                            Image(systemName: "tv")
                                .foregroundColor(.secondary)
                        }
                @unknown default:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
            }
            .frame(width: 48, height: 64)
            .cornerRadius(6)

            Text(title)
                .font(.headline)
                .lineLimit(2)

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

#Preview {
    NavigationStack {
        SeriesListView()
    }
    .modelContainer(DataStore.shared.modelContainer)
}
