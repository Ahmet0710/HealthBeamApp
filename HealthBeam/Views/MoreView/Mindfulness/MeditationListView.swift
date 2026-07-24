import SwiftUI

struct MeditationListView: View {
    let categoryName: String
    @State private var selectedMeditation: Meditation?

    var filteredMeditations: [Meditation] {
        return allMeditations.filter { $0.categoryName == categoryName }
    }
    
    // ✅ Renk Paleti Güncellendi: Energy and Focus artık simsiyah!
    private func gradientForCategory(_ category: String) -> LinearGradient {
        switch category {
        case "Relaxing Sleep":
            return LinearGradient(colors: [Color(red: 20/255, green: 32/255, blue: 54/255), Color(red: 54/255, green: 20/255, blue: 60/255)], startPoint: .topLeading, endPoint: .bottomTrailing)
            
        case "Self-Worth and Love":
            return LinearGradient(colors: [Color.pink.opacity(0.4), Color.purple.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
            
        case "Relationships and Connection":
            return LinearGradient(colors: [.orange.opacity(0.8), .red.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
            
        case "Inner Peace and Calmness":
            return LinearGradient(colors: [Color.teal.opacity(0.6), Color.blue.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
            
        case "Growth and Transformation":
            return LinearGradient(colors: [Color.green.opacity(0.6), Color.cyan.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
            
        case "Energy and Focus":
            return LinearGradient(colors: [.black, .black], startPoint: .top, endPoint: .bottom)
            
        default:
            return LinearGradient(colors: [.gray, .black], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredMeditations) { meditation in
                    Button(action: {
                        selectedMeditation = meditation
                    }) {
                        MeditationListCard(meditation: meditation)
                            .tint(.primary)
                    }
                }
            }
            .padding()
        }
        .background(gradientForCategory(categoryName).ignoresSafeArea())
        .navigationTitle(categoryName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .fullScreenCover(item: $selectedMeditation) { meditation in
            PlayerView(meditation: meditation)
        }
    }
}

// MARK: - Meditation List Card (Premium Card Structure)
struct MeditationListCard: View {
    let meditation: Meditation

    var body: some View {
        ZStack(alignment: .leading) {
            Image(mainCategories.first(where: { $0.name == meditation.categoryName })?.imageName ?? "category_calm")
                .resizable()
                .scaledToFill()
                .frame(height: 120)
                .frame(maxWidth: .infinity)
                .cornerRadius(12)
                .clipped()

            // Overlay for better text readability
            Rectangle()
                .foregroundColor(.black)
                .opacity(0.45) // Biraz daha derinlik için opacity artırıldı
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 4) {
                Text(meditation.title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text("\(meditation.durationInMinutes) minutes")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .opacity(0.9)
            }
            .foregroundColor(.white)
            .padding(20)
        }
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}
