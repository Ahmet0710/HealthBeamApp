import SwiftUI

struct DownloadsManagementView: View {
    @State private var downloadedMeditations: [Meditation] = []
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Info Header
                headerView()
                
                if isLoading {
                    Spacer(); ProgressView().tint(.white); Spacer()
                } else if downloadedMeditations.isEmpty {
                    emptyDownloadsView()
                } else {
                    ScrollView {
                        VStack(spacing: 15) {
                            ForEach(downloadedMeditations) { meditation in
                                DownloadManagementCard(meditation: meditation) {
                                    deleteMeditation(meditation)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("Storage")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { refreshDownloads() }
    }
    
    private func headerView() -> some View {
        VStack(spacing: 12) {
            Image(systemName: "internaldrive.fill")
                .font(.system(size: 40))
                .foregroundColor(.cyan)
                .shadow(color: .cyan.opacity(0.5), radius: 10)
            
            Text("Offline Meditations")
                .font(.title2).bold()
                .foregroundColor(.white)
            
            Text("\(downloadedMeditations.count) files saved on device")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 30)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.03))
    }
    
    private func emptyDownloadsView() -> some View {
        VStack(spacing: 15) {
            Spacer()
            Image(systemName: "tray.and.arrow.down.fill")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.3))
            Text("Your storage is empty").foregroundColor(.gray)
            Spacer()
        }
    }

    func refreshDownloads() {
        isLoading = true
        Task {
            let found = allMeditations.filter { meditation in
                MeditationResourceManager.shared.isDownloaded(meditation: meditation)
            }
            await MainActor.run {
                self.downloadedMeditations = found
                self.isLoading = false
            }
        }
    }

    func deleteMeditation(_ meditation: Meditation) {
        MeditationResourceManager.shared.removeDownload(for: meditation)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            downloadedMeditations.removeAll { $0.id == meditation.id }
        }
    }
}

struct DownloadManagementCard: View {
    let meditation: Meditation
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(meditation.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                Text("\(meditation.durationInMinutes) min • \(meditation.categoryName)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash.fill")
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Circle().fill(Color.red.opacity(0.8)))
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.07)))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}
