import SwiftUI

// Minimal row for a Resource (stub for MVP)
struct ResourceRow: View {
    let title: String
    let author: String?
    let rating: Double?

    var body: some View {
        HStack {
            Rectangle()
                .fill(Color.gray)
                .frame(width: 48, height: 64)
                .cornerRadius(6)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                if let a = author {
                    Text(a).font(.subheadline).foregroundColor(.secondary)
                }
            }
            Spacer()
            if let r = rating {
                Text(String(format: "%.2f", r))
                    .font(.subheadline)
                    .padding(.trailing, 8)
            }
        }
        .padding(.vertical, 6)
    }
}

struct ResourceRow_Previews: PreviewProvider {
    static var previews: some View {
        ResourceRow(title: "Dune", author: "Frank Herbert", rating: 4.5)
            .previewLayout(.sizeThatFits)
    }
}
