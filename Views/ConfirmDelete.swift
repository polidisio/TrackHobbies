import SwiftUI
import SwiftData

extension View {
    /// Muestra un diálogo de confirmación cuando `item` no es nil; borra solo si el usuario acepta.
    func confirmDelete(_ item: Binding<ResourceEntity?>) -> some View {
        modifier(ConfirmDeleteModifier(item: item))
    }
}

private struct ConfirmDeleteModifier: ViewModifier {
    @Environment(\.modelContext) private var modelContext
    @Binding var item: ResourceEntity?

    func body(content: Content) -> some View {
        content.confirmationDialog(
            "¿Eliminar «\(item?.title ?? "")»?",
            isPresented: Binding(get: { item != nil }, set: { if !$0 { item = nil } }),
            titleVisibility: .visible,
            presenting: item
        ) { resource in
            Button("Eliminar", role: .destructive) {
                withAnimation { modelContext.delete(resource) }
            }
        } message: { _ in
            Text("Se perderán su progreso, nota y comentario. No se puede deshacer.")
        }
    }
}
