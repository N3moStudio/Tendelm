import Testing
import TendelmCore

@Suite("TendelmFont")
struct TendelmFontTests {
    @Test("register() is safe to call repeatedly")
    func registerIdempotent() {
        TendelmFont.register()
        TendelmFont.register()
        TendelmFont.register()
    }
}
