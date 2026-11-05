import Testing
import SwiftUI
@testable import Tendelm
import TendelmCore

@Suite("EnvironmentValues service registration")
struct EnvironmentValuesServicesTests {
    @Test("Default habitScoreCalculator is a DefaultHabitScoreCalculator")
    func defaultCalculatorRegistered() {
        let env = EnvironmentValues()
        #expect(env.habitScoreCalculator is DefaultHabitScoreCalculator)
    }
}
