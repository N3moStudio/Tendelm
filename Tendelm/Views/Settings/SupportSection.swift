import SwiftUI
import TendelmCore

struct SupportSection: View {
    var body: some View {
        Section {
            Link(destination: Self.feedbackURL) {
                Label("Project & feedback", systemImage: "curlybraces")
            }
            NavigationLink {
                ScrollView {
                    Text(Self.notices).font(.footnote).textSelection(.enabled).padding()
                }.navigationTitle("Credits")
            } label: {
                Label("Credits", systemImage: "info.circle")
            }
        } header: {
            Text("About Tendelm")
                .foregroundStyle(Color.kadoForegroundSecondary)
        }
        .listRowBackground(Color.kadoBackgroundSecondary)
    }

    private static let feedbackURL = URL(
        string: "https://github.com/N3moStudio/Tendelm"
    )!
    private static let notices: String = {
        guard let url = Bundle.main.url(forResource: "OpenSourceNotices", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return "Tendelm by N3mo Studio. Based on Kadō by Sébastien Castiel (MIT). ThinkingOrbsKit by Jakub Antalík (MIT)."
        }
        return text
    }()
}

#Preview {
    Form {
        SupportSection()
    }
}

#Preview("Dark") {
    Form {
        SupportSection()
    }
    .preferredColorScheme(.dark)
}
