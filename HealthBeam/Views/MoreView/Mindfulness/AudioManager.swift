import Foundation
import AVFoundation
import Combine

@MainActor
class AudioManager: ObservableObject {
    @Published var isPlaying = false
    @Published var isLoading = false
    @Published var playbackProgress: Double = 0
    @Published var totalDuration: Double = 0
    @Published var currentMeditationID: UUID?
    @Published var currentMeditation: Meditation?
    
    private var player: AVAudioPlayer?
    private var timer: Timer?

    init() {
        setupAudioSession()
        setupDeletionObserver()
    }

    func startPlayer(meditation: Meditation) {
        self.isLoading = true
        self.currentMeditation = meditation
        self.currentMeditationID = meditation.id
        
        Task {
            do {
                let url = try await MeditationResourceManager.shared.streamingAudioURL(for: meditation)
                
                self.playAudio(url: url)
                self.isLoading = false
            } catch {
                print("Audio Loading Error: \(error)")
                self.isLoading = false
            }
        }
    }

    func downloadAndStartPlayer(meditation: Meditation) {
        self.isLoading = true
        self.currentMeditation = meditation
        self.currentMeditationID = meditation.id

        Task {
            do {
                let url = try await MeditationResourceManager.shared.getAudioURL(
                    for: meditation,
                    categoryTag: meditation.odrTag
                )

                self.playAudio(url: url)
                self.isLoading = false
            } catch {
                print("Audio Download Error: \(error)")
                self.isLoading = false
            }
        }
    }

    private func playAudio(url: URL) {
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
            
            self.totalDuration = player?.duration ?? 0
            self.isPlaying = true
            startTimer()
        } catch {
            print("Playback Error: \(error)")
        }
    }

    func playPause() {
        guard let player = player else {
            isPlaying = false
            return
        }

        if isPlaying {
            player.pause()
            timer?.invalidate()
        } else {
            player.play()
            startTimer()
        }
        isPlaying.toggle()
    }

    func stop() {
        player?.stop()
        timer?.invalidate()
        isPlaying = false
        playbackProgress = 0
    }

    func seek(by seconds: Double) {
        guard let player = player else { return }
        let newTime = player.currentTime + seconds
        player.currentTime = max(0, min(newTime, player.duration))
        playbackProgress = player.currentTime
    }

    // ✅ SÜREÇ TAKİBİ VE OTOMATİK KAYIT
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let player = self.player else { return }
                self.playbackProgress = player.currentTime
                
                // Meditasyon bittiğinde (Son 0.5 saniyeye girildiğinde)
                if player.currentTime >= player.duration - 0.5 {
                    self.saveSessionToHistory() // 1. Önce kaydet
                    self.stop()                // 2. Sonra durdur
                }
            }
        }
    }

    // ✅ HISTORY KAYIT MANTIĞI
    private func saveSessionToHistory() {
            if let meditation = currentMeditation {
                HistoryManager.shared.addSession(meditationID: meditation.id)
                print("✅ Session recorded in History: \(meditation.title)")
            }
        }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio Session Error: \(error)")
        }
    }

    private func setupDeletionObserver() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ResourceDeleted"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let deletedTag = notification.object as? String
            
            Task { @MainActor in
                guard let tag = deletedTag else { return }
                
                if self?.currentMeditation?.odrTag == tag {
                    self?.stop()
                    self?.currentMeditation = nil
                    self?.currentMeditationID = nil
                    print("🛑 Playback stopped: Content deleted.")
                }
            }
        }
    }

    deinit {
        // Timer ve NotificationCenter otomatik olarak temizlenir,
        // Swift 6'da deinit içinde actor-isolated property erişimi yasaktır.
    }
}
