import Foundation

/// Reglas puras para emparejar un libro (título + autor) con resultados de Google Books.
enum BookMatch {
    /// Minúsculas, sin acentos ni signos: «Pérez-Reverte, A.» → «perezreverte a».
    static func normalize(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
            .lowercased()
            .filter { $0.isLetter || $0.isNumber || $0 == " " }
            .trimmingCharacters(in: .whitespaces)
    }

    /// Goodreads añade la serie al título: «The Hobbit (The Lord of the Rings, #0)» → «The Hobbit».
    static func cleanTitle(_ title: String) -> String {
        guard let open = title.lastIndex(of: "("), title.hasSuffix(")"), open > title.startIndex else { return title }
        return title[..<open].trimmingCharacters(in: .whitespaces)
    }

    /// Consulta para `/books/search` (el Worker corta a 100 caracteres).
    static func query(title: String, author: String?) -> String {
        func clean(_ s: String) -> String { s.replacingOccurrences(of: "\"", with: "") }
        var q = "intitle:\"\(String(clean(cleanTitle(title)).prefix(60)))\""
        if let author, !author.isEmpty { q += " inauthor:\"\(String(clean(author).prefix(30)))\"" }
        return q
    }

    /// Mejor resultado, o `nil` si ninguno encaja (mejor sin datos que con los de otro libro).
    static func pick(_ results: [GoogleBookItem], title: String, author: String?) -> GoogleBookItem? {
        let wanted = normalize(cleanTitle(title))
        guard !wanted.isEmpty else { return nil }
        let surname = author.map(normalize)?.split(separator: " ").last.map(String.init)
        let fits = results.filter { r in
            let t = normalize(r.title)
            guard !t.isEmpty, t.contains(wanted) || wanted.contains(t) else { return false }
            guard let surname, !r.author.isEmpty else { return true }
            return normalize(r.author).contains(surname)
        }
        // Estable: entre iguales gana el primero (el orden de relevancia de Google).
        return fits.max { score($0) < score($1) }
    }

    private static func score(_ r: GoogleBookItem) -> Int {
        (r.numberOfPages != nil ? 2 : 0) + (r.coverURL != nil ? 1 : 0)
    }
}
