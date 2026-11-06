import Foundation
import SwiftUI
import UserNotifications
import TendelmCore

extension EnvironmentValues {
    @Entry var eraseAllTendelmData: @MainActor () throws -> Void = { throw AppDataReset.Failure.unavailable }
}

@MainActor
enum AppDataReset {
    enum Failure: Error, LocalizedError {
        case unavailable, cleanup
        var errorDescription: String? {
            switch self {
            case .unavailable: "The reset isn't available here. Open Settings in Tendelm and try again."
            case .cleanup: "Your saved items were erased, but some cached files couldn't be removed. Try Erase all data again to finish."
            }
        }
    }

    static func clearPreferences(in stores: [UserDefaults]) {
        for defaults in stores {
            for key in defaults.dictionaryRepresentation().keys
                where key.hasPrefix("kado.") || key.hasPrefix("personal.") || key == "lastExportAt" {
                defaults.removeObject(forKey: key)
            }
        }
    }

    /// Only the app's own generated export copies; exports saved in Files remain.
    static func clearTemporaryBackups(in directory: URL = FileManager.default.temporaryDirectory) throws {
        let fm = FileManager.default
        for folder in try fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey]) {
            guard UUID(uuidString: folder.lastPathComponent) != nil else { continue }
            let values = try folder.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
            guard values.isDirectory == true, values.isSymbolicLink != true else { continue }
            let files = try fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
            let exports = files.filter { $0.lastPathComponent.hasPrefix("tendelm-backup-") && ["json", "csv"].contains($0.pathExtension) }
            guard !exports.isEmpty else { continue }
            for file in exports {
                try fm.removeItem(at: file)
            }
            if try fm.contentsOfDirectory(atPath: folder.path).isEmpty { try fm.removeItem(at: folder) }
        }
    }

    static func clearCachedFiles() throws {
        try clearTemporaryBackups()
        let fm = FileManager.default
        #if DEBUG
        // UI runs use separate stores and must never touch the normal store copy.
        if UITestSupport.isRunningUITests { return }
        #endif
        // A migration keeps a safety copy of the old store. Explicit erasure
        // removes that inactive copy too, so it cannot later resurrect data.
        if let active = SharedStore.productionStoreURL(), active != SharedStore.legacyStoreURL() {
            let legacyStores = [SharedStore.legacyStoreURL(), URL.applicationSupportDirectory.appendingPathComponent("TendelmDev.sqlite")]
            for legacy in legacyStores where legacy != SharedStore.devStoreURL() {
                for suffix in ["", "-shm", "-wal"] {
                    let old = URL(fileURLWithPath: legacy.path + suffix)
                    if fm.fileExists(atPath: old.path) { try fm.removeItem(at: old) }
                }
            }
        }
        if let snapshot = WidgetSnapshotStore.url(), fm.fileExists(atPath: snapshot.path) {
            try fm.removeItem(at: snapshot)
        }
    }
}
