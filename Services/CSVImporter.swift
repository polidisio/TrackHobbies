import Foundation
import SwiftData
import SwiftUI

/// Lee el CSV propio de `CSVExporter` (backup/restore de libros, series y juegos).
enum CSVImporter {
    static func isOwnFormat(_ content: String) -> Bool {
        content.hasPrefix("type,title,") || content.hasPrefix("\u{FEFF}type,title,")
    }

    /// Solo añade: omite lo que ya existe (mismo tipo + título + id externo). Devuelve cuántos añadió.
    @discardableResult
    static func insert(_ items: [ResourceEntity], context: ModelContext, source: String = "trackhobbies") -> Int {
        let existing = (try? context.fetch(FetchDescriptor<ResourceEntity>())) ?? []
        var seen = Set(existing.map { "\($0.type)|\($0.title)|\($0.externalId ?? "")" })
        let ids = Set(existing.map(\.id))
        var added = 0
        for item in items where !ids.contains(item.id) && seen.insert("\(item.type)|\(item.title)|\(item.externalId ?? "")").inserted {
            context.insert(item)
            added += 1
        }
        do { try context.save() } catch { print("Error saving imported items: \(error)") }
        Analytics.track("import_done", ["source": source, "count": added])
        return added
    }

    static func summary(added: Int, total: Int) -> String {
        String(localized: "Añadidos: \(added). Omitidos (ya existían): \(total - added).")
    }

    static let nothingFound = String(localized: "No se encontraron elementos en el archivo. ¿Es un CSV de TrackHobbies o de Goodreads?")
    static let unreadable = String(localized: "No se pudo leer el archivo.")

    /// UTF-8 y, si no, Latin-1 (algunos exports antiguos).
    static func readText(_ url: URL) -> String? {
        (try? String(contentsOf: url, encoding: .utf8)) ?? (try? String(contentsOf: url, encoding: .isoLatin1))
    }

    static func parse(_ content: String) -> [ResourceEntity] {
        let rows = parseRows(content)
        guard let header = rows.first else { return [] }
        let col = Dictionary(header.enumerated().map { ($1.trimmingCharacters(in: CharacterSet(charactersIn: "\u{FEFF}")), $0) },
                             uniquingKeysWith: { a, _ in a })
        return rows.dropFirst().compactMap { row in
            func get(_ k: String) -> String? {
                guard let i = col[k], i < row.count, !row[i].isEmpty else { return nil }
                return row[i]
            }
            guard let type = get("type").flatMap(ResourceType.init(rawValue:)), let title = get("title") else { return nil }
            func date(_ k: String) -> Date? { get(k).flatMap { try? Date($0, strategy: .iso8601.year().month().day()) } }
            return ResourceEntity(
                type: type, title: title,
                externalId: get("external_id"), imageURL: get("image_url"), summary: get("summary"),
                authorOrCreator: get("author_or_creator"),
                userRating: get("rating").flatMap(Double.init),
                status: get("status").flatMap(ProgressStatus.init(rawValue:)) ?? .notStarted,
                timeSpentHours: get("hours").flatMap(Double.init),
                lastUpdated: Date(),
                currentPage: get("current_page").flatMap(Int.init),
                totalPages: get("pages").flatMap(Int.init),
                currentSeason: get("season").flatMap(Int.init),
                currentEpisode: get("episode").flatMap(Int.init),
                totalSeasons: get("total_seasons").flatMap(Int.init),
                totalEpisodes: get("total_episodes").flatMap(Int.init),
                startDate: date("start_date"), endDate: date("end_date"),
                reviewComment: get("review")
            )
        }
    }

    /// RFC 4180: campos entre comillas con `""` y saltos de línea dentro.
    static func parseRows(_ s: String) -> [[String]] {
        var rows: [[String]] = [], row: [String] = [], field = "", quoted = false
        var it = s.makeIterator()
        var pending = it.next()
        while let c = pending {
            pending = it.next()
            if quoted {
                if c == "\"" {
                    if pending == "\"" { field.append("\""); pending = it.next() } else { quoted = false }
                } else { field.append(c) }
            } else if c == "\"" { quoted = true }
            else if c == "," { row.append(field); field = "" }
            else if c == "\n" || c == "\r\n" || c == "\r" {
                row.append(field); field = ""
                if row != [""] { rows.append(row) }
                row = []
            } else { field.append(c) }
        }
        if !field.isEmpty || !row.isEmpty { row.append(field); rows.append(row) }
        return rows
    }
}

/// Botón de la barra: importa el CSV propio (el de `ExportCSVButton`) e informa del resultado.
struct ImportCSVButton: View {
    @Environment(\.modelContext) private var modelContext
    @State private var picking = false
    @State private var message: String?

    var body: some View {
        Button { picking = true } label: {
            Image(systemName: "square.and.arrow.down")
                .accessibilityLabel("Importar CSV")
        }
        .fileImporter(isPresented: $picking, allowedContentTypes: [.commaSeparatedText]) { result in
            message = restore(result)
        }
        .alert("Importación", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(message ?? "")
        }
    }

    private func restore(_ result: Result<URL, Error>) -> String {
        guard case .success(let url) = result, url.startAccessingSecurityScopedResource() else { return CSVImporter.unreadable }
        defer { url.stopAccessingSecurityScopedResource() }
        guard let text = CSVImporter.readText(url) else { return CSVImporter.unreadable }
        guard CSVImporter.isOwnFormat(text) else { return String(localized: "El archivo no es un CSV exportado desde TrackHobbies.") }
        let items = CSVImporter.parse(text)
        guard !items.isEmpty else { return CSVImporter.nothingFound }
        return CSVImporter.summary(added: CSVImporter.insert(items, context: modelContext), total: items.count)
    }
}
