import SwiftUI
struct WaterLogView: View {
    var currentIntakeLiters: Double
    var goalLiters: Double
    var onLogWater: (Double) -> Void

    private var progress: Double {
        guard goalLiters > 0 else { return 0 }
        return min(currentIntakeLiters / goalLiters, 1.0)
    }
    
    private let quickAddAmounts: [Double] = [0.25, 0.50, 0.75]

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Water tracking")
                    .font(.title2.bold())
                Spacer()
                Text(String(format: "%.1f / %.1f L", currentIntakeLiters, goalLiters))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)
            }

            ProgressView()
                .tint(.blue)
                .scaleEffect(x: 1, y: 2, anchor: .center)
                .animation(.spring(), value: progress)

            HStack(spacing: 12) {
                ForEach(quickAddAmounts, id: \.self) { amount in
                    Button(action: {
                        onLogWater(amount)
                    }) {
                        Text(String(format: "+%.2f L", amount))
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue.gradient)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
