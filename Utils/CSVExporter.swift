import Foundation

// Simple CSV exporter for Resource model (minimal, for MVP)
struct CSVResource {
    let id: String
    let type: String
    let title: String
    let authorOrCreator: String?
    let externalId: String?
    let status: String
    let timeSpentHours: Double?
    let userRating: Double?
    let summary: String?
}

struct CSVExporter {
    static func export(resources: [CSVResource]) -> String {
        var lines: [String] = []
        // Header
        lines.append("id,type,title,authorOrCreator,externalId,status,timeSpentHours,userRating,summary")

        for r in resources {
            let titleField = r.title.replacingOccurrences(of: "\"", with: "\"\"")
            let author = (r.authorOrCreator ?? "").replacingOccurrences(of: "\"", with: "\"\"")
            let external = (r.externalId ?? "").replacingOccurrences(of: "\"", with: "\"\"")
            let summary = (r.summary ?? "").replacingOccurrences(of: "\"", with: "\"\"")
            let line = "\"\(r.id)\",\"\(r.type)\",\"\(titleField)\",\"\(author)\",\"\(external)\",\"\(r.status)\",\"\(r.timeSpentHours ?? 0)\",\"\(r.userRating ?? 0)\",\"\(summary)\""
            lines.append(line)
        }
        return lines.joined(separator: "\n")
    }
}
