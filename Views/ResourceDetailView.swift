import SwiftUI
import SwiftData

struct ResourceDetailView: View {
    @Bindable var resource: ResourceEntity

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                progressSection
                if resource.progressStatus == .completed {
                    ratingSection
                }
                infoSection
            }
            .padding()
        }
        .navigationTitle(resource.title)
        .navigationBarTitleDisplayMode(.inline)
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
