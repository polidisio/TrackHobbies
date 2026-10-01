import Foundation
import SwiftData
import os

/// V1 = baseline del primer release, congelado: NO editar estos modelos.
/// V2 = modelos actuales (`Models/PersistenceModels.swift`), compatibles con CloudKit
/// (sin `.unique`, con valores por defecto y relaciones con inverso).
/// Antes de volver a cambiar `ResourceEntity` o `PendingItemEntity`: congelar V2 aquí dentro,
/// crear `SchemaV3` y añadir un `MigrationStage` en `TrackHobbiesMigrationPlan.stages`.
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [ResourceEntity.self, PendingItemEntity.self] }

    @Model
    final class ResourceEntity {
        @Attribute(.unique) var id: UUID
        var type: String
        var title: String
        var externalId: String?
        var imageURL: String?
        var summary: String?
        var authorOrCreator: String?
        var userRating: Double?
        var status: String
        var timeSpentHours: Double?
        var lastUpdated: Date?
        var currentPage: Int?
        var totalPages: Int?
        var progressPercentage: Double?
        var currentSeason: Int?
        var currentEpisode: Int?
        var totalSeasons: Int?
        var totalEpisodes: Int?
        var startDate: Date?
        var endDate: Date?
        var reviewComment: String?
        @Relationship(deleteRule: .cascade) var pendings: [PendingItemEntity]?

        init(
            id: UUID = UUID(),
            type: ResourceType,
            title: String,
            externalId: String? = nil,
            imageURL: String? = nil,
            summary: String? = nil,
            authorOrCreator: String? = nil,
            userRating: Double? = nil,
            status: ProgressStatus = .notStarted,
            timeSpentHours: Double? = nil,
            lastUpdated: Date? = nil,
            currentPage: Int? = nil,
            totalPages: Int? = nil,
            progressPercentage: Double? = nil,
            currentSeason: Int? = nil,
            currentEpisode: Int? = nil,
            totalSeasons: Int? = nil,
            totalEpisodes: Int? = nil,
            startDate: Date? = nil,
            endDate: Date? = nil,
            reviewComment: String? = nil
        ) {
            self.id = id
            self.type = type.rawValue
            self.title = title
            self.externalId = externalId
            self.imageURL = imageURL
            self.summary = summary
            self.authorOrCreator = authorOrCreator
            self.userRating = userRating
            self.status = status.rawValue
            self.timeSpentHours = timeSpentHours
            self.lastUpdated = lastUpdated
            self.currentPage = currentPage
            self.totalPages = totalPages
            self.progressPercentage = progressPercentage
            self.currentSeason = currentSeason
            self.currentEpisode = currentEpisode
            self.totalSeasons = totalSeasons
            self.totalEpisodes = totalEpisodes
            self.startDate = startDate
            self.endDate = endDate
            self.reviewComment = reviewComment
        }

        var resourceType: ResourceType {
            get { ResourceType(rawValue: type) ?? .book }
            set { type = newValue.rawValue }
        }

        var progressStatus: ProgressStatus {
            get { ProgressStatus(rawValue: status) ?? .notStarted }
            set { status = newValue.rawValue }
        }
    }

    @Model
    final class PendingItemEntity {
        @Attribute(.unique) var id: UUID
        var resourceId: UUID
        var title: String
        var dueDate: Date?
        var completed: Bool

        init(
            id: UUID = UUID(),
            resourceId: UUID,
            title: String,
            dueDate: Date? = nil,
            completed: Bool = false
        ) {
            self.id = id
            self.resourceId = resourceId
            self.title = title
            self.dueDate = dueDate
            self.completed = completed
        }
    }
}

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 1, 0)
    static var models: [any PersistentModel.Type] { [ResourceEntity.self, PendingItemEntity.self] }
}

enum TrackHobbiesMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self, SchemaV2.self] }
    static var stages: [MigrationStage] {
        [.lightweight(fromVersion: SchemaV1.self, toVersion: SchemaV2.self)]
    }
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
        let schema = Schema(versionedSchema: SchemaV2.self)
        let url = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TrackHobbies.sqlite")

        do {
            let config = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .private("iCloud.com.trackhobbies.app"))
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
