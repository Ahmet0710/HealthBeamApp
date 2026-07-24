import SwiftUI
struct LockedView: View {
    var onUnlock: () -> Void
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 20) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.white.opacity(0.8))
                Text("App locked")
                    .font(.title)
                    .foregroundStyle(.white)
                Button(action: onUnlock) {
                    Label("Unlock with Face ID / Touch ID", systemImage: "faceid")
                        .font(.headline)
                        .padding()
                        .frame(width: 320)
                        .background(.white.opacity(0.2))
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .padding(.horizontal, 0)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.85), Color.purple.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()
        )
    }
}
struct LockedView_Previews: PreviewProvider {
    static var previews: some View {
        LockedView(onUnlock: {
            print("Unlock button tapped!")
        })
    }
}
