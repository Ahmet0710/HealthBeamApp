import SwiftUI
public struct NutritionInfoView: View {
    public let value: Int
    public let label: String
    public var color: Color
    public init(value: Int, label: String, color: Color = .primary) {
        self.value = value
        self.label = label
        self.color = color
    }
    public var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
        }
        .frame(minWidth: 30)
    }
}
struct NutritionInfoView_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 16) {
            NutritionInfoView(value: 200, label: "Cal")
            NutritionInfoView(value: 20, label: "P", color: .red)
            NutritionInfoView(value: 30, label: "C", color: .green)
            NutritionInfoView(value: 10, label: "F", color: .yellow)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
