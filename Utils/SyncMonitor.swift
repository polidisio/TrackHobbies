import CloudKit
import CoreData
import Foundation
import os

/// Estado de la sincronización con CloudKit. SwiftData usa NSPersistentCloudKitContainer por debajo,
/// que publica un evento por cada setup/import/export con su resultado y error.
@MainActor
final class SyncMonitor: ObservableObject {
    static let shared = SyncMonitor()

    @Published private(set) var accountStatus: CKAccountStatus?
    @Published private(set) var lastEvent: (kind: String, date: Date)?
    @Published private(set) var lastError: String?
    /// Texto del primer error interno (solo en pantalla, nunca se envía a analytics).
    @Published private(set) var lastErrorDetail: String?

    private static let log = Logger(subsystem: "com.trackhobbies.app", category: "Sync")
    private var started = false

    func start() {
        guard !started else { return }
        started = true
        NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification, object: nil, queue: .main
        ) { [weak self] note in
            guard let event = note.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                    as? NSPersistentCloudKitContainer.Event, let end = event.endDate else { return }
            let kind = Self.name(event.type)
            let nsError = event.error as NSError?
            Task { @MainActor in self?.record(kind: kind, date: end, error: nsError) }
        }
        Task { await refreshAccount() }
    }

    func refreshAccount() async {
        accountStatus = try? await CKContainer(identifier: "iCloud.com.trackhobbies.app").accountStatus()
    }

    private func record(kind: String, date: Date, error: NSError?) {
        if let error {
            // partialFailure (CKError 2) solo dice "alguno falló": la causa va en los errores internos.
            let inner = (error.userInfo[CKPartialErrorsByItemIDKey] as? [AnyHashable: Error])?.values.map { $0 as NSError } ?? []
            let innerCodes = Array(Set(inner.map { "\($0.domain) \($0.code)" })).sorted()
            lastError = ([("\(error.domain) \(error.code)")] + (innerCodes.isEmpty ? [] : ["→ " + innerCodes.joined(separator: ", ")])).joined(separator: " ")
            // 22 (batchRequestFailed) solo dice "falló otro del lote": la causa está en el primero que no sea 22.
            let culprit = inner.first { $0.code != 22 } ?? inner.first ?? error
            let server = culprit.userInfo["ServerErrorDescription"] as? String
            lastErrorDetail = "\(culprit.domain) \(culprit.code): " + String((server ?? culprit.localizedDescription).prefix(300))
            Self.log.error("\(kind, privacy: .public) failed: \(self.lastError ?? "", privacy: .public)")
            // Solo dominio y códigos: nunca el texto del error ni datos del usuario.
            Analytics.track("sync_error", ["kind": kind, "domain": error.domain, "code": error.code, "inner_codes": innerCodes.joined(separator: ",")])
        } else {
            lastError = nil
            lastErrorDetail = nil
            lastEvent = (kind, date)
        }
    }

    private static func name(_ type: NSPersistentCloudKitContainer.EventType) -> String {
        switch type {
        case .setup: return "setup"
        case .import: return "import"
        case .export: return "export"
        @unknown default: return "other"
        }
    }
}
