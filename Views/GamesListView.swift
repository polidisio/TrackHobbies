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
                            Text("Pendientes (\(wishlistGames.count))")
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
                            Text("Sin empezar (\(notStartedGames.count))")
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
                            Text("En progreso (\(inProgressGames.count))")
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
                                            game.progressStatus = .archived
                                            game.lastUpdated = Date()
                                        } label: {
                                            Label("Archivar", systemImage: "archivebox")
                                        }
                                        .tint(.gray)
                                    }
                            }
                        } label: {
                            Text("Completados (\(completedGames.count))")
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
                            Text("Archivados (\(archivedGames.count))")
                                .foregroundColor(.secondary)
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
                modelContext.delete(game)
            } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "gamecontroller")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No hay juegos")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Toca + para añadir tu primer juego")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
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
            AsyncImage(url: URL(string: game.imageURL ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure, .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay {
                            Image(systemName: "gamecontroller")
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
                Text(game.title)
                    .font(.headline)
                    .lineLimit(2)

                if let time = game.timeSpentHours, time > 0 {
                    Text("\(Int(time))h jugadas")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 8) {
                    StatusBadge(status: game.progressStatus)

                    if let rating = game.userRating {
                        RatingView(rating: rating)
                    }

                    if game.reviewComment != nil && !(game.reviewComment ?? "").isEmpty {
                        Image(systemName: "text.quote")
                            .font(.caption)
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
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                TextField("Clave API RAWG (opcional)", text: $viewModel.apiKey)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                HStack {
                    TextField("Buscar por título...", text: $viewModel.searchQuery)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.search)
                        .onSubmit {
                            viewModel.searchGames()
                        }

                    Button {
                        viewModel.searchGames()
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .disabled(viewModel.searchQuery.isEmpty)
                }
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
                List(viewModel.searchResults, id: \.id) { item in
                    GameSearchResultRow(
                        title: item.title,
                        imageURL: item.imageURL,
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

struct GameSearchResultRow: View {
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
                            Image(systemName: "gamecontroller")
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
        GamesListView()
    }
    .modelContainer(DataStore.shared.modelContainer)
}
