import SwiftUI
import UniformTypeIdentifiers

/// CSV de recursos (libros, series, juegos). Campos vacíos = sin dato (nunca `0`).
enum CSVExporter {
    static let header = "type,title,author_or_creator,external_id,rating,status,pages,current_page,season,episode,total_seasons,total_episodes,hours,start_date,end_date,review,image_url,summary"

    static func export(_ entities: [ResourceEntity]) -> String {
        let day = Date.ISO8601FormatStyle().year().month().day()
        let rows = entities.map { e -> String in
            [
                e.resourceType.rawValue, e.title, e.authorOrCreator, e.externalId,
                e.userRating.map { "\($0)" },
                e.progressStatus.rawValue, // estable: no depende del idioma de la UI
                e.totalPages.map(String.init), e.currentPage.map(String.init),
                e.currentSeason.map(String.init), e.currentEpisode.map(String.init),
                e.totalSeasons.map(String.init), e.totalEpisodes.map(String.init),
                e.timeSpentHours.map { "\($0)" },
                e.startDate?.formatted(day), e.endDate?.formatted(day),
                e.reviewComment, e.imageURL, e.summary,
            ].map(field).joined(separator: ",")
        }
        return ([header] + rows).joined(separator: "\n")
    }

    /// RFC 4180: siempre entre comillas, `"` duplicada; los saltos de línea quedan dentro del campo.
    static func field(_ value: String?) -> String {
        "\"" + (value ?? "").replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}

struct CSVFile: Transferable {
    let name: String
    let content: String

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .commaSeparatedText) { file in
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(file.name)
            try file.content.write(to: url, atomically: true, encoding: .utf8)
            return SentTransferredFile(url)
        }
    }
}

/// Botón de la barra: comparte el CSV directamente (sin hoja intermedia).
struct ExportCSVButton: View {
    let type: ResourceType
    let items: [ResourceEntity]

    var body: some View {
        ShareLink(
            item: CSVFile(name: "trackhobbies_\(type.rawValue).csv", content: CSVExporter.export(items)),
            preview: SharePreview("trackhobbies_\(type.rawValue).csv")
        ) {
            Image(systemName: "square.and.arrow.up")
                .accessibilityLabel("Exportar CSV")
        }
        .disabled(items.isEmpty)
        .simultaneousGesture(TapGesture().onEnded { Analytics.track("export_started", ["format": "csv"]) })
    }
}
