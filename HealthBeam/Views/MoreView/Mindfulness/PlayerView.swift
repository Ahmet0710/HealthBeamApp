import SwiftUI

struct PlayerView: View {
    let meditation: Meditation
    
    @EnvironmentObject var audioManager: AudioManager
    @Environment(\.dismiss) var dismiss
    
    // UI State Management
    @State private var showDownloadAlert = false
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let playPauseButtonSize: CGFloat = screenWidth > 400 ? 90 : 75

            ZStack {
                // --- 1. BACKGROUND ---
                Image(mainCategories.first(where: { $0.name == meditation.categoryName })?.imageName ?? "category_calm")
                    .resizable()
                    .scaledToFill()
                    .frame(width: screenWidth, height: geometry.size.height)
                    .clipped()
                    .blur(radius: 10)
                    .ignoresSafeArea()

                Color.black.opacity(0.55).ignoresSafeArea()

                // --- 2. MAIN INTERFACE ---
                VStack(spacing: 20) {
                    // TOP TOOLBAR
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.down")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Circle().fill(Color.black.opacity(0.3)))
                        }
                        
                        Spacer()
                        
                        // ✅ FAVORITE BUTTON (Hatalar Düzeltildi)
                        Button(action: {
                            FavoritesManager.shared.toggleFavorite(meditationID: meditation.id)
                        }) {
                            Image(systemName: FavoritesManager.shared.isFavorite(meditationID: meditation.id) ? "heart.fill" : "heart")
                                .font(.title2)
                                .foregroundColor(FavoritesManager.shared.isFavorite(meditationID: meditation.id) ? .red : .white)
                                .padding(12)
                                .background(Circle().fill(Color.black.opacity(0.3)))
                                .shadow(color: FavoritesManager.shared.isFavorite(meditationID: meditation.id) ? .red.opacity(0.4) : .clear, radius: 10)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    Spacer()

                    // CONTENT INFO
                    VStack(spacing: 12) {
                        Text(meditation.title)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                        
                        Text(meditation.categoryName)
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.7))
                            .tracking(1.2)
                    }
                    .padding(.horizontal)

                    Spacer()

                    // CIRCULAR PROGRESS
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 6)
                            .foregroundColor(.white.opacity(0.15))

                        Circle()
                            .trim(from: 0.0, to: min(audioManager.totalDuration > 0 ? audioManager.playbackProgress / audioManager.totalDuration : 0.0, 1.0))
                            .stroke(style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .foregroundColor(.white)
                            .rotationEffect(Angle(degrees: 270.0))
                            .animation(.linear, value: audioManager.playbackProgress)

                        VStack(spacing: 4) {
                            Text(formatTime(audioManager.playbackProgress))
                                .font(.system(size: 48, weight: .light, design: .monospaced))
                                .bold()
                            Text("REMAINING").font(.caption2).tracking(2).opacity(0.6)
                        }
                        .foregroundColor(.white)
                    }
                    .frame(width: 260, height: 260)

                    Spacer()

                    // CONTROLS
                    HStack(spacing: 45) {
                        Button(action: { audioManager.seek(by: -15) }) {
                            Image(systemName: "gobackward.15").font(.system(size: 28))
                        }

                        if audioManager.isLoading {
                            ProgressView().tint(.white).scaleEffect(1.5)
                        } else {
                            Button(action: { audioManager.playPause() }) {
                                Image(systemName: audioManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .resizable()
                                    .frame(width: playPauseButtonSize, height: playPauseButtonSize)
                            }
                        }

                        Button(action: { audioManager.seek(by: 15) }) {
                            Image(systemName: "goforward.15").font(.system(size: 28))
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.bottom, 50)
                }
                .opacity(showDownloadAlert ? 0.2 : 1.0)
                
                // --- 3. DOWNLOAD OVERLAY ---
                if showDownloadAlert {
                    downloadOverlayView
                }
            }
        }
        .onAppear { checkAndStart() }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ResourceDeleted"))) { notification in
            if let deletedTag = notification.object as? String, meditation.odrTag == deletedTag {
                dismiss()
            }
        }
    }

    private var downloadOverlayView: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            VStack(spacing: 25) {
                Image(systemName: "icloud.and.arrow.down").font(.system(size: 50)).foregroundColor(.blue)
                VStack(spacing: 12) {
                    Text("Download Meditation?").font(.title3).bold()
                    Text("This session needs to be downloaded to your device.").font(.subheadline).multilineTextAlignment(.center).foregroundColor(.secondary)
                }
                VStack(spacing: 10) {
                    Button(action: {
                        showDownloadAlert = false
                        audioManager.downloadAndStartPlayer(meditation: meditation)
                    }) {
                        Text("Download and Start").fontWeight(.bold).foregroundColor(.white).frame(maxWidth: .infinity).padding().background(Color.blue).cornerRadius(15)
                    }
                    Button(action: { dismiss() }) { Text("Not Now").foregroundColor(.white.opacity(0.7)).padding() }
                }
            }
            .padding(30).background(RoundedRectangle(cornerRadius: 30).fill(Color(UIColor.secondarySystemBackground))).padding(40)
        }
    }

    private func checkAndStart() {
        let isDownloaded = MeditationResourceManager.shared.isDownloaded(meditation: meditation)

        if isDownloaded {
            showDownloadAlert = false
            audioManager.startPlayer(meditation: meditation)
        } else {
            showDownloadAlert = true
        }
    }

    private func formatTime(_ time: Double) -> String {
        let safeTime = time.isNaN || time.isInfinite ? 0 : time
        let minutes = Int(safeTime) / 60
        let seconds = Int(safeTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
