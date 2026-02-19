import SwiftUI

// Minimal placeholder content view to bootstrap the UI structure.
struct ContentView: View {
    var body: some View {
        TabView {
            // Libros
            NavigationView {
                Text("Libros - mock").navigationTitle("Libros")
            }
            .tabItem { Label("Libros", systemImage: "book") }

            // Series
            NavigationView {
                Text("Series - mock").navigationTitle("Series")
            }
            .tabItem { Label("Series", systemImage: "tv") }

            // Juegos
            NavigationView {
                Text("Juegos - mock").navigationTitle("Juegos")
            }
            .tabItem { Label("Juegos", systemImage: "gamecontroller") }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
