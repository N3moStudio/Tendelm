import Testing
@testable import TendelmCore

struct TipProductTests {
    @Test("Exactly three tiers, in ascending order")
    func orderedTiers() {
        #expect(TipProduct.orderedTiers == [.small, .medium, .large])
        #expect(TipProduct.allCases.count == 3)
    }

    @Test("Each tier maps to its reverse-DNS product ID")
    func productIDs() {
        #expect(TipProduct.small.productID == "com.n3mostudio.tendelm.tip.small")
        #expect(TipProduct.medium.productID == "com.n3mostudio.tendelm.tip.medium")
        #expect(TipProduct.large.productID == "com.n3mostudio.tendelm.tip.large")
    }

    @Test("allIDs lists every tier's identifier in ascending order")
    func allIDs() {
        #expect(TipProduct.allIDs == [
            "com.n3mostudio.tendelm.tip.small",
            "com.n3mostudio.tendelm.tip.medium",
            "com.n3mostudio.tendelm.tip.large",
        ])
    }

    @Test("init(productID:) round-trips every case and rejects unknowns")
    func roundTrip() {
        for tier in TipProduct.allCases {
            #expect(TipProduct(productID: tier.productID) == tier)
        }
        #expect(TipProduct(productID: "com.n3mostudio.tendelm.tip.unknown") == nil)
        #expect(TipProduct(productID: "") == nil)
    }

    @Test("Every tier has a non-empty decorative emoji")
    func emoji() {
        for tier in TipProduct.allCases {
            #expect(!tier.emoji.isEmpty)
        }
    }
}
