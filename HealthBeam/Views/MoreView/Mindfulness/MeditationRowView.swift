import SwiftUI
import Combine

struct MeditationRowView: View {
    let meditation: Meditation

    var body: some View {
        HStack(spacing: 16) {
            // Meditasyon görseli
            Image(mainCategories.first(where: { $0.name == meditation.categoryName })?.imageName ?? "category_calm.png")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 70, height: 70)
                .cornerRadius(10)
                .clipped()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(meditation.title)
                    .fontWeight(.bold)
                    .lineLimit(1)
                Text("\(meditation.durationInMinutes) minutes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
