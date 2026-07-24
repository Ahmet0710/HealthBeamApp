import SwiftUI

struct PremiumHeaderView: View {
    let unlockedCount: Int
    let totalCount: Int
    let progress: Double
    
    @State private var animatedProgress: Double = 0
    
    // KÖŞE YARIÇAPI (Daha yumuşak ve modern)
    private let headerCornerRadius: CGFloat = 32.0
    
    var body: some View {
        ZStack {
            // Arka Plan
            RoundedRectangle(cornerRadius: headerCornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 25/255, green: 25/255, blue: 35/255), Color.black],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: headerCornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.4), radius: 15, x: 0, y: 10)
            
            HStack(spacing: 24) {
                // Sol: Animasyonlu Halka
                ZStack {
                    // Gölge Halka
                    Circle()
                        .stroke(Color.white.opacity(0.05), lineWidth: 12)
                        .frame(width: 85, height: 85)
                    
                    // Dolgu Halka
                    Circle()
                        .trim(from: 0, to: animatedProgress)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [.purple, .blue, .cyan, .purple]),
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 85, height: 85)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: .blue.opacity(0.5), radius: 8)
                    
                    VStack(spacing: 0) {
                        Text("\(Int(progress * 100))")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                        Text("%")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.gray)
                    }
                }
                
                // Sağ: İstatistikler
                    VStack(alignment: .leading, spacing: 6) {
                    Text("Total Achievements")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.gray)
                        .textCase(.uppercase)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(unlockedCount)")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("/ \(totalCount)")
                            .font(.title3.weight(.medium))
                            .foregroundColor(.gray.opacity(0.7))
                    }
                    
                    Text(quoteForProgress(progress))
                        .font(.footnote)
                        .foregroundColor(Color(red: 200/255, green: 200/255, blue: 255/255))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
            .padding(24)
        }
        .frame(height: 140)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { oldValue, newValue in
            withAnimation(.easeInOut(duration: 1.2)) {
                animatedProgress = newValue
            }
        }
    }
    
    func quoteForProgress(_ val: Double) -> String {
        if val < 0.1 { return String(localized: "Start your journey today! 🚀") }
        if val < 0.5 { return String(localized: "Great momentum! Keep going. 🔥") }
        if val < 0.9 { return String(localized: "So close to greatness! ⚡️") }
        return String(localized: "You are a legend! 🏆")
    }
}
struct ModernFilterBar: View {
    @Binding var selectedFilter: AchievementFilter
    @Namespace private var ns
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(AchievementFilter.allCases) { filter in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedFilter = filter
                    }
                } label: {
                    ZStack {
                        if selectedFilter == filter {
                            // Tamamen yuvarlak kapsül
                            Capsule()
                                .fill(Color.white.opacity(0.15))
                                .matchedGeometryEffect(id: "bg", in: ns)
                        }
                        Text(filter.localizedTitle)
                            .font(.system(size: 14, weight: selectedFilter == filter ? .bold : .medium))
                            .foregroundColor(selectedFilter == filter ? .white : .gray)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        // Arka plan da tam yuvarlak kapsül
        .background(Color.black.opacity(0.3), in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
    }
}
struct AchievementsViews: View {
    @EnvironmentObject var viewModel: AchievementsViewModel
    @State private var selectedAchievement: Achievement?
    
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        ScrollViewReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 10/255, green: 12/255, blue: 25/255),
                        Color(red: 20/255, green: 15/255, blue: 40/255),
                        Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 1. Header
                        PremiumHeaderView(
                            unlockedCount: viewModel.unlockedCount,
                            totalCount: viewModel.totalCount,
                            progress: viewModel.overallProgress
                        )
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        // 2. Filtre & Sıralama
                        VStack(spacing: 12) {
                            ModernFilterBar(selectedFilter: $viewModel.activeFilter)
                                .padding(.horizontal)
                            
                            HStack {
                                Spacer()
                                Menu {
                                    ForEach(AchievementSort.allCases) { sort in
                                        Button {
                                            withAnimation { viewModel.activeSort = sort }
                                        } label: {
                                            Label(sort.localizedTitle, systemImage: viewModel.activeSort == sort ? "checkmark" : "")
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Text(String(localized: "Sort: \(viewModel.activeSort.localizedTitle)"))
                                            .font(.caption.weight(.semibold))
                                        Image(systemName: "arrow.up.arrow.down")
                                            .font(.caption)
                                    }
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(.ultraThinMaterial)
                                    // Sıralama butonu da kapsül
                                    .clipShape(Capsule())
                                    .foregroundColor(.white.opacity(0.8))
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // 3. Kategoriler ve Kartlar
                        ForEach(AchievementCategory.allCases) { category in
                            let achievementsToShow = viewModel.displayAchievements.filter { $0.category == category }
                            
                            if !achievementsToShow.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    // Kategori Başlığı
                                    HStack {
                                        // Renkli Kapsül İndikatör
                                        Capsule()
                                            .fill(category.color)
                                            .frame(width: 4, height: 18)
                                        
                                        Text(category.localizedTitle)
                                            .font(.title3.bold())
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        // Sayaç (Köşeleri yumuşatıldı)
                                        let stats = viewModel.progressFor(category: category)
                                        Text("\(stats.unlocked)/\(stats.total)")
                                            .font(.caption.bold())
                                            .foregroundColor(.gray)
                                            .padding(6)
                                            .background(Color.white.opacity(0.08))
                                            // Daha yumuşak köşe
                                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    }
                                    .padding(.horizontal)
                                    
                                    // Grid
                                    LazyVGrid(columns: columns, spacing: 20) {
                                        ForEach(achievementsToShow, id: \.id) { achievement in
                                            AchievementCardViews(achievement: achievement)
                                                .onTapGesture {
                                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                                    impact.impactOccurred()
                                                    self.selectedAchievement = achievement
                                                }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                .padding(.bottom, 10)
                            }
                        }
                        
                        Spacer().frame(height: 50)
                    }
                }
            }
        }
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .searchable(text: $viewModel.searchText, prompt: "Search...")
        .sheet(item: $selectedAchievement) { achievement in
            AchievementDetailView(achievement: achievement)
        }
    }
}
