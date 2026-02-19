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
                            SectionHeader(status: .wishlist, count: wishlistSeries.count)
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
                            SectionHeader(status: .notStarted, count: notStartedSeries.count)
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
                            SectionHeader(status: .inProgress, count: inProgressSeries.count)
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
                                            withAnimation {
                                                serie.progressStatus = .archived
                                                serie.lastUpdated = Date()
                                            }
                                        } label: {
                                            Label("Archivar", systemImage: "archivebox")
                                        }
                                        .tint(ProgressStatus.archived.color)
                                    }
                            }
                        } label: {
                            SectionHeader(status: .completed, count: completedSeries.count)
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
                            SectionHeader(status: .archived, count: archivedSeries.count)
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
                withAnimation {
                    modelContext.delete(serie)
                }
            } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tv.fill")
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.seriesColor.opacity(0.4))

            VStack(spacing: 6) {
                Text("No hay series")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("Toca + para añadir tu primera serie")
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

struct SeriesRowView: View {
    let serie: ResourceEntity

    var body: some View {
        HStack(spacing: 12) {
            ResourceThumbnail(url: serie.imageURL, icon: "tv.fill", color: AppTheme.seriesColor)

            VStack(alignment: .leading, spacing: 5) {
                Text(serie.title)
                    .font(.headline)
                    .lineLimit(2)

                if let summary = serie.summary, !summary.isEmpty {
                    Text(summary.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 6) {
                    StatusBadge(status: serie.progressStatus)

                    if let rating = serie.userRating {
                        RatingView(rating: rating)
                    }

                    if serie.reviewComment != nil && !(serie.reviewComment ?? "").isEmpty {
                        Image(systemName: "text.quote")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                if serie.progressStatus == .inProgress {
                    if let season = serie.currentSeason, let episode = serie.currentEpisode {
                        let seasonText = serie.totalSeasons != nil ? "T\(season)/\(serie.totalSeasons!)" : "T\(season)"
                        let episodeText = "E\(episode)"
                        Text("\(seasonText) \(episodeText)")
                            .font(.caption)
                            .foregroundColor(AppTheme.accent)
                    } else if let season = serie.currentSeason {
                        let seasonText = serie.totalSeasons != nil ? "T\(season)/\(serie.totalSeasons!)" : "T\(season)"
                        Text(seasonText)
                            .font(.caption)
                            .foregroundColor(AppTheme.accent)
                    }
                }

                dateLabel(start: serie.startDate, end: serie.endDate)
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
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Buscar por título...", text: $viewModel.searchQuery)
                        .submitLabel(.search)
                        .onSubmit {
                            viewModel.searchSeries()
                        }
                }
                .padding(10)
                .background(Color(.tertiarySystemFill))
                .cornerRadius(10)

                if !viewModel.searchQuery.isEmpty {
                    Button("Buscar") {
                        viewModel.searchSeries()
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
                List(viewModel.searchResults, id: \.title) { item in
                    SearchResultRow(
                        title: item.title,
                        subtitle: "",
                        imageURL: item.imageURL,
                        icon: "tv.fill",
                        color: AppTheme.seriesColor,
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

#Preview {
    NavigationStack {
        SeriesListView()
    }
    .modelContainer(DataStore.shared.modelContainer)
}
