import SwiftUI
import TendelmCore

/// Settings' "Support Tendelm" section: the Supporter pack row, then the
/// row that pushes ``TipJarView``. Kept apart from the Feedback section
/// so supporting Tendelm carries its own visual weight.
struct TipJarSection: View {
    var body: some View {
        Section {
            SupporterPackRow()
            NavigationLink {
                TipJarView()
            } label: {
                Label("Leave a tip", systemImage: "heart")
                    // Match the accent tint the Link rows get; a plain
                    // NavigationLink label would render primary/black.
                    .foregroundStyle(Color.kadoAccent)
            }
            .listRowBackground(Color.kadoBackgroundSecondary)
        } header: {
            Text("Support Tendelm")
                .foregroundStyle(Color.kadoForegroundSecondary)
        } footer: {
            Text("The Supporter pack is a one-time purchase for cosmetic extras. Tips unlock nothing. Everything else in Tendelm stays free.")
                .foregroundStyle(Color.kadoForegroundSecondary)
        }
    }
}

#Preview {
    NavigationStack {
        Form {
            TipJarSection()
        }
        .environment(\.tipJarStore, MockTipJarStore())
    }
}

#Preview("Dark") {
    NavigationStack {
        Form {
            TipJarSection()
        }
        .environment(\.tipJarStore, MockTipJarStore())
    }
    .preferredColorScheme(.dark)
}
