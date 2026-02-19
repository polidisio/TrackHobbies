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
