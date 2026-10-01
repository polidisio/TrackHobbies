import CloudKit
import SwiftUI

/// Diagnóstico de iCloud en Estadísticas: cuenta, última sincronización y último error.
struct SyncStatusView: View {
    @ObservedObject private var monitor = SyncMonitor.shared

    private var accountText: String {
        switch monitor.accountStatus {
        case .available: return String(localized: "iCloud activo")
        case .noAccount: return String(localized: "Sin cuenta de iCloud")
        case .restricted: return String(localized: "iCloud restringido")
        case .temporarilyUnavailable: return String(localized: "iCloud no disponible ahora")
        case .couldNotDetermine: return String(localized: "No se pudo comprobar iCloud")
        case nil: return String(localized: "Comprobando iCloud…")
        @unknown default: return String(localized: "Estado de iCloud desconocido")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(accountText, systemImage: monitor.accountStatus == .available ? "icloud" : "icloud.slash")
            if let last = monitor.lastEvent {
                Text("Última sincronización: \(last.date.formatted(date: .omitted, time: .shortened)) (\(last.kind))")
            } else {
                Text("Sin sincronizaciones todavía")
            }
            if let error = monitor.lastError {
                Text("Error de iCloud: \(error)").foregroundStyle(.red)
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .task { await monitor.refreshAccount() }
    }
}
