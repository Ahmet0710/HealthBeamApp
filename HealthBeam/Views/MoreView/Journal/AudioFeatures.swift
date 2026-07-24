import SwiftUI
import AVFoundation
import Combine
struct AudioThumbnailView: View {
    let audioURL: URL
    let duration: TimeInterval
    @StateObject var audioPlayer = AudioPlayer()

    var body: some View {
        HStack(spacing: 15) {
            Button(action: { audioPlayer.togglePlayback(from: audioURL) }) {
                Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title3)
                    .frame(width: 44, height: 44)
                    .background(Color.customPurple.opacity(0.2))
                    .foregroundColor(.customPurple)
                    .clipShape(Circle())
            }

            VStack(alignment: .leading) {
                Text("Audio Recording").font(.headline)
                Text(duration.toTimeString()).font(.subheadline).foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(12)
        .onDisappear {
            audioPlayer.stop()
        }
    }
}
@MainActor
class AudioPlayer: ObservableObject {
    @Published var isPlaying = false
    private var audioPlayer: AVAudioPlayer?

    func togglePlayback(from url: URL) {
        if audioPlayer?.isPlaying == true {
            audioPlayer?.pause()
            isPlaying = false
        } else {
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.play()
                isPlaying = true
            } catch {
                print("Audio playback failed: \(error.localizedDescription)")
            }
        }
    }

    func stop() {
        audioPlayer?.stop()
        isPlaying = false
    }
}
struct AudioRecorderView: View {
    @Environment(\.dismiss) var dismiss
    var onAudioRecorded: (URL, TimeInterval) -> Void
    @StateObject var audioRecorder = AudioRecorderService()

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            VStack(spacing: 40) {
                Spacer()
                Text(audioRecorder.statusText)
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.7))

                Text(audioRecorder.recordingTime.toTimeString())
                    .font(.system(size: 60, weight: .light, design: .monospaced))
                    .foregroundColor(.white)

                visualizerView
                    .frame(height: 100)

                Spacer()

                controlsView

                Spacer()
            }
            .padding()
        }
        .onAppear(perform: audioRecorder.checkMicrophonePermission)
        .onDisappear(perform: audioRecorder.stopAndDiscardRecording)
    }

    @ViewBuilder var visualizerView: some View {
        HStack(spacing: 4) {
            ForEach(0..<15) { _ in
                RoundedRectangle(cornerRadius: 2)
                    .frame(width: 4, height: .random(in: 5...100) * audioRecorder.audioLevel)
                    .foregroundColor(.white)
            }
        }
        .animation(.easeOut(duration: 0.1), value: audioRecorder.audioLevel)
    }

    @ViewBuilder var controlsView: some View {
        HStack(spacing: 30) {
            if audioRecorder.isRecording {
                Button(action: audioRecorder.stopRecording) {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 70))
                        .foregroundColor(.red)
                }
            } else {
                if audioRecorder.recordedURL != nil {
                    Button(action: audioRecorder.resetRecording) {
                        Image(systemName: "trash.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Button(action: audioRecorder.togglePlayback) {
                        Image(systemName: audioRecorder.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.white)
                    }
                    Button(action: {
                        if let url = audioRecorder.recordedURL {
                            onAudioRecorded(url, audioRecorder.recordingTime)
                            dismiss()
                        }
                    }) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                    }
                } else {
                    Button(action: audioRecorder.startRecording) {
                        Image(systemName: "mic.circle.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
}
@MainActor
class AudioRecorderService: NSObject, ObservableObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var recordingTime: TimeInterval = 0
    @Published var audioLevel: CGFloat = 0.0
    @Published var statusText = "Start Recording"

    var recordedURL: URL?
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var cancellable: AnyCancellable?

    func checkMicrophonePermission() {
        if #available(iOS 17.0, *) {
            if AVAudioApplication.shared.recordPermission == .undetermined {
                AVAudioApplication.requestRecordPermission { _ in }
            }
        } else {
            if AVAudioSession.sharedInstance().recordPermission == .undetermined {
                AVAudioSession.sharedInstance().requestRecordPermission { _ in }
            }
        }
    }

    func startRecording() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("m4a")
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()

            isRecording = true
            statusText = "Recording..."
            cancellable = Timer.publish(every: 0.05, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    self?.updateMeters()
                }
        } catch {
            statusText = "Failed to start recording"
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        cancellable?.cancel()
        cancellable = nil
        isRecording = false
        recordedURL = audioRecorder?.url
        statusText = "Recording Stopped"
    }

    func resetRecording() {
        stopAndDiscardRecording()
        recordedURL = nil
        recordingTime = 0
        audioLevel = 0.0
        statusText = "Start Recording"
    }

    func stopAndDiscardRecording() {
        if isRecording {
            audioRecorder?.stop()
            audioRecorder?.deleteRecording()
        }
        cancellable?.cancel()
        cancellable = nil
        isRecording = false
    }

    func updateMeters() {
        guard let recorder = audioRecorder else { return }
        recorder.updateMeters()
        recordingTime = recorder.currentTime
        let power = recorder.averagePower(forChannel: 0)
        self.audioLevel = CGFloat(max(0, (power + 60) / 60))
    }

    func togglePlayback() {
        guard let url = recordedURL else { return }
        if isPlaying {
            audioPlayer?.pause()
            isPlaying = false
        } else {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.delegate = self
                audioPlayer?.play()
                isPlaying = true
            } catch {
                print("Playback error")
            }
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
    }
}
