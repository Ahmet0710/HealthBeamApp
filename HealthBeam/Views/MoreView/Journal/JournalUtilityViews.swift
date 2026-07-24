import SwiftUI
import Combine

struct PlaceholderView: View {
    let title: String
    let icon: String
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: icon).font(.system(size: 60))
                    .foregroundColor(.customPurple.opacity(0.6))
                Text(title).font(.largeTitle).bold()
                Text("This feature is currently under development.")
                    .font(.subheadline).foregroundColor(.secondary)
            }
            .navigationTitle(title)
        }
    }
}
struct ContentAddButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 50, height: 50)
                .background(Color.customPurple.opacity(0.1))
                .foregroundColor(.customPurple)
                .clipShape(Circle())
        }
    }
}
struct JournalBottomToolbar: View {
    var onMagic: () -> Void = {}
    var onPhoto: () -> Void = {}
    var onCamera: () -> Void = {}
    var onAudio: () -> Void = {}
    var onLocation: () -> Void = {}
    var onTree: () -> Void = {}

    var body: some View {
        HStack(spacing: 21) {
            Button(action: onPhoto) {
                Image(systemName: "photo.on.rectangle").font(.title2)
            }
            Button(action: onCamera) {
                Image(systemName: "camera").font(.title2)
            }
            Button(action: onAudio) {
                Image(systemName: "waveform").font(.title2)
            }
            Button(action: onLocation) {
                Image(systemName: "location.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
        }
        .foregroundColor(.gray)
   //     .buttonStyle(.glass)
        .padding(.horizontal, 22)
        .padding(.vertical, 12)
        .background(Color(.clear).opacity(0.96))
        .clipShape(Capsule())
        .padding(.horizontal, 18)
        .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 2)
    }
}
