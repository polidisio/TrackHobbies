import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                BooksListView()
            }
            .tabItem { Label("Libros", systemImage: "book.fill") }

            NavigationStack {
                SeriesListView()
            }
            .tabItem { Label("Series", systemImage: "tv.fill") }

            NavigationStack {
                GamesListView()
            }
            .tabItem { Label("Juegos", systemImage: "gamecontroller.fill") }
        }
        .tint(AppTheme.accent)
    }
}

#Preview {
    ContentView()
        .modelContainer(DataStore.shared.modelContainer)
}
