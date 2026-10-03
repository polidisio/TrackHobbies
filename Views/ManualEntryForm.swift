import PhotosUI
import SwiftData
import SwiftUI

/// Datos de la entrada manual (libro, serie o juego). Solo el título es obligatorio.
struct ManualDraft {
    var title = ""
    var creator = ""
    var status: ProgressStatus = .notStarted
    var pages = ""
    var seasons = ""
    var episodes = ""
    var hours = ""
    var imageURL: String?

    var isValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    @discardableResult
    func insert(type: ResourceType, context: ModelContext) -> ResourceEntity {
        func int(_ s: String) -> Int? { Int(s.trimmingCharacters(in: .whitespaces)).flatMap { $0 > 0 ? $0 : nil } }
        let creator = creator.trimmingCharacters(in: .whitespaces)
        let pagesValue: Int? = if case .success(let n) = PageTracking.validateTotal(pages, currentPage: nil) { n } else { nil }
        let entity = ResourceEntity(
            type: type,
            title: title.trimmingCharacters(in: .whitespaces),
            imageURL: imageURL,
            authorOrCreator: creator.isEmpty ? nil : creator,
            status: status,
            timeSpentHours: Double(hours.replacingOccurrences(of: ",", with: ".")).flatMap { $0 > 0 ? $0 : nil },
            lastUpdated: Date(),
            totalPages: type == .book ? pagesValue : nil,
            totalSeasons: type == .series ? int(seasons) : nil,
            totalEpisodes: type == .series ? int(episodes) : nil,
            startDate: status == .inProgress ? Date() : nil,
            endDate: status == .completed ? Date() : nil
        )
        context.insert(entity)
        Analytics.track("resource_added", ["type": type.rawValue, "source": "manual"])
        do { try context.save() } catch { print("Error saving manual entry: \(error)") }
        return entity
    }
}

struct ManualEntryForm: View {
    let type: ResourceType
    @Binding var draft: ManualDraft
    @State private var pickedPhoto: PhotosPickerItem?
    @State private var showMore = false

    private let statuses: [ProgressStatus] = [.notStarted, .wishlist, .inProgress, .completed]

    var body: some View {
        Form {
            Section("Información") {
                TextField("Título", text: $draft.title)
                    .autocorrectionDisabled() // el autocorrector estropea nombres propios («Dune» → «Dime»)
                if type == .book {
                    TextField("Autor (opcional)", text: $draft.creator)
                        .autocorrectionDisabled()
                }
            }
            Section {
                DisclosureGroup("Más datos (opcional)", isExpanded: $showMore) {
                    Picker("Estado", selection: $draft.status) {
                        ForEach(statuses, id: \.self) { Text($0.displayName).tag($0) }
                    }
                    switch type {
                    case .book:
                        TextField("Total de páginas", text: $draft.pages).keyboardType(.numberPad)
                    case .series:
                        TextField("Temporadas", text: $draft.seasons).keyboardType(.numberPad)
                        TextField("Episodios", text: $draft.episodes).keyboardType(.numberPad)
                    case .game:
                        TextField("Horas jugadas", text: $draft.hours).keyboardType(.decimalPad)
                    }
                    coverRow
                }
            }
        }
        .onChange(of: pickedPhoto) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    draft.imageURL = CoverStore.dataURL(from: data)
                }
            }
        }
    }

    private var coverRow: some View {
        HStack {
            if draft.imageURL != nil {
                CoverImage(url: draft.imageURL) { phase in
                    if case .success(let image) = phase { image.resizable().scaledToFill() } else { Color.gray.opacity(0.2) }
                }
                .frame(width: 40, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .accessibilityHidden(true)
            }
            PhotosPicker(selection: $pickedPhoto, matching: .images) {
                Label(draft.imageURL == nil ? "Subir portada" : "Cambiar portada", systemImage: "photo")
            }
            if draft.imageURL != nil {
                Spacer()
                Button(role: .destructive) { draft.imageURL = nil; pickedPhoto = nil } label: {
                    Image(systemName: "trash").accessibilityLabel("Quitar portada")
                }
                .buttonStyle(.borderless)
            }
        }
    }
}

/// Portadas subidas por el usuario: `data:` URL dentro de `imageURL`.
/// ponytail: va como `data:` URL (≈50 KB) para no tocar el esquema de CloudKit Production
/// (un campo nuevo exige SchemaV3 + despliegue). Si hay muchas, mover a `Data` con `.externalStorage`.
enum CoverStore {
    private static let cache = NSCache<NSString, UIImage>()

    static func decode(_ url: String) -> UIImage? {
        guard url.hasPrefix("data:") else { return nil }
        if let hit = cache.object(forKey: url as NSString) { return hit }
        guard let comma = url.firstIndex(of: ","),
              let data = Data(base64Encoded: String(url[url.index(after: comma)...])),
              let image = UIImage(data: data) else { return nil }
        cache.setObject(image, forKey: url as NSString)
        return image
    }

    /// Reduce a 480 px por el lado largo y JPEG 0.7: cabe de sobra en un campo de CloudKit.
    static func dataURL(from data: Data, maxSide: CGFloat = 480) -> String? {
        guard let image = UIImage(data: data) else { return nil }
        let scale = min(maxSide / max(image.size.width, image.size.height), 1.0)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        // scale 1: por defecto el renderer usa la de la pantalla (3x) y la imagen saldría 3 veces más grande.
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        return resized.jpegData(compressionQuality: 0.7).map { "data:image/jpeg;base64," + $0.base64EncodedString() }
    }
}

/// Carga la portada desde una URL o desde una imagen subida (`data:`).
struct CoverImage<Content: View>: View {
    let url: String?
    @ViewBuilder let content: (AsyncImagePhase) -> Content

    var body: some View {
        if let url, let image = CoverStore.decode(url) {
            content(.success(Image(uiImage: image)))
        } else {
            AsyncImage(url: URL(string: url ?? ""), content: content)
        }
    }
}
