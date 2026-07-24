import SwiftUI

struct BloodPressureValueText: View {

    let systolic: Double
    let diastolic: Double

    private let valueFont = Font.system(size: 20, weight: .semibold)

    var body: some View {
        // Metin boyutu kadar yer kaplar, gradient rengini alır.
        Text("\(Int(systolic))/\(Int(diastolic)) mmHg")
            .font(valueFont)
            .foregroundStyle(
                LinearGradient(
                    colors: [.red, .blue],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: 28)
    }
}
