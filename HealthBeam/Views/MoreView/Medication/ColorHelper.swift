import SwiftUI
extension String {
    // Hex String'i Color'a çevirir (Örn: "#FF0000" -> Color.red)
    func toColor() -> Color {
        var cString:String = self.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.count) != 6) {
            return Color.blue // Hata durumunda varsayılan renk
        }

        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        return Color(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0
        )
    }
}
extension Medication {
    // Veritabanındaki Hex kodunu renge çevirir
    var themeColor: Color {
        if let hex = self.colorHex {
            return hex.toColor()
        }
        return .blue // Varsayılan
    }
}
