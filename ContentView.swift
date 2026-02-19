import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                BooksListView()
            }
            .tabItem { Label("Libros", systemImage: "book") }
            
            NavigationStack {
                SeriesListView()
            }
            .tabItem { Label("Series", systemImage: "tv") }
            
            NavigationStack {
                GamesListView()
            }
            .tabItem { Label("Juegos", systemImage: "gamecontroller") }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(DataStore.shared.modelContainer)
}
