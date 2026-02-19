import SwiftUI

enum AppTheme {
    static let accent = Color.indigo
    static let accentLight = Color.indigo.opacity(0.12)

    static let bookColor = Color.blue
    static let seriesColor = Color.purple
    static let gameColor = Color.green

    static let cardBackground = Color(.secondarySystemGroupedBackground)
    static let pageBackground = Color(.systemGroupedBackground)
    static let placeholderFill = Color(.tertiarySystemFill)
    static let subtleShadow = Color.black.opacity(0.08)

    static let thumbnailSize = CGSize(width: 52, height: 72)
    static let thumbnailRadius: CGFloat = 8
    static let cardRadius: CGFloat = 12
}

struct MeshBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme

    private var blobOpacity: Double {
        colorScheme == .dark ? 0.25 : 0.35
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AppTheme.pageBackground

                // Top-left blob: indigo
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.indigo.opacity(blobOpacity),
                                Color.indigo.opacity(0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: geometry.size.width * 0.55
                        )
                    )
                    .frame(width: geometry.size.width * 1.1, height: geometry.size.width * 1.1)
                    .offset(x: -geometry.size.width * 0.3, y: -geometry.size.height * 0.15)

                // Center-right blob: blue
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.blue.opacity(blobOpacity * 0.8),
                                Color.blue.opacity(0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: geometry.size.width * 0.5
                        )
                    )
                    .frame(width: geometry.size.width * 0.9, height: geometry.size.width * 0.9)
                    .offset(x: geometry.size.width * 0.35, y: geometry.size.height * 0.15)

                // Bottom-left blob: indigo-blue mix
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.3, green: 0.2, blue: 0.8).opacity(blobOpacity * 0.7),
                                Color.indigo.opacity(0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: geometry.size.width * 0.45
                        )
                    )
                    .frame(width: geometry.size.width * 0.85, height: geometry.size.width * 0.85)
                    .offset(x: -geometry.size.width * 0.15, y: geometry.size.height * 0.4)
            }
        }
        .ignoresSafeArea()
    }
}
