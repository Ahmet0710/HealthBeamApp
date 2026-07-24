import SwiftUI

struct MindfulnessSectionView: View {
    var body: some View {
        DiscoverView()
    }
}

struct DiscoverView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(mainCategories, id: \.id) { category in
                    NavigationLink(destination: MeditationListView(categoryName: category.name)) {
                        MainCategoryCard(category: category)
                    }
                }
            }
            .padding()
        }
        .background(
            LinearGradient(colors: [.green.opacity(0.5), .black],
                           startPoint: .top,
                           endPoint: .bottom)
            .ignoresSafeArea()
        )
    }
}

struct MainCategoryCard: View {
    let category: MainCategory
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image(category.imageName)
                .resizable()
                .scaledToFill()
                .frame(height: 120)
                .frame(maxWidth: .infinity)
                .cornerRadius(12)
                .clipped()
            Rectangle()
                .foregroundColor(.black)
                .opacity(0.4)
                .cornerRadius(12)
            Text(category.name)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding()
        }
        .frame(height: 120)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.17), radius: 6, x: 0, y: 2)
    }
}

