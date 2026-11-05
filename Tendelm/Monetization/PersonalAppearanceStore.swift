import Observation

/// This MIT-based personal fork includes the source palettes locally and has
/// no App Store products. It never queries or impersonates an upstream purchase.
@MainActor @Observable
final class PersonalAppearanceStore: SupporterPackStoring {
    var isSupporter: Bool { true }
    var offerState: SupporterOfferState { .failed }
    func refreshEntitlement() async {}
    func loadOffer() async {}
    func purchase() async -> SupporterPurchaseOutcome { .cancelled }
    func restore() async -> SupporterRestoreOutcome { .nothingToRestore }
}
