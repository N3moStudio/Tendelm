import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import TendelmCore

/// Settings section that wires the JSON round-trip: export the full
/// store as a `.json` file via the share sheet, import a file or pasted
/// contents through the same review. Presentations attach to the complete Form,
/// not to a Section whose rows can be recycled while scrolling.
struct BackupSettingsContainer<Content: View>: View {
    private let content: (AnyView) -> Content

    init(@ViewBuilder content: @escaping (AnyView) -> Content) {
        self.content = content
    }
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.modelContext) private var modelContext
    @Environment(\.backupExporter) private var exporter
    @Environment(\.backupImporter) private var importer

    @AppStorage("lastExportAt") private var lastExportAt: Double = 0

    @State private var isShowingImporter = false
    @State private var isExporting = false
    @State private var exportTask: Task<Void, Never>?

    // One slot each for the presented sheet and alert. The states are
    // mutually exclusive, and stacking a modifier per case (this view
    // was up to two sheets and three alerts) is how presentation stacks
    // start dropping presentations — see the PR #16 compound.
    @State private var presentedSheet: PresentedSheet?
    @State private var presentedAlert: PresentedAlert?

    var body: some View {
        // This is one fixed section; erasure lets the caller compose its Form.
        content(AnyView(section))
        .onDisappear { exportTask?.cancel() }
        .fileImporter(
            isPresented: $isShowingImporter,
            allowedContentTypes: [.json, .commaSeparatedText]
        ) { result in
            handleFileImport(result)
        }
        .sheet(item: $presentedSheet) { sheet in
            switch sheet {
            case .helper(let site):
                ImportHelperBrowser(site: site)
            case .share(let url):
                ShareSheet(activityItems: [url])
                    .ignoresSafeArea()
            case .confirmImport(let document, let summary):
                ImportConfirmSheet(
                    summary: summary,
                    onCancel: { presentedSheet = nil },
                    onConfirm: { commitImport(document) }
                )
            }
        }
        .alert(
            presentedAlert?.title ?? "",
            isPresented: Binding(
                get: { presentedAlert != nil },
                set: { if !$0 { presentedAlert = nil } }
            ),
            presenting: presentedAlert
        ) { _ in
            Button("OK", role: .cancel) { presentedAlert = nil }
        } message: { alert in
            alert.message
        }
    }

    private var section: some View {
        Group {
            Section {
                Button { isShowingImporter = true } label: {
                    SettingsRow(title: "Choose backup file", symbol: "doc")
                }
                .disabled(isExporting || presentedSheet != nil || isShowingImporter)
                .accessibilityIdentifier("backup.importFile")
                let pasteLayout = typeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
                    : AnyLayout(HStackLayout(spacing: 12))
                pasteLayout {
                    SettingsRow(title: "Paste backup text", symbol: "doc.on.clipboard")
                    if !typeSize.isAccessibilitySize { Spacer(minLength: 8) }
                    PasteButton(payloadType: String.self, onPaste: handlePastedText)
                        .labelStyle(.titleOnly)
                        .accessibilityLabel("Paste backup text")
                        .accessibilityIdentifier("backup.paste")
                        .disabled(isExporting || presentedSheet != nil || isShowingImporter)
                }.frame(minHeight: 44)
            } header: { Text("Import a backup") }
            footer: {
                Text("Open [json.site](https://json.site), copy the JSON, then tap Done and Paste here.")
                    .environment(\.openURL, OpenURLAction { url in
                        guard url == ImportHelperSite.json.url else { return .systemAction }
                        guard !isExporting, presentedSheet == nil, !isShowingImporter else { return .handled }
                        presentedSheet = .helper(.json)
                        return .handled
                    })
            }
            .listRowBackground(Color.kadoBackgroundSecondary)
            Section {
                Menu {
                    Button("JSON", systemImage: "curlybraces") { performExport(format: .json) }
                    Button("CSV", systemImage: "tablecells") { performExport(format: .csv) }
                } label: { SettingsRow(title: "Export backup", symbol: "square.and.arrow.up") }
                    .disabled(isExporting || presentedSheet != nil)
                if isExporting { TendelmProgressLabel(title: "Preparing backup…") }
                if lastExportAt > 0 {
                    Text("Last export: \(lastExportDisplay)").font(.footnote).foregroundStyle(Color.kadoForegroundSecondary)
                }
            } header: { Text("Export a backup") }
            footer: { Text("Save your habits, daily history and time-since trackers together.") }
            .listRowBackground(Color.kadoBackgroundSecondary)
            Section {
                NavigationLink { ExternalImportView() } label: {
                    SettingsRow(title: "Import from another app", symbol: "arrow.down.doc")
                }.accessibilityIdentifier("externalImport.open")
            } header: { Text("From another app") }
            footer: { Text("Bring daily history from Streaks, Habitify or a simple CSV.") }
            .listRowBackground(Color.kadoBackgroundSecondary)
            Section {
                DisclosureGroup("What's in a backup?") {
                    Text("Backups include active and archived habits, their daily entries, and time-since trackers with reset history. Recently Deleted and appearance settings stay on this device.")
                    Text("Import merges by identity. Matching records are updated; other saved items stay. To start completely fresh, use Privacy & reset → Erase all data first.")
                }.font(.subheadline)
            }.listRowBackground(Color.kadoBackgroundSecondary)
        }
    }

    // MARK: - Export

    private var lastExportDisplay: String {
        let date = Date(timeIntervalSince1970: lastExportAt)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func performExport(format: BackupFormat) {
        guard !isExporting else { return }
        isExporting = true
        exportTask = Task {
            defer { isExporting = false }
            do {
                let document = try exporter.export(from: modelContext)
                let filename = "tendelm-backup-\(Self.filenameDate(from: .now)).\(format.fileExtension)"
                let url = try await BackupFileWriter.write(document, format: format, filename: filename)
                try Task.checkCancellation()
                lastExportAt = Date.now.timeIntervalSince1970
                presentedSheet = .share(url)
            } catch is CancellationError {
                return
            } catch {
                presentedAlert = .exportFailed(error.localizedDescription)
            }
        }
    }

    /// `en_US_POSIX` so the filename stays `YYYY-MM-DD` across every
    /// user locale (e.g. a device set to `fr_FR` would otherwise emit
    /// `18/04/2026`, which breaks as a filename on some targets).
    static func filenameDate(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: date)
    }

    // MARK: - Import

    private func handlePastedText(_ strings: [String]) {
        guard !isExporting, presentedSheet == nil, !isShowingImporter else { return }
        do {
            let data = try ImportTextInput.data(from: strings)
            prepareImport(data, format: BackupFormat.sniff(data))
        } catch { presentedAlert = .pasteFailed(error.localizedDescription) }
    }

    private func prepareImport(_ data: Data, format: BackupFormat) {
        do {
            let document: BackupDocument
            switch format {
            case .json: document = try importer.parse(data: data)
            case .csv: document = try CSVBackupCoder().decode(data)
            }
            let summary = try importer.summary(for: document, in: modelContext)
            presentedSheet = .confirmImport(document: document, summary: summary)
        } catch BackupError.invalidJSON { presentedAlert = .importFailed(.invalidJSON) }
        catch BackupError.invalidCSV { presentedAlert = .importFailed(.invalidCSV) }
        catch BackupError.malformedRow(let line) { presentedAlert = .importFailed(.malformedRow(line: line)) }
        catch BackupError.unsupportedVersion { presentedAlert = .importFailed(.unsupportedVersion) }
        catch { presentedAlert = .importFailed(.readFailed) }
    }

    private func handleFileImport(_ result: Result<URL, Error>) {
        switch result {
        case .failure:
            presentedAlert = .importFailed(.readFailed)
        case .success(let url):
            let didStartAccess = url.startAccessingSecurityScopedResource()
            defer { if didStartAccess { url.stopAccessingSecurityScopedResource() } }

            let data: Data
            do {
                data = try Data(contentsOf: url)
            } catch {
                presentedAlert = .importFailed(.readFailed)
                return
            }

            // The extension is a hint — some file providers rename on
            // export — so fall back to sniffing the contents.
            let format = BackupFormat.detect(pathExtension: url.pathExtension)
                ?? BackupFormat.sniff(data)

            prepareImport(data, format: format)
        }
    }

    private func commitImport(_ document: BackupDocument) {
        do {
            let summary = try importer.apply(document, to: modelContext)
            presentedSheet = nil
            WidgetReloader.reloadAll(using: modelContext)
            presentedAlert = .importSucceeded(summary)
        } catch {
            presentedSheet = nil
            presentedAlert = .importFailed(.readFailed)
        }
    }
}

// MARK: - Confirmation sheet

private struct ImportConfirmSheet: View {
    let summary: ImportSummary
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    labelRow(
                        title: "Habits",
                        total: summary.totalHabits,
                        new: summary.newHabits,
                        updated: summary.updatedHabits
                    )
                    labelRow(
                        title: "Completions",
                        total: summary.totalCompletions,
                        new: summary.newCompletions,
                        updated: summary.updatedCompletions
                    )
                } footer: {
                    Text("Habits and completions merge by ID. Matching time-since trackers restore the backup's start date and reset history. Other trackers stay unchanged.")
                }
                if summary.totalTrackers > 0 {
                    Section {
                        labelRow(title: "Time since", total: summary.totalTrackers, new: summary.newTrackers, updated: summary.updatedTrackers)
                    }
                }
            }
            .navigationTitle("Review backup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                        .accessibilityIdentifier("backup.review.cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import", action: onConfirm)
                        .accessibilityIdentifier("backup.review.confirm")
                }
            }
        }
    }

    @ViewBuilder
    private func labelRow(title: LocalizedStringKey, total: Int, new: Int, updated: Int) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(total) (\(new) new, \(updated) updated)")
                .foregroundStyle(Color.kadoForegroundSecondary)
                .monospacedDigit()
        }
    }
}

// MARK: - Presentation state

/// Every sheet this section can present, in one slot.
private enum PresentedSheet: Identifiable {
    case helper(ImportHelperSite)
    case share(URL)
    case confirmImport(document: BackupDocument, summary: ImportSummary)

    var id: String {
        switch self {
        case .helper(let site): return "helper-\(site.rawValue)"
        case .share(let url): return "share-\(url.absoluteString)"
        case .confirmImport: return "confirmImport"
        }
    }
}

/// Every alert this section can present, in one slot.
private enum PresentedAlert: Identifiable {
    case pasteFailed(String)
    case exportFailed(String)
    case importFailed(ImportFailure)
    case importSucceeded(ImportSummary)

    var id: String {
        switch self {
        case .pasteFailed: return "pasteFailed"
        case .exportFailed: return "exportFailed"
        case .importFailed(let failure): return "importFailed-\(failure.id)"
        case .importSucceeded: return "importSucceeded"
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .pasteFailed: return "Couldn't read pasted text"
        case .exportFailed: return "Export failed"
        case .importFailed(let failure): return failure.title
        case .importSucceeded: return "Import complete"
        }
    }

    /// Returns `Text` rather than `LocalizedStringKey` so the dynamic
    /// export-error description reaches the non-localizing initializer
    /// while the fixed strings stay on the localized path.
    var message: Text {
        switch self {
        case .pasteFailed(let message): return Text(message)
        case .exportFailed(let description):
            return Text(description)
        case .importFailed(let failure):
            return Text(failure.message)
        case .importSucceeded(let summary):
            return Text("Time-since trackers: \(summary.totalTrackers)\nHabits: \(summary.totalHabits) (\(summary.newHabits) new, \(summary.updatedHabits) updated)\nCompletions: \(summary.totalCompletions) (\(summary.newCompletions) new, \(summary.updatedCompletions) updated)")
        }
    }
}

/// Why an import couldn't proceed.
private enum ImportFailure {
    case invalidJSON
    case invalidCSV
    case malformedRow(line: Int)
    case unsupportedVersion
    case readFailed

    var id: String {
        switch self {
        case .invalidJSON: return "invalidJSON"
        case .invalidCSV: return "invalidCSV"
        case .malformedRow(let line): return "malformedRow-\(line)"
        case .unsupportedVersion: return "unsupportedVersion"
        case .readFailed: return "readFailed"
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .invalidJSON: return "Not a Tendelm backup"
        case .invalidCSV: return "Not a Tendelm CSV export"
        case .malformedRow: return "Malformed row"
        case .unsupportedVersion: return "Newer Tendelm version"
        case .readFailed: return "Couldn't read file"
        }
    }

    var message: LocalizedStringKey {
        switch self {
        case .invalidJSON:
            return "The file couldn't be decoded as a Tendelm backup."
        case .invalidCSV:
            return "The file couldn't be read as a Tendelm CSV export. Check that its header row is intact."
        case .malformedRow(let line):
            return "Line \(line) doesn't have the expected number of columns."
        case .unsupportedVersion:
            return "This backup was created by a newer Tendelm version. Update Tendelm to import."
        case .readFailed:
            return "The file couldn't be read. Try a different file."
        }
    }
}

// MARK: - UIActivityViewController bridge

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Previews

#Preview("Never exported") {
    BackupSettingsContainer { section in Form { section } }
}

#Preview("Previously exported") {
    BackupSettingsContainer { section in Form { section } }
        .defaultAppStorage(.preview(lastExportAt: Date.now.timeIntervalSince1970 - 86_400))
}

#Preview("Dark") {
    BackupSettingsContainer { section in Form { section } }
        .defaultAppStorage(.preview(lastExportAt: Date.now.timeIntervalSince1970 - 3600))
        .preferredColorScheme(.dark)
}

/// The export format picker is a `Menu`, which a preview can't open,
/// and the import alerts are driven by private `@State`. These two
/// previews at least make the new CSV failure copy reviewable without
/// running the app — the tap-driven simulator path is unavailable on
/// this XcodeBuildMCP install (see CLAUDE.md).
#Preview("CSV parse failure alert") {
    Color.clear
        .alert(
            ImportFailure.invalidCSV.title,
            isPresented: .constant(true)
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(ImportFailure.invalidCSV.message)
        }
}

#Preview("Malformed row alert") {
    Color.clear
        .alert(
            ImportFailure.malformedRow(line: 42).title,
            isPresented: .constant(true)
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(ImportFailure.malformedRow(line: 42).message)
        }
}

#Preview("Confirmation sheet") {
    Color.clear.sheet(isPresented: .constant(true)) {
        ImportConfirmSheet(
            summary: ImportSummary(
                totalHabits: 12,
                newHabits: 3,
                updatedHabits: 9,
                totalCompletions: 147,
                newCompletions: 12,
                updatedCompletions: 135
            ),
            onCancel: {},
            onConfirm: {}
        )
    }
}

private extension UserDefaults {
    /// Isolated `UserDefaults` instance for previews so the `@AppStorage`
    /// value doesn't bleed into the running app or between previews.
    static func preview(lastExportAt: Double) -> UserDefaults {
        let suite = UserDefaults(suiteName: "backup-section-preview-\(UUID().uuidString)") ?? .standard
        suite.set(lastExportAt, forKey: "lastExportAt")
        return suite
    }
}
