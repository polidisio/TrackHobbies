import SwiftUI
import SwiftData

struct BooksListView: View {
    @StateObject private var viewModel = BooksViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddSheet = false
    
    var body: some View {
        List {
            if viewModel.books.isEmpty {
                emptyStateView
            } else {
                ForEach(viewModel.books) { book in
                    BookRowView(book: book)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                viewModel.deleteBook(book)
                            } label: {
                                Label("Eliminar", systemImage: "trash")
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
            BookSearchView(viewModel: viewModel, modelContext: modelContext, isPresented: $showingAddSheet)
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
            }
            
            Spacer()
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
        case .notStarted: return Color.gray.opacity(0.2)
        case .inProgress: return Color.blue.opacity(0.2)
        case .completed: return Color.green.opacity(0.2)
        }
    }
    
    private var foregroundColor: Color {
        switch status {
        case .notStarted: return .gray
        case .inProgress: return .blue
        case .completed: return .green
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

#Preview {
    NavigationStack {
        BooksListView()
    }
    .modelContainer(for: ResourceEntity.self, inMemory: true)
}
