import SwiftUI

struct FeaturedMeditationCard: View {
    let meditation: Meditation
    var body: some View {
        ZStack(alignment: .leading) {
            Image(meditation.categoryName == "Rahatlama" ? "meditation_bg_1" : "meditation_bg_2")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 300, height: 200)
                .cornerRadius(20)
                .clipped()

            Rectangle()
                .foregroundColor(.black)
                .opacity(0.3)
                .cornerRadius(20)

            VStack(alignment: .leading, spacing: 8) {
                Text(meditation.title)
                    .font(.title2)
                    .fontWeight(.bold)

                Text("\(meditation.durationInMinutes) minutes - \(meditation.categoryName.uppercased())")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .opacity(0.8)
            }
            .foregroundColor(.white)
            .padding(20)
        }
    }
}
