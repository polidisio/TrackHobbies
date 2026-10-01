import Foundation
import SwiftData
import os

/// V1 = baseline del primer release. Antes de cambiar `ResourceEntity` o `PendingItemEntity`:
/// congelar sus modelos actuales dentro de un enum `SchemaV1` anidado, crear `SchemaV2`
/// y añadir un `MigrationStage` en `TrackHobbiesMigrationPlan.stages`.
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [ResourceEntity.self, PendingItemEntity.self] }
}

enum TrackHobbiesMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}

@MainActor
final class DataStore {
    static let shared = DataStore()

    let modelContainer: ModelContainer
    /// Non-nil si no se pudo abrir la base de datos en disco. En ese caso la app corre en memoria
    /// (nada se guarda) y la UI debe avisarlo. El fichero en disco no se toca.
    let startupError: Error?

    private static let log = Logger(subsystem: "com.trackhobbies.app", category: "DataStore")

    private init() {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let url = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TrackHobbies.sqlite")

        do {
            let config = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
            modelContainer = try ModelContainer(
                for: schema,
                migrationPlan: TrackHobbiesMigrationPlan.self,
                configurations: [config]
            )
            startupError = nil
        } catch {
            Self.log.error("Could not open store at \(url.path, privacy: .public): \(error, privacy: .public)")
            startupError = error
            do {
                let memory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                modelContainer = try ModelContainer(for: schema, configurations: [memory])
            } catch {
                // ponytail: un contenedor en memoria no falla en la práctica; si falla no hay nada que salvar.
                fatalError("DataStore: in-memory fallback failed – \(error)")
            }
        }
    }
}
