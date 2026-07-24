import SwiftUI

struct FavoritesView: View {
    @State private var favoriteMeditations: [Meditation] = []
    @State private var selectedMeditation: Meditation?

    var body: some View {
        ZStack {
            // HealthBeam 5.0 Deep Dark Background
            Color.black.ignoresSafeArea()
            LinearGradient(colors: [.green.opacity(0.2), .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea()

            VStack(alignment: .leading) {
                if favoriteMeditations.isEmpty {
                    emptyFavoritesView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(favoriteMeditations) { meditation in
                                Button(action: {
                                    selectedMeditation = meditation
                                }) {
                                    // HistoryCard ile benzer, favorilere özel kart tasarımı
                                    FavoriteMeditationCard(meditation: meditation)
                                }
                                .buttonStyle(PlainButtonStyle()) // Tıklama efektini sadeleştirir
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.large)
        .fullScreenCover(item: $selectedMeditation) { meditation in
            PlayerView(meditation: meditation)
        }
        .onAppear(perform: loadFavoriteMeditations)
    }

    // MARK: - Logic
    func loadFavoriteMeditations() {
        let favoriteIDs = FavoritesManager.shared.loadFavorites()
        // UUIDString karşılaştırması yaparak favorileri listeliyoruz
        self.favoriteMeditations = allMeditations.filter { favoriteIDs.contains($0.id.uuidString) }
    }

    // MARK: - Subviews
    private var emptyFavoritesView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "heart.slash.fill")
                .font(.system(size: 70))
                .foregroundColor(.gray.opacity(0.3))
            
            Text("Your heart is empty")
                .font(.title2).bold()
                .foregroundColor(.white)
            
            Text("To add a meditation to your Favorites, tap the heart icon on the player screen.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Favorite Card Component
struct FavoriteMeditationCard: View {
    let meditation: Meditation
    
    var body: some View {
        HStack(spacing: 16) {
            // Category Image Thumbnail
            Image(mainCategories.first(where: { $0.name == meditation.categoryName })?.imageName ?? "category_calm")
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .cornerRadius(12)
                .clipped()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(meditation.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(meditation.categoryName)
                    .font(.caption)
                    .foregroundColor(.green.opacity(0.8))
            }
            
            Spacer()
            
            Image(systemName: "play.circle.fill")
                .font(.title2)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}
