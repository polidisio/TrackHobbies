import SwiftUI
import SwiftData

struct StatsView: View {
    @Query(sort: \ResourceEntity.lastUpdated, order: .reverse) private var allResources: [ResourceEntity]

    private var books: [ResourceEntity] { allResources.filter { $0.type == "book" } }
    private var series: [ResourceEntity] { allResources.filter { $0.type == "series" } }
    private var games: [ResourceEntity] { allResources.filter { $0.type == "game" } }

    private func completed(_ items: [ResourceEntity]) -> [ResourceEntity] {
        items.filter { $0.progressStatus == .completed || $0.progressStatus == .archived }
    }

    private func rated(_ items: [ResourceEntity]) -> [ResourceEntity] {
        items.filter { $0.userRating != nil }
    }

    private func averageRating(_ items: [ResourceEntity]) -> Double? {
        let ratedItems = rated(items)
        guard !ratedItems.isEmpty else { return nil }
        let sum = ratedItems.compactMap(\.userRating).reduce(0, +)
        return sum / Double(ratedItems.count)
    }

    private func bestRated(_ items: [ResourceEntity]) -> ResourceEntity? {
        items.max(by: { ($0.userRating ?? 0) < ($1.userRating ?? 0) })
    }

    private var totalPagesRead: Int {
        books.reduce(0) { total, book in
            if book.progressStatus == .completed || book.progressStatus == .archived {
                return total + (book.totalPages ?? book.currentPage ?? 0)
            } else if book.progressStatus == .inProgress {
                return total + (book.currentPage ?? 0)
            }
            return total
        }
    }

    private var totalSeasonsWatched: Int {
        completed(series).compactMap(\.totalSeasons).reduce(0, +)
    }

    private var totalEpisodesWatched: Int {
        completed(series).compactMap(\.totalEpisodes).reduce(0, +)
    }

    private var totalHoursPlayed: Double {
        games.compactMap(\.timeSpentHours).reduce(0, +)
    }

    private var completedThisMonth: Int {
        let cal = Calendar.current
        let now = Date()
        return allResources.filter { item in
            guard let end = item.endDate else { return false }
            return cal.isDate(end, equalTo: now, toGranularity: .month)
        }.count
    }

    private var completedThisYear: Int {
        let cal = Calendar.current
        let now = Date()
        return allResources.filter { item in
            guard let end = item.endDate else { return false }
            return cal.isDate(end, equalTo: now, toGranularity: .year)
        }.count
    }

    private var averageCompletionDays: Int? {
        let pairs = allResources.compactMap { item -> Int? in
            guard let start = item.startDate, let end = item.endDate else { return nil }
            return Calendar.current.dateComponents([.day], from: start, to: end).day
        }
        guard !pairs.isEmpty else { return nil }
        return pairs.reduce(0, +) / pairs.count
    }

    private var last30DaysCount: Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return allResources.filter { item in
            guard let end = item.endDate else { return false }
            return end >= cutoff
        }.count
    }

    private var ratingDistribution: [(label: String, count: Int)] {
        let ratedItems = allResources.compactMap(\.userRating)
        return [
            ("1-2", ratedItems.filter { $0 >= 1 && $0 < 2 }.count),
            ("2-3", ratedItems.filter { $0 >= 2 && $0 < 3 }.count),
            ("3-4", ratedItems.filter { $0 >= 3 && $0 < 4 }.count),
            ("4-5", ratedItems.filter { $0 >= 4 && $0 <= 5 }.count)
        ]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                resumenGeneralSection
                porEstadoSection
                librosSection
                seriesSection
                juegosSection
                actividadTemporalSection
                ratingsSection
            }
            .padding()
        }
        .background { MeshBackgroundView() }
        .navigationTitle("Estadísticas")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - 1. Resumen General

    private var resumenGeneralSection: some View {
        DetailCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Resumen general")
                    .font(.headline)

                Text("\(allResources.count) elementos en tu colección")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    StatCard(
                        icon: ResourceType.book.filledIcon,
                        value: "\(books.count)",
                        label: "Libros",
                        color: AppTheme.bookColor
                    )
                    StatCard(
                        icon: ResourceType.series.filledIcon,
                        value: "\(series.count)",
                        label: "Series",
                        color: AppTheme.seriesColor
                    )
                    StatCard(
                        icon: ResourceType.game.filledIcon,
                        value: "\(games.count)",
                        label: "Juegos",
                        color: AppTheme.gameColor
                    )
                }
            }
        }
    }

    // MARK: - 2. Por Estado

    private var porEstadoSection: some View {
        DetailCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Por estado")
                    .font(.headline)

                ForEach(ProgressStatus.allCases, id: \.self) { status in
                    let count = allResources.filter { $0.progressStatus == status }.count
                    HStack(spacing: 10) {
                        Image(systemName: status.icon)
                            .foregroundColor(status.color)
                            .frame(width: 20)
                        Text(status.sectionTitle)
                            .font(.subheadline)
                        Spacer()
                        Text("\(count)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }
                }

                if !allResources.isEmpty {
                    let completedCount = allResources.filter { $0.progressStatus == .completed || $0.progressStatus == .archived }.count
                    let pct = Double(completedCount) / Double(allResources.count) * 100

                    Divider()

                    HStack {
                        Text("Completados")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(pct))% del total")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
            }
        }
    }

    // MARK: - 3. Libros

    private var librosSection: some View {
        DetailCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Libros", systemImage: ResourceType.book.filledIcon)
                    .font(.headline)
                    .foregroundColor(AppTheme.bookColor)

                StatRow(label: "Leídos", value: "\(completed(books).count)")
                StatRow(label: "Páginas leídas", value: "\(totalPagesRead)")

                if let avg = averageRating(books) {
                    StatRow(label: "Valoración media", value: String(format: "%.1f", avg) + " / 5")
                }

                if let best = bestRated(books), best.userRating != nil {
                    Divider()
                    bestRatedRow(best)
                }
            }
        }
    }

    // MARK: - 4. Series

    private var seriesSection: some View {
        DetailCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Series", systemImage: ResourceType.series.filledIcon)
                    .font(.headline)
                    .foregroundColor(AppTheme.seriesColor)

                StatRow(label: "Completadas", value: "\(completed(series).count)")
                StatRow(label: "Temporadas vistas", value: "\(totalSeasonsWatched)")
                StatRow(label: "Episodios vistos", value: "\(totalEpisodesWatched)")

                if let avg = averageRating(series) {
                    StatRow(label: "Valoración media", value: String(format: "%.1f", avg) + " / 5")
                }

                if let best = bestRated(series), best.userRating != nil {
                    Divider()
                    bestRatedRow(best)
                }
            }
        }
    }

    // MARK: - 5. Juegos

    private var juegosSection: some View {
        DetailCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Juegos", systemImage: ResourceType.game.filledIcon)
                    .font(.headline)
                    .foregroundColor(AppTheme.gameColor)

                StatRow(label: "Completados", value: "\(completed(games).count)")
                StatRow(label: "Horas jugadas", value: String(format: "%.0f h", totalHoursPlayed))

                if let avg = averageRating(games) {
                    StatRow(label: "Valoración media", value: String(format: "%.1f", avg) + " / 5")
                }

                if let best = bestRated(games), best.userRating != nil {
                    Divider()
                    bestRatedRow(best)
                }
            }
        }
    }

    // MARK: - 6. Actividad Temporal

    private var actividadTemporalSection: some View {
        DetailCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Actividad", systemImage: "calendar")
                    .font(.headline)

                StatRow(label: "Completados este mes", value: "\(completedThisMonth)")
                StatRow(label: "Completados este año", value: "\(completedThisYear)")

                if let avgDays = averageCompletionDays {
                    StatRow(label: "Tiempo medio", value: "\(avgDays) días")
                }

                StatRow(label: "Últimos 30 días", value: "\(last30DaysCount) completados")
            }
        }
    }

    // MARK: - 7. Ratings

    private var ratingsSection: some View {
        DetailCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Valoraciones", systemImage: "star.fill")
                    .font(.headline)
                    .foregroundColor(.yellow)

                if let avg = averageRating(allResources) {
                    HStack {
                        Text("Media global")
                            .font(.subheadline)
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f / 5", avg))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                    }

                    Divider()
                }

                let dist = ratingDistribution
                let maxCount = dist.map(\.count).max() ?? 1

                ForEach(dist, id: \.label) { bucket in
                    RatingDistributionBar(
                        label: bucket.label,
                        count: bucket.count,
                        maxCount: max(maxCount, 1)
                    )
                }
            }
        }
    }

    // MARK: - Best Rated Row

    private func bestRatedRow(_ item: ResourceEntity) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mejor valorado")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                ResourceThumbnail(
                    url: item.imageURL,
                    icon: item.resourceType.filledIcon,
                    color: item.resourceType.color
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)

                    if let author = item.authorOrCreator, !author.isEmpty {
                        Text(author)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    if let rating = item.userRating {
                        RatingView(rating: rating)
                    }
                }

                Spacer()
            }
        }
    }
}

// MARK: - StatCard

private struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - StatRow

private struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - RatingDistributionBar

private struct RatingDistributionBar: View {
    let label: String
    let count: Int
    let maxCount: Int

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 2) {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundColor(.yellow)
                Text(label)
                    .font(.caption)
                    .monospacedDigit()
            }
            .frame(width: 50, alignment: .leading)

            GeometryReader { geometry in
                let fraction = maxCount > 0 ? CGFloat(count) / CGFloat(maxCount) : 0
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(AppTheme.accent.opacity(0.6))
                    .frame(width: max(geometry.size.width * fraction, count > 0 ? 4 : 0))
            }
            .frame(height: 14)

            Text("\(count)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 24, alignment: .trailing)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        StatsView()
    }
    .modelContainer(DataStore.shared.modelContainer)
}
