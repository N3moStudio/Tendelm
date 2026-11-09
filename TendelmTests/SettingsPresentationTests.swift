import Foundation
import SwiftUI
import Testing
@testable import Tendelm

@MainActor
struct SettingsPresentationTests {
    @Test func compactOrdinaryTypeLeavesAccessibilityUnchanged() {
        #expect(SettingsTypography.compact(.xSmall) == .xSmall)
        #expect(SettingsTypography.compact(.large) == .medium)
        #expect(SettingsTypography.compact(.xxxLarge) == .xxLarge)
        for size in [DynamicTypeSize.accessibility1, .accessibility2, .accessibility3, .accessibility4, .accessibility5] {
            #expect(SettingsTypography.compact(size) == size)
        }
    }

}
