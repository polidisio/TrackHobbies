import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var showStoreError = DataStore.shared.startupError != nil
    @AppStorage(Analytics.promptedKey) private var analyticsPrompted = false

    var body: some View {
        TabView {
            NavigationStack {
                BooksListView()
                    .onAppear { Analytics.screen("books") }
            }
            .tabItem { Label("Libros", systemImage: "book.fill") }

            NavigationStack {
                SeriesListView()
                    .onAppear { Analytics.screen("series") }
            }
            .tabItem { Label("Series", systemImage: "tv.fill") }

            NavigationStack {
                GamesListView()
                    .onAppear { Analytics.screen("games") }
            }
            .tabItem { Label("Juegos", systemImage: "gamecontroller.fill") }

            NavigationStack {
                StatsView()
                    .onAppear { Analytics.screen("stats") }
            }
            .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
        }
        .tint(AppTheme.accent)
        .sheet(isPresented: Binding(get: { !analyticsPrompted }, set: { _ in })) {
            AnalyticsConsentView { accepted in
                Analytics.setEnabled(accepted)
                analyticsPrompted = true
            }
            .presentationDetents([.medium])
            .interactiveDismissDisabled()
        }
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
