import SwiftUI

struct DownloadButton: View {
    let meditation: Meditation
    @State private var status: DownloadStatus = .unknown
    
    enum DownloadStatus {
        case unknown
        case notDownloaded // Bulut ☁️
        case downloading   // Çark ⏳
        case downloaded    // Tik ✅
    }
    
    var body: some View {
        Button(action: {
            handleAction()
        }) {
            ZStack {
                switch status {
                case .unknown, .notDownloaded:
                    Image(systemName: "icloud.and.arrow.down")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.7))
                case .downloading:
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.2)
                case .downloaded:
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }
            .frame(width: 50, height: 50)
        }
        .onAppear { checkStatus() }
        .contextMenu {
            if status == .downloaded {
                Button(role: .destructive) {
                    deleteFile()
                } label: {
                    Label("Delete download", systemImage: "trash")
                }
            }
        }
    }
    
    func checkStatus() {
        let isDownloaded = MeditationResourceManager.shared.isDownloaded(meditation: meditation)
        status = isDownloaded ? .downloaded : .notDownloaded
    }
    
    func handleAction() {
        if status == .downloaded { return }
        status = .downloading
        
        Task {
            do {
                // ✅ HATA DÜZELTİLDİ:
                // MeditationResourceManager içinde 'download' yerine 'getAudioURL'
                // kullanarak indirme işlemini tetikliyoruz.
                _ = try await MeditationResourceManager.shared.getAudioURL(
                    for: meditation,
                    categoryTag: meditation.odrTag
                )
                
                await MainActor.run {
                    withAnimation { self.status = .downloaded }
                }
            } catch {
                print("İndirme hatası: \(error)")
                await MainActor.run { self.status = .notDownloaded }
            }
        }
    }
    
    func deleteFile() {
        MeditationResourceManager.shared.removeDownload(for: meditation)
        withAnimation { status = .notDownloaded }
    }
}
