import UIKit

/// Existing semantic colors resolve through these palettes. No mutable global
/// theme or navigation identity is needed. Tendelm retains its original values.
enum AppPalette {
    enum Role: Int {
        case paper50, paper100, paper200, paper300
        case ink900, ink700, ink500, ink300, ink100
        case sage100, sage300, sage500, sage, sage900
    }

    static func color(_ role: Role, theme: HabitTheme, dark: Bool) -> UIColor? {
        let colors: [UInt32]
        switch (theme.current, dark) {
        case (.muted, false):
            colors = [0xF4F0F5, 0xE9E1ED, 0xD9CEDF, 0xC5B7CD,
                      0x2C2532, 0x493D50, 0x67596F, 0x84728D, 0xB5A6BE,
                      0xE4D7EB, 0xBEA6CC, 0x8A6B9A, 0x705081, 0x4F365D]
        case (.muted, true):
            colors = [0x19151E, 0x282130, 0x3B3045, 0x55475F,
                      0xF2EAF7, 0xDDD0E7, 0xBFB0CA, 0x9F8DAD, 0x655371,
                      0x382940, 0x654A74, 0xA88BBC, 0xCFADDF, 0xE4CEEF]
        case (.autumn, false):
            colors = [0xFBF1E5, 0xF2E0CC, 0xE2C7A9, 0xCFAC87,
                      0x35261F, 0x574034, 0x765340, 0x94705B, 0xBB9A80,
                      0xF0D3BF, 0xD9A180, 0xAF6B47, 0x92492C, 0x69341F]
        case (.autumn, true):
            colors = [0x211710, 0x322218, 0x483021, 0x63422E,
                      0xFAEDDF, 0xEAD3BC, 0xCEAF91, 0xB29071, 0x77573C,
                      0x4C2E1E, 0x845235, 0xCE9367, 0xECB58C, 0xF8D9BC]
        case (.monochromeSage, false):
            colors = [0xEDF4ED, 0xDCE9DC, 0xC4D8C5, 0xA7C2AB,
                      0x203328, 0x354D3D, 0x4D6857, 0x6F8A77, 0x98B29F,
                      0xD0E3D4, 0x99BCA3, 0x5D896B, 0x326345, 0x244932]
        case (.monochromeSage, true):
            colors = [0x111E17, 0x1C2F23, 0x294333, 0x3B5945,
                      0xEAF4E9, 0xCBDFCE, 0xAAC7AF, 0x88AA92, 0x4E7158,
                      0x223F2B, 0x3F6B4B, 0x78A789, 0xA0D1AD, 0xC8E5CB]
        default:
            return nil
        }
        let hex = colors[role.rawValue]
        return UIColor(red: CGFloat((hex >> 16) & 255) / 255,
                       green: CGFloat((hex >> 8) & 255) / 255,
                       blue: CGFloat(hex & 255) / 255, alpha: 1)
    }
}
