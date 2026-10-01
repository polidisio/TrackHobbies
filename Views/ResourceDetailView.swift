import SwiftUI
import SwiftData

struct ResourceDetailView: View {
    @Bindable var resource: ResourceEntity
    @State private var usePages = true
    @State private var pendingChange: PendingChange?
    @State private var showTotalEditor = false
    @State private var totalDraft = ""
    @State private var totalError: String?

    /// Cambio que borraría datos del usuario y espera su confirmación.
    private struct PendingChange {
        let title: String
        let message: String
        let confirmLabel: String
        let apply: () -> Void
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                progressSection
                if resource.progressStatus == .inProgress {
                    trackingSection
                }
                datesSection
                if resource.progressStatus == .completed || resource.progressStatus == .archived {
                    ratingSection
                }
                infoSection
            }
            .padding()
        }
        .background {
            MeshBackgroundView()
        }
        .navigationTitle(resource.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            usePages = resource.totalPages != nil || resource.currentPage != nil
        }
        .confirmationDialog(
            pendingChange?.title ?? "",
            isPresented: Binding(get: { pendingChange != nil }, set: { if !$0 { pendingChange = nil } }),
            titleVisibility: .visible,
            presenting: pendingChange
        ) { change in
            Button(change.confirmLabel, role: .destructive) { change.apply() }
        } message: { change in
            Text(change.message)
        }
        .alert("Total de páginas", isPresented: $showTotalEditor) {
            TextField("Páginas", text: $totalDraft)
                .keyboardType(.numberPad)
            Button("Guardar") { saveTotal() }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Cámbialo solo si tu edición tiene otro número de páginas.")
        }
    }

    // MARK: - Cambios con pérdida de datos

    private func requestStatus(_ newStatus: ProgressStatus) {
        if resource.progressStatus == .completed, newStatus != .completed, newStatus != .archived,
           let rating = resource.userRating {
            let nota = rating.formatted(.number.precision(.fractionLength(0...2)))
            pendingChange = PendingChange(
                title: String(localized: "¿Sacar de «Completado»?"),
                message: String(localized: "Se borrará tu nota (\(nota) de 5)."),
                confirmLabel: String(localized: "Cambiar y borrar nota")
            ) { applyStatus(newStatus) }
        } else {
            applyStatus(newStatus)
        }
    }

    private func applyStatus(_ newStatus: ProgressStatus) {
        let oldStatus = resource.progressStatus
        withAnimation {
            resource.progressStatus = newStatus
        }
        resource.lastUpdated = Date()

        if newStatus == .inProgress && resource.startDate == nil {
            resource.startDate = Date()
        }
        if newStatus == .completed {
            resource.endDate = Date()
        }
        if oldStatus == .completed && newStatus == .inProgress {
            resource.endDate = nil
        }
        if newStatus == .wishlist || newStatus == .notStarted {
            resource.startDate = nil
            resource.endDate = nil
        }
        if oldStatus == .completed && newStatus != .completed && newStatus != .archived {
            resource.userRating = nil
        }
    }

    private func requestTrackingMode(_ newValue: Bool) {
        guard newValue != usePages else { return }
        var lost: [String] = []
        if newValue {
            if let pct = resource.progressPercentage, pct > 0 { lost.append(String(localized: "el porcentaje (\(Int(pct))%)")) }
        } else {
            if let page = resource.currentPage { lost.append(String(localized: "la página actual (\(page))")) }
            if let total = resource.totalPages { lost.append(String(localized: "el total de páginas (\(total))")) }
        }
        if lost.isEmpty {
            applyTrackingMode(newValue)
        } else {
            pendingChange = PendingChange(
                title: String(localized: "¿Cambiar el modo de seguimiento?"),
                message: String(localized: "Se borrará \(ListFormatter.localizedString(byJoining: lost))."),
                confirmLabel: String(localized: "Cambiar y borrar")
            ) { applyTrackingMode(newValue) }
        }
    }

    private func applyTrackingMode(_ newValue: Bool) {
        usePages = newValue
        if newValue {
            resource.progressPercentage = nil
        } else {
            resource.currentPage = nil
            resource.totalPages = nil
        }
        resource.lastUpdated = Date()
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            AsyncImage(url: URL(string: resource.imageURL ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                case .failure, .empty:
                    RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                        .fill(AppTheme.placeholderFill)
                        .overlay {
                            Image(systemName: resource.resourceType.filledIcon)
                                .font(.system(size: 40))
                                .foregroundStyle(resource.resourceType.color.opacity(0.4))
                        }
                @unknown default:
                    RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                        .fill(AppTheme.placeholderFill)
                }
            }
            .frame(height: 240)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
            .shadow(color: AppTheme.subtleShadow, radius: 8, y: 4)

            Text(resource.title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            if let author = resource.authorOrCreator, !author.isEmpty {
                Text(author)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Progress

    private var progressSection: some View {
        DetailCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Progreso")
                    .font(.headline)

                Picker("Progreso", selection: Binding(
                    get: { resource.progressStatus },
                    set: { requestStatus($0) }
                )) {
                    ForEach(ProgressStatus.allCases, id: \.self) { status in
                        Text(status.displayName).tag(status)
                    }
                }
                .pickerStyle(.menu)
                .tint(resource.progressStatus.color)
            }
        }
    }

    // MARK: - Tracking

    @ViewBuilder
    private var trackingSection: some View {
        switch resource.resourceType {
        case .book:
            bookTrackingSection
        case .series:
            seriesTrackingSection
        case .game:
            gameTrackingSection
        }
    }

    private func markCompleted() {
        resource.progressStatus = .completed
        resource.endDate = Date()
        resource.lastUpdated = Date()
    }

    private func saveTotal() {
        switch PageTracking.validateTotal(totalDraft, currentPage: resource.currentPage) {
        case .success(let total):
            resource.totalPages = total
            resource.lastUpdated = Date()
            totalError = nil
        case .failure(.invalid):
            totalError = String(localized: "Introduce un número de páginas entre 1 y \(PageTracking.maxPages).")
        case .failure(.belowCurrent(let current)):
            totalError = String(localized: "El total no puede ser menor que la página actual (\(current)).")
        }
    }

    private var bookTrackingSection: some View {
        DetailCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Seguimiento de lectura")
                    .font(.headline)

                Picker("Modo", selection: Binding(get: { usePages }, set: { requestTrackingMode($0) })) {
                    Text("Por páginas").tag(true)
                    Text("Por porcentaje").tag(false)
                }
                .pickerStyle(.segmented)

                if usePages {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Página actual")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("0", value: Binding(
                                get: { resource.currentPage ?? 0 },
                                set: {
                                    let page = PageTracking.clampedPage($0, total: resource.totalPages)
                                    resource.currentPage = page > 0 ? page : nil
                                    resource.lastUpdated = Date()
                                    if PageTracking.isFinished(page: resource.currentPage, total: resource.totalPages) {
                                        markCompleted()
                                    }
                                }
                            ), format: .number)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                        }

                        // El total no se teclea a la vez que la lectura: se cambia con un editor explícito.
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total páginas")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Button {
                                totalDraft = resource.totalPages.map(String.init) ?? ""
                                totalError = nil
                                showTotalEditor = true
                            } label: {
                                HStack {
                                    Text(resource.totalPages.map(String.init) ?? "—")
                                    Spacer()
                                    Image(systemName: resource.totalPages == nil ? "plus.circle" : "pencil")
                                }
                                .padding(8)
                                .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(resource.totalPages == nil ? "Añadir total de páginas" : "Editar total de páginas")
                        }
                    }

                    if let totalError {
                        Text(totalError)
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    if let current = resource.currentPage, let total = resource.totalPages, total > 0 {
                        let percentage = min(Double(current) / Double(total), 1.0)
                        VStack(spacing: 4) {
                            ProgressView(value: percentage)
                                .tint(percentage >= 1.0 ? .green : AppTheme.accent)
                            Text("Pág. \(current) / \(total) (\(Int(percentage * 100))%)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        if PageTracking.isFinished(page: current, total: total) {
                            Button("Marcar como completado") { markCompleted() }
                                .buttonStyle(.borderedProminent)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        let pct = resource.progressPercentage ?? 0
                        HStack {
                            Text("Progreso")
                                .font(.subheadline)
                            Spacer()
                            Text("\(Int(pct))%")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        Slider(value: Binding(
                            get: { resource.progressPercentage ?? 0 },
                            set: {
                                resource.progressPercentage = $0
                                resource.lastUpdated = Date()
                                if $0 >= 100 {
                                    resource.progressStatus = .completed
                                    resource.endDate = Date()
                                }
                            }
                        ), in: 0...100, step: 1)
                        .tint(pct >= 100 ? .green : AppTheme.accent)

                        ProgressView(value: pct / 100)
                            .tint(pct >= 100 ? .green : AppTheme.accent)
                    }
                }
            }
        }
    }

    private var seriesTrackingSection: some View {
        DetailCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Seguimiento")
                    .font(.headline)

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Temporada")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Stepper(value: Binding(
                            get: { resource.currentSeason ?? 1 },
                            set: { resource.currentSeason = $0; resource.lastUpdated = Date() }
                        ), in: 1...(resource.totalSeasons ?? 99)) {
                            if let total = resource.totalSeasons {
                                Text("T\(resource.currentSeason ?? 1) de \(total)")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            } else {
                                Text("T\(resource.currentSeason ?? 1)")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Capítulo")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Stepper(value: Binding(
                            get: { resource.currentEpisode ?? 1 },
                            set: { resource.currentEpisode = $0; resource.lastUpdated = Date() }
                        ), in: 1...(resource.totalEpisodes ?? 999)) {
                            if let total = resource.totalEpisodes {
                                Text("E\(resource.currentEpisode ?? 1) de \(total)")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            } else {
                                Text("E\(resource.currentEpisode ?? 1)")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            }
        }
    }

    private var gameTrackingSection: some View {
        DetailCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Seguimiento")
                    .font(.headline)

                HStack {
                    Text("Horas jugadas")
                        .font(.subheadline)
                    Spacer()
                    TextField("0", value: Binding(
                        get: { resource.timeSpentHours ?? 0 },
                        set: { resource.timeSpentHours = $0 > 0 ? $0 : nil; resource.lastUpdated = Date() }
                    ), format: .number)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                    .frame(minWidth: 80)
                    Text("h")
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Dates

    @ViewBuilder
    private var datesSection: some View {
        if resource.startDate != nil || resource.endDate != nil {
            DetailCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Fechas")
                        .font(.headline)

                    if resource.startDate != nil {
                        DatePicker(
                            "Inicio",
                            selection: Binding(
                                get: { resource.startDate ?? Date() },
                                set: { resource.startDate = $0; resource.lastUpdated = Date() }
                            ),
                            displayedComponents: .date
                        )
                    }

                    if resource.endDate != nil {
                        DatePicker(
                            "Fin",
                            selection: Binding(
                                get: { resource.endDate ?? Date() },
                                set: { resource.endDate = $0; resource.lastUpdated = Date() }
                            ),
                            displayedComponents: .date
                        )
                    }

                    if let start = resource.startDate, let end = resource.endDate {
                        let days = Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
                        Text("\(days) días")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Rating

    private var ratingSection: some View {
        DetailCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Valoración")
                        .font(.headline)

                    Spacer()

                    if let rating = resource.userRating {
                        Text(formatRating(rating))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                }

                StarRatingInput(rating: Binding(
                    get: { resource.userRating ?? 0 },
                    set: { newRating in
                        resource.userRating = newRating > 0 ? newRating : nil
                        resource.lastUpdated = Date()
                    }
                ))

                VStack(alignment: .leading, spacing: 6) {
                    Text("Comentario")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Escribe un comentario...", text: Binding(
                        get: { resource.reviewComment ?? "" },
                        set: {
                            resource.reviewComment = $0.isEmpty ? nil : $0
                            resource.lastUpdated = Date()
                        }
                    ), axis: .vertical)
                    .lineLimit(3...6)
                    .textFieldStyle(.roundedBorder)
                }
            }
        }
    }

    // MARK: - Info

    private var infoSection: some View {
        Group {
            if let summary = resource.summary, !summary.isEmpty {
                DetailCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Resumen")
                            .font(.headline)

                        Text(summary.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression))
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }

            if let hours = resource.timeSpentHours, hours > 0, resource.resourceType != .game || resource.progressStatus != .inProgress {
                DetailCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tiempo dedicado")
                            .font(.headline)

                        Text("\(Int(hours))h")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private func formatRating(_ rating: Double) -> String {
        if rating == rating.rounded() {
            return String(format: "%.0f / 5", rating)
        } else {
            return String(format: "%.2g / 5", rating)
        }
    }
}

// MARK: - Detail Card Container

struct DetailCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
    }
}

// MARK: - Star Rating

struct StarRatingInput: View {
    @Binding var rating: Double

    private let starCount = 5
    private let step = 0.25

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...starCount, id: \.self) { starIndex in
                starView(for: starIndex)
            }
        }
        .frame(height: 44)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Nota")
        .accessibilityValue(rating > 0 ? "\(rating.formatted(.number.precision(.fractionLength(0...2)))) de 5" : "Sin nota")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: rating = min(rating + step, Double(starCount))
            case .decrement: rating = max(rating - step, step)
            @unknown default: break
            }
        }
    }

    private func starView(for index: Int) -> some View {
        GeometryReader { geometry in
            ZStack {
                Image(systemName: "star")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.yellow)

                Image(systemName: "star.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.yellow)
                    .clipShape(
                        FillClip(fillAmount: fillAmount(for: index))
                    )
            }
            .contentShape(Rectangle())
            .onTapGesture { location in
                let fraction = location.x / geometry.size.width
                let snapped = snapToQuarter(fraction)
                let newRating = Double(index - 1) + snapped
                withAnimation(.easeInOut(duration: 0.15)) {
                    rating = min(max(newRating, step), Double(starCount))
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func fillAmount(for starIndex: Int) -> Double {
        let starStart = Double(starIndex - 1)
        if rating >= Double(starIndex) {
            return 1.0
        } else if rating > starStart {
            return rating - starStart
        } else {
            return 0.0
        }
    }

    private func snapToQuarter(_ value: Double) -> Double {
        let snapped = (value / step).rounded() * step
        return min(max(snapped, step), 1.0)
    }
}

struct FillClip: Shape {
    let fillAmount: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(CGRect(
            x: rect.minX,
            y: rect.minY,
            width: rect.width * fillAmount,
            height: rect.height
        ))
        return path
    }
}

#Preview {
    let container = DataStore.shared.modelContainer
    let resource = ResourceEntity(
        type: .book,
        title: "Dune",
        imageURL: "https://covers.openlibrary.org/b/id/8231856-M.jpg",
        authorOrCreator: "Frank Herbert",
        status: .completed
    )
    resource.userRating = 4.5
    resource.summary = "A science fiction masterpiece about the desert planet Arrakis."

    return NavigationStack {
        ResourceDetailView(resource: resource)
    }
    .modelContainer(container)
}
