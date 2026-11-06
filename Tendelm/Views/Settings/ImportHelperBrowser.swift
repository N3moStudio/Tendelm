import SafariServices
import SwiftUI

enum ImportHelperSite: String, Identifiable {
    case json, csv
    var id: String { rawValue }
    var url: URL {
        switch self {
        case .json: URL(string: "https://json.site")!
        case .csv: URL(string: "https://csvjson.com/csv2json")!
        }
    }
}

/// Mirrors Elsepin's system Safari flow. No file transfer, JavaScript bridge,
/// clipboard monitoring or automatic import; the user chooses, copies and pastes.
struct ImportHelperBrowser: UIViewControllerRepresentable {
    let site: ImportHelperSite
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(dismiss: dismiss) }

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let browser = SFSafariViewController(url: site.url)
        browser.dismissButtonStyle = .done
        browser.delegate = context.coordinator
        return browser
    }

    func updateUIViewController(_ browser: SFSafariViewController, context: Context) {
        context.coordinator.dismiss = dismiss
    }

    @MainActor final class Coordinator: NSObject, SFSafariViewControllerDelegate {
        var dismiss: DismissAction
        init(dismiss: DismissAction) { self.dismiss = dismiss }
        nonisolated func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            Task { @MainActor [weak self] in self?.dismiss() }
        }
    }
}
