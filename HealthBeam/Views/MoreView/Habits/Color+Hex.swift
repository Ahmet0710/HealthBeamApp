import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

extension Color {
    func toHex() -> String? {
        #if canImport(UIKit)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let r = Int(red * 255)
        let g = Int(green * 255)
        let b = Int(blue * 255)
        let clampedR = min(255, max(0, r))
        let clampedG = min(255, max(0, g))
        let clampedB = min(255, max(0, b))
        return String(format: "#%02X%02X%02X", clampedR, clampedG, clampedB)
        #elseif canImport(AppKit)
        let nsColor = NSColor(self)
        guard let rgbColor = nsColor.usingColorSpace(.deviceRGB) else { return nil }
        let r = Int(rgbColor.redComponent * 255)
        let g = Int(rgbColor.greenComponent * 255)
        let b = Int(rgbColor.blueComponent * 255)

        let clampedR = min(255, max(0, r))
        let clampedG = min(255, max(0, g))
        let clampedB = min(255, max(0, b))

        return String(format: "#%02X%02X%02X", clampedR, clampedG, clampedB)
        #else
        return nil
        #endif
    }

    init?(hex: String) {
        var hexString = hex
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }
        if hexString.count == 3 {
            hexString = hexString.map { "\($0)\($0)" }.joined()
        }
        guard hexString.count == 6,
              let intCode = Int(hexString, radix: 16) else {
            return nil
        }
        let r = Double((intCode >> 16) & 0xFF) / 255.0
        let g = Double((intCode >> 8) & 0xFF) / 255.0
        let b = Double(intCode & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
