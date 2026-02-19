import SwiftUI
import SwiftData

struct GamesListView: View {
    @StateObject private var viewModel = GamesViewModel()
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<ResourceEntity> { $0.type == "game" }, sort: \.lastUpdated, order: .reverse) private var games: [ResourceEntity]
    @State private var showingAddSheet = false
    @State private var wishlistExpanded = true
    @State private var notStartedExpanded = true
    @State private var inProgressExpanded = true
    @State private var completedExpanded = true
    @State private var archivedExpanded = false

    private var wishlistGames: [ResourceEntity] { games.filter { $0.progressStatus == .wishlist } }
    private var notStartedGames: [ResourceEntity] { games.filter { $0.progressStatus == .notStarted } }
    private var inProgressGames: [ResourceEntity] { games.filter { $0.progressStatus == .inProgress } }
    private var completedGames: [ResourceEntity] { games.filter { $0.progressStatus == .completed } }
    private var archivedGames: [ResourceEntity] { games.filter { $0.progressStatus == .archived } }

    var body: some View {
        List {
            if games.isEmpty {
                emptyStateView
            } else {
                if !wishlistGames.isEmpty {
                    Section {
                        DisclosureGroup(isExpanded: $wishlistExpanded) {
                            ForEach(wishlistGames) { game in
                                gameRow(game)
                            }
                        } label: {
                            SectionHeader(status: .wishlist, count: wishlistGames.count)
                        }
                    }
                }

                if !notStartedGames.isEmpty {
                    Section {
                        DisclosureGroup(isExpanded: $notStartedExpanded) {
                            ForEach(notStartedGames) { game in
                                gameRow(game)
                            }
                        } label: {
                            SectionHeader(status: .notStarted, count: notStartedGames.count)
                        }
                    }
                }

                if !inProgressGames.isEmpty {
                    Section {
                        DisclosureGroup(isExpanded: $inProgressExpanded) {
                            ForEach(inProgressGames) { game in
                                gameRow(game)
                            }
                        } label: {
                            SectionHeader(status: .inProgress, count: inProgressGames.count)
                        }
                    }
                }

                if !completedGames.isEmpty {
                    Section {
                        DisclosureGroup(isExpanded: $completedExpanded) {
                            ForEach(completedGames) { game in
                                gameRow(game)
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            withAnimation {
                                                game.progressStatus = .archived
                                                game.lastUpdated = Date()
                                            }
                                        } label: {
                                            Label("Archivar", systemImage: "archivebox")
                                        }
                                        .tint(ProgressStatus.archived.color)
                                    }
                            }
                        } label: {
                            SectionHeader(status: .completed, count: completedGames.count)
                        }
                    }
                }

                if !archivedGames.isEmpty {
                    Section {
                        DisclosureGroup(isExpanded: $archivedExpanded) {
                            ForEach(archivedGames) { game in
                                gameRow(game)
                            }
                        } label: {
                            SectionHeader(status: .archived, count: archivedGames.count)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Juegos")
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
            GameSearchView(viewModel: viewModel, isPresented: $showingAddSheet)
        }
    }

    private func gameRow(_ game: ResourceEntity) -> some View {
        NavigationLink(destination: ResourceDetailView(resource: game)) {
            GameRowView(game: game)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                withAnimation {
                    modelContext.delete(game)
                }
            } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.gameColor.opacity(0.4))

            VStack(spacing: 6) {
                Text("No hay juegos")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("Toca + para añadir tu primer juego")
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

struct GameRowView: View {
    let game: ResourceEntity

    var body: some View {
        HStack(spacing: 12) {
            ResourceThumbnail(url: game.imageURL, icon: "gamecontroller.fill", color: AppTheme.gameColor)

            VStack(alignment: .leading, spacing: 5) {
                Text(game.title)
                    .font(.headline)
                    .lineLimit(2)

                if let time = game.timeSpentHours, time > 0 {
                    Text("\(Int(time))h jugadas")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 6) {
                    StatusBadge(status: game.progressStatus)

                    if let rating = game.userRating {
                        RatingView(rating: rating)
                    }

                    if game.reviewComment != nil && !(game.reviewComment ?? "").isEmpty {
                        Image(systemName: "text.quote")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                dateLabel(start: game.startDate, end: game.endDate)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct GameSearchView: View {
    @ObservedObject var viewModel: GamesViewModel
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
            .navigationTitle("Añadir Juego")
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
                            viewModel.addGame(title: manualTitle, context: modelContext)
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
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "key.fill")
                        .foregroundColor(.secondary)
                    TextField("Clave API RAWG (opcional)", text: $viewModel.apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                .padding(10)
                .background(Color(.tertiarySystemFill))
                .cornerRadius(10)

                HStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Buscar por título...", text: $viewModel.searchQuery)
                            .submitLabel(.search)
                            .onSubmit {
                                viewModel.searchGames()
                            }
                    }
                    .padding(10)
                    .background(Color(.tertiarySystemFill))
                    .cornerRadius(10)

                    if !viewModel.searchQuery.isEmpty {
                        Button("Buscar") {
                            viewModel.searchGames()
                        }
                        .fontWeight(.medium)
                    }
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
                List(viewModel.searchResults, id: \.id) { item in
                    SearchResultRow(
                        title: item.title,
                        subtitle: "",
                        imageURL: item.imageURL,
                        icon: "gamecontroller.fill",
                        color: AppTheme.gameColor,
                        onAdd: {
                            viewModel.addGame(from: item, context: modelContext)
                            isPresented = false
                        },
                        onWishlist: {
                            viewModel.addGameToWishlist(from: item, context: modelContext)
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
            Section("Información del juego") {
                TextField("Título", text: $manualTitle)
            }
        }
    }
}

#Preview {
    NavigationStack {
        GamesListView()
    }
    .modelContainer(DataStore.shared.modelContainer)
}
