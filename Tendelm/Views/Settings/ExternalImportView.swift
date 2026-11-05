import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import TendelmCore

struct ExternalImportView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.calendar) private var calendar
    @State private var showsPicker = false
    @State private var isReading = false
    @State private var readTask: Task<Void, Never>?
    @State private var pendingData: Data?
    @State private var needsDateOrder = false
    @State private var document: ExternalHabitImport?
    @State private var summary: ExternalImportSummary?
    @State private var message: String?
    @State private var messageTitle = "Couldn't import"

    var body: some View {
        Form {
            Section {
                Text("Bring your history with you")
                    .font(.headline)
                Text("Choose a daily CSV from Streaks or Habitify. You'll see a preview before anything is added.")
                    .foregroundStyle(Color.kadoForegroundSecondary)
                Button("Choose a file", systemImage: "doc") { showsPicker = true }
                    .disabled(isReading)
                    .accessibilityIdentifier("externalImport.choose")
                if isReading { TendelmProgressLabel(title: "Reading your history…") }
            } footer: {
                Text("Your file is read on this device.")
            }
            .listRowBackground(Color.kadoBackgroundSecondary)

            if needsDateOrder {
                Section {
                    Button("Month / day / year — 06/15/2025") { reparse(.monthFirst) }
                        .accessibilityIdentifier("externalImport.monthFirst")
                    Button("Day / month / year — 15/06/2025") { reparse(.dayFirst) }
                        .accessibilityIdentifier("externalImport.dayFirst")
                } header: { Text("How are dates written in this file?") }
                footer: { Text("Both orders fit these dates. Choose the one your old app used.") }
                .listRowBackground(Color.kadoBackgroundSecondary)
            }

            if let document, let summary {
                Section("Preview · \(document.source.rawValue)") {
                    LabeledContent("New habits", value: "\(summary.newHabits)")
                    LabeledContent("Days to add", value: "\(summary.newDays)")
                        .accessibilityIdentifier("externalImport.newDays")
                    if summary.existingDays > 0 {
                        LabeledContent("Days already in Tendelm", value: "\(summary.existingDays)")
                    }
                    DisclosureGroup("Habits in this file") {
                        ForEach(document.habits, id: \.id) { habit in
                            LabeledContent(habit.name, value: "\(habit.completions.count) days")
                        }
                    }
                    Text("Imports daily checkmarks and notes. Set goals, schedules and reminders afterward. Existing daily entries and habit settings stay as they are; an earlier entry extends that habit's start date.")
                        .font(.footnote).foregroundStyle(Color.kadoForegroundSecondary)
                    if document.skippedDays > 0 {
                        Text("\(document.skippedDays) skipped days will be kept as notes, without a checkmark. Tendelm doesn't pause streaks for skipped days, so streak totals may differ.")
                            .font(.footnote)
                    }
                    if document.quantityDays > 0 {
                        Text("Original amounts and units are kept in notes. They won't become counter or timer goals.")
                            .font(.footnote)
                    }
                    if document.usesNamesAsIdentity {
                        Text("Some entries have no original habit ID. Matching names are grouped together; renaming them in a later export creates a separate habit.")
                            .font(.footnote)
                    }
                    if summary.hasAdditions {
                        Button("Import history", systemImage: "arrow.down.doc") { commit(document) }
                            .accessibilityIdentifier("externalImport.confirm")
                    } else {
                        Text("This history is already in Tendelm.")
                    }
                    Button("Cancel", role: .cancel) { clearPreview() }
                        .accessibilityIdentifier("externalImport.cancel")
                }
                .listRowBackground(Color.kadoBackgroundSecondary)
            }

            Section("Get your export") {
                DisclosureGroup("Streaks") {
                    Text("Settings → Manage Data → Export Data → Tasks → CSV. Save to Files, then choose it here.")
                    Text("Manual completions, misses and skips are supported. Other entry types need a simple CSV conversion first.")
                        .font(.footnote).foregroundStyle(Color.kadoForegroundSecondary)
                    Link("Streaks export help", destination: URL(string: "https://streaks.app/help/export-task-data/")!)
                }
                DisclosureGroup("Habitify") {
                    Text("Settings → Import / Export → Export as .csv. Save to Files, then choose it here.")
                    Link("Habitify export help", destination: URL(string: "https://intercom.help/habitify-app/en/articles/10501738-how-to-export-data-of-habitify-account")!)
                }
                DisclosureGroup("Another app?") {
                    Text("Direct imports from other apps aren't available yet. If your app exports a spreadsheet, you can arrange it in this simple format. Use completed, failed or skipped for the status and YYYY-MM-DD for dates.")
                    Text("habit,date,status,note\nRead,2025-06-15,completed,Five pages")
                        .font(.footnote.monospaced()).textSelection(.enabled)
                    Text("An optional habit_id column keeps matching the same habit after you rename it. HabitKit JSON, Loop ZIP, and full database backups aren't supported here.")
                        .font(.footnote).foregroundStyle(Color.kadoForegroundSecondary)
                }
            }
            .listRowBackground(Color.kadoBackgroundSecondary)
        }
        .scrollContentBackground(.hidden)
        .background(Color.kadoBackground)
        .navigationTitle("Import history")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $showsPicker, allowedContentTypes: [.commaSeparatedText, .plainText]) { result in
            switch result {
            case .success(let url): load(url)
            case .failure(let error):
                if (error as NSError).code != NSUserCancelledError { showError(error) }
            }
        }
        .alert(messageTitle, isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(message ?? "") }
        .onDisappear { readTask?.cancel() }
    }

    private func load(_ url: URL) {
        readTask?.cancel()
        clearPreview()
        isReading = true
        readTask = Task {
            defer { isReading = false }
            do {
                let data = try await ExternalImportFileReader.read(url)
                try Task.checkCancellation()
                pendingData = data
                try await prepare(data, order: .automatic)
            } catch is CancellationError { return }
            catch ExternalImportError.needsDateOrder { needsDateOrder = true }
            catch { pendingData = nil; showError(error) }
        }
    }

    private func reparse(_ order: ImportDateOrder) {
        guard let data = pendingData, !isReading else { return }
        needsDateOrder = false
        isReading = true
        readTask = Task {
            defer { isReading = false }
            do { try await prepare(data, order: order) }
            catch is CancellationError { return }
            catch { showError(error); needsDateOrder = true }
        }
    }

    private func prepare(_ data: Data, order: ImportDateOrder) async throws {
        let parsed = try await ExternalImportFileReader.parse(data, dateOrder: order, calendar: calendar)
        try Task.checkCancellation()
        let preview = try ExternalHabitImporter().summary(for: parsed, in: context, calendar: calendar)
        document = parsed
        summary = preview
        pendingData = nil
    }

    private func commit(_ document: ExternalHabitImport) {
        do {
            let result = try ExternalHabitImporter().apply(document, to: context, calendar: calendar)
            WidgetReloader.reloadAll(using: context)
            clearPreview()
            messageTitle = "History imported"
            message = "Added \(result.newHabits) habits and \(result.newDays) days. Your existing daily entries were kept."
        } catch { showError(error) }
    }

    private func clearPreview() {
        document = nil
        summary = nil
        pendingData = nil
        needsDateOrder = false
    }

    private func showError(_ error: Error) {
        messageTitle = "Couldn't import"
        message = error.localizedDescription
    }
}
