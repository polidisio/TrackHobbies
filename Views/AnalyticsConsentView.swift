import SwiftUI

struct AnalyticsConsentView: View {
    let onChoice: (Bool) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.accent)
                .accessibilityHidden(true)
            Text("Ayuda a mejorar TrackHobbies").font(.title2.bold())
            Text("Comparte datos de uso anónimos (qué funciones usas). Nunca enviamos tus títulos, notas, reseñas ni puntuaciones. Puedes cambiarlo cuando quieras en Estadísticas.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button { onChoice(true) } label: {
                Text("Compartir uso anónimo").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            Button { onChoice(false) } label: {
                Text("Ahora no").frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding(24)
    }
}
