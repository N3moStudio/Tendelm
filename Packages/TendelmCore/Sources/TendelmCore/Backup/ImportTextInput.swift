import Foundation

/// Clipboard input is opt-in and goes through the same parsers as a file.
nonisolated public enum ImportTextInput {
    public static func data(from strings: [String], maximumBytes: Int = ExternalHabitCSV.maximumBytes) throws -> Data {
        guard strings.count == 1, let text = strings.first else {
            throw ExternalImportError.invalidFile("Copy the contents of one export, then tap Paste again.")
        }
        guard text.utf8.count <= maximumBytes else {
            throw ExternalImportError.invalidFile("This text is too large. Use an export smaller than 8 MB.")
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ExternalImportError.invalidFile("Copy your export's text first, then tap Paste.")
        }
        guard !trimmed.lowercased().hasPrefix("https://"), !trimmed.lowercased().hasPrefix("http://"),
              !trimmed.lowercased().hasPrefix("file://") else {
            throw ExternalImportError.invalidFile("Copy the file's contents, not its link, then tap Paste again.")
        }
        return Data(text.utf8)
    }
}
