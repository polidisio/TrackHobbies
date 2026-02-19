import SwiftUI
import SwiftData

struct ResourceDetailView: View {
    @Bindable var resource: ResourceEntity
    @State private var usePages = true

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                progressSection
                if resource.progressStatus == .inProgress {
                    trackingSection
                }
                if resource.progressStatus == .completed {
                    ratingSection
                }
                infoSection
            }
            .padding()
        }
        .navigationTitle(resource.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            usePages = resource.totalPages != nil || resource.currentPage != nil
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            AsyncImage(url: URL(string: resource.imageURL ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                case .failure, .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay {
                            Image(systemName: resource.resourceType.icon)
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                        }
                @unknown default:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
            }
            .frame(height: 240)
            .cornerRadius(12)

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

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Progreso")
                .font(.headline)

            Picker("Progreso", selection: Binding(
                get: { resource.progressStatus },
                set: { newStatus in
                    let oldStatus = resource.progressStatus
                    resource.progressStatus = newStatus
                    resource.lastUpdated = Date()
                    if oldStatus == .completed && newStatus != .completed {
                        resource.userRating = nil
                    }
                }
            )) {
                ForEach(ProgressStatus.allCases, id: \.self) { status in
                    Text(status.displayName).tag(status)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }

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

    private var bookTrackingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Seguimiento de lectura")
                .font(.headline)

            Picker("Modo", selection: $usePages) {
                Text("Por páginas").tag(true)
                Text("Por porcentaje").tag(false)
            }
            .pickerStyle(.segmented)
            .onChange(of: usePages) { _, newValue in
                if newValue {
                    resource.progressPercentage = nil
                } else {
                    resource.currentPage = nil
                    resource.totalPages = nil
                }
                resource.lastUpdated = Date()
            }

            if usePages {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Página actual")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("0", value: Binding(
                            get: { resource.currentPage ?? 0 },
                            set: {
                                resource.currentPage = $0 > 0 ? $0 : nil
                                resource.lastUpdated = Date()
                                if let current = resource.currentPage, let total = resource.totalPages, total > 0, current >= total {
                                    resource.progressStatus = .completed
                                }
                            }
                        ), format: .number)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total páginas")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("0", value: Binding(
                            get: { resource.totalPages ?? 0 },
                            set: {
                                resource.totalPages = $0 > 0 ? $0 : nil
                                resource.lastUpdated = Date()
                                if let current = resource.currentPage, let total = resource.totalPages, total > 0, current >= total {
                                    resource.progressStatus = .completed
                                }
                            }
                        ), format: .number)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                    }
                }

                if let current = resource.currentPage, let total = resource.totalPages, total > 0 {
                    let percentage = min(Double(current) / Double(total), 1.0)
                    VStack(spacing: 4) {
                        ProgressView(value: percentage)
                            .tint(percentage >= 1.0 ? .green : .blue)
                        Text("Pág. \(current) / \(total) (\(Int(percentage * 100))%)")
                            .font(.caption)
                            .foregroundColor(.secondary)
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
                            .foregroundColor(.secondary)
                    }
                    Slider(value: Binding(
                        get: { resource.progressPercentage ?? 0 },
                        set: {
                            resource.progressPercentage = $0
                            resource.lastUpdated = Date()
                            if $0 >= 100 {
                                resource.progressStatus = .completed
                            }
                        }
                    ), in: 0...100, step: 1)
                    .tint(pct >= 100 ? .green : .blue)

                    ProgressView(value: pct / 100)
                        .tint(pct >= 100 ? .green : .blue)
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }

    private var seriesTrackingSection: some View {
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
                    ), in: 1...99) {
                        Text("T\(resource.currentSeason ?? 1)")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Capítulo")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Stepper(value: Binding(
                        get: { resource.currentEpisode ?? 1 },
                        set: { resource.currentEpisode = $0; resource.lastUpdated = Date() }
                    ), in: 1...999) {
                        Text("E\(resource.currentEpisode ?? 1)")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }

    private var gameTrackingSection: some View {
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
                .frame(width: 80)
                Text("h")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }

    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Valoración")
                    .font(.headline)

                Spacer()

                if let rating = resource.userRating {
                    Text(formatRating(rating))
                        .font(.subheadline)
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
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }

    private var infoSection: some View {
        Group {
            if let summary = resource.summary, !summary.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Resumen")
                        .font(.headline)

                    Text(summary.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression))
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGroupedBackground))
                .cornerRadius(12)
            }

            if let hours = resource.timeSpentHours, hours > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tiempo dedicado")
                        .font(.headline)

                    Text("\(Int(hours))h")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGroupedBackground))
                .cornerRadius(12)
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

struct StarRatingInput: View {
    @Binding var rating: Double

    private let starCount = 5
    private let step = 0.25

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...starCount, id: \.self) { starIndex in
                starView(for: starIndex)
                    .onTapGesture { location in
                        handleTap(starIndex: starIndex, location: location)
                    }
            }
        }
        .frame(height: 44)
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
                rating = min(max(newRating, step), Double(starCount))
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

    private func handleTap(starIndex: Int, location: CGPoint) {
        // Handled in GeometryReader onTapGesture
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
