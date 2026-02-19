import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var booksViewModel = BooksViewModel()
    @StateObject private var seriesViewModel = SeriesViewModel()
    @StateObject private var gamesViewModel = GamesViewModel()
    
    var body: some View {
        TabView {
            NavigationStack {
                BooksListView(viewModel: booksViewModel)
            }
            .tabItem { Label("Libros", systemImage: "book") }
            
            NavigationStack {
                SeriesListView(viewModel: seriesViewModel)
            }
            .tabItem { Label("Series", systemImage: "tv") }
            
            NavigationStack {
                GamesListView(viewModel: gamesViewModel)
            }
            .tabItem { Label("Juegos", systemImage: "gamecontroller") }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ResourceEntity.self, inMemory: true)
}
