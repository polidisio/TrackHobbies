import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Copia de seguridad completa en JSON: todos los campos de cada recurso (incluida la portada subida).
/// A diferencia del CSV conserva el `id`, así que reimportar sobre los mismos datos no duplica nada.
enum Backup {
    static let version = 1

    struct File: Codable {
        var version = Backup.version
        var exportedAt = Date()
        var items: [Item]
    }

    struct Item: Codable {
        var id: UUID
        var type, title, status: String
        var externalId, imageURL, summary, authorOrCreator, reviewComment: String?
        var userRating, timeSpentHours, progressPercentage: Double?
        var currentPage, totalPages, currentSeason, currentEpisode, totalSeasons, totalEpisodes: Int?
        var lastUpdated, startDate, endDate: Date?

        init(_ e: ResourceEntity) {
            id = e.id; type = e.type; title = e.title; status = e.status
            externalId = e.externalId; imageURL = e.imageURL; summary = e.summary
            authorOrCreator = e.authorOrCreator; reviewComment = e.reviewComment
            userRating = e.userRating; timeSpentHours = e.timeSpentHours; progressPercentage = e.progressPercentage
            currentPage = e.currentPage; totalPages = e.totalPages
            currentSeason = e.currentSeason; currentEpisode = e.currentEpisode
            totalSeasons = e.totalSeasons; totalEpisodes = e.totalEpisodes
            lastUpdated = e.lastUpdated; startDate = e.startDate; endDate = e.endDate
        }

        func entity() -> ResourceEntity {
            ResourceEntity(
                id: id, type: ResourceType(rawValue: type) ?? .book, title: title, externalId: externalId,
                imageURL: imageURL, summary: summary, authorOrCreator: authorOrCreator, userRating: userRating,
                status: ProgressStatus(rawValue: status) ?? .notStarted, timeSpentHours: timeSpentHours,
                lastUpdated: lastUpdated, currentPage: currentPage, totalPages: totalPages,
                progressPercentage: progressPercentage, currentSeason: currentSeason, currentEpisode: currentEpisode,
                totalSeasons: totalSeasons, totalEpisodes: totalEpisodes, startDate: startDate, endDate: endDate,
                reviewComment: reviewComment
            )
        }
    }

    enum Failure: LocalizedError {
        case unreadable, newerVersion
        var errorDescription: String? {
            switch self {
            case .unreadable: return String(localized: "El archivo no es una copia de seguridad de TrackHobbies.")
            case .newerVersion: return String(localized: "La copia es de una versión más nueva de TrackHobbies. Actualiza la app.")
            }
        }
    }

    static func encode(_ entities: [ResourceEntity]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(File(items: entities.map(Item.init)))
    }

    static func decode(_ data: Data) throws -> [ResourceEntity] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let file = try? decoder.decode(File.self, from: data) else { throw Failure.unreadable }
        guard file.version <= version else { throw Failure.newerVersion }
        return file.items.map { $0.entity() }
    }
}

struct BackupFile: Transferable {
    let data: Data
    let name: String

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .json) { file in
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(file.name)
            try file.data.write(to: url, options: .atomic)
            return SentTransferredFile(url)
        }
    }
}

/// Sección de Estadísticas: exportar e importar la copia de seguridad.
struct BackupView: View {
    let resources: [ResourceEntity]
    @Environment(\.modelContext) private var modelContext
    @State private var picking = false
    @State private var message: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Copia de seguridad").font(.headline)
            if let data = try? Backup.encode(resources) {
                ShareLink(
                    item: BackupFile(data: data, name: "trackhobbies_backup_\(Date.now.formatted(.iso8601.year().month().day())).json"),
                    preview: SharePreview("trackhobbies_backup.json")
                ) {
                    Label("Exportar copia (JSON)", systemImage: "square.and.arrow.up")
                }
                .disabled(resources.isEmpty)
                .simultaneousGesture(TapGesture().onEnded { Analytics.track("export_started", ["format": "json"]) })
            }
            Button { picking = true } label: {
                Label("Restaurar copia", systemImage: "square.and.arrow.down")
            }
            Text("Restaurar solo añade lo que falta: no borra ni sobrescribe nada.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fileImporter(isPresented: $picking, allowedContentTypes: [.json]) { result in
            message = restore(result)
        }
        .alert("Copia de seguridad", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(message ?? "")
        }
    }

    private func restore(_ result: Result<URL, Error>) -> String {
        guard case .success(let url) = result, url.startAccessingSecurityScopedResource() else {
            return String(localized: "No se pudo abrir el archivo.")
        }
        defer { url.stopAccessingSecurityScopedResource() }
        do {
            let items = try Backup.decode(Data(contentsOf: url))
            let added = CSVImporter.insert(items, context: modelContext, source: "backup")
            return CSVImporter.summary(added: added, total: items.count)
        } catch {
            return error.localizedDescription
        }
    }
}
