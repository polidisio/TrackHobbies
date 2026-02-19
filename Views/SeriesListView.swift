import SwiftUI
import SwiftData

struct SeriesListView: View {
    @StateObject private var viewModel = SeriesViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddSheet = false
    
    var body: some View {
        List {
            if viewModel.series.isEmpty {
                emptyStateView
            } else {
                ForEach(viewModel.series) { serie in
                    SeriesRowView(serie: serie)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                viewModel.deleteSeries(serie)
                            } label: {
                                Label("Eliminar", systemImage: "trash")
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
        .onAppear {
            viewModel.setModelContext(modelContext)
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
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct SeriesSearchView: View {
    @ObservedObject var viewModel: SeriesViewModel
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
                            viewModel.addSeries(title: manualTitle)
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
                        imageURL: item.imageURL
                    ) {
                        viewModel.addSeries(from: item)
                        isPresented = false
                    }
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
    .modelContainer(for: ResourceEntity.self, inMemory: true)
}
