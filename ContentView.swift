import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var showStoreError = DataStore.shared.startupError != nil

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

            NavigationStack {
                StatsView()
            }
            .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
        }
        .tint(AppTheme.accent)
        .alert("No se pudieron cargar tus datos", isPresented: $showStoreError) {
            Button("Entendido", role: .cancel) {}
        } message: {
            Text("La app funciona en modo temporal: lo que añadas no se guardará. Tus datos anteriores siguen en el dispositivo. Cierra la app y vuelve a abrirla; si persiste, actualiza la app.")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(DataStore.shared.modelContainer)
}
