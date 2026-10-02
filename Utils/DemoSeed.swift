#if DEBUG
import Foundation
import SwiftData

/// Solo Debug: rellena la app con datos de ejemplo para las capturas de App Store.
/// Uso: lanzar con `-SeedDemo /ruta/demo.json` (una copia de seguridad JSON de `Backup`).
/// Marca el consentimiento de analítica como respondido (desactivado) para que no tape la pantalla.
enum DemoSeed {
    @MainActor static func runIfRequested() {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: "-SeedDemo"), i + 1 < args.count else {
            NSLog("DemoSeed: sin -SeedDemo en %@", args.joined(separator: " "))
            return
        }
        UserDefaults.standard.set(true, forKey: Analytics.promptedKey)
        UserDefaults.standard.set(false, forKey: Analytics.consentKey)
        guard let data = FileManager.default.contents(atPath: args[i + 1]),
              let items = try? Backup.decode(data) else {
            NSLog("DemoSeed: no se pudo leer %@", args[i + 1])
            return
        }
        let added = CSVImporter.insert(items, context: DataStore.shared.modelContainer.mainContext, source: "demo")
        NSLog("DemoSeed: %d elementos añadidos", added)
    }
}
#endif
