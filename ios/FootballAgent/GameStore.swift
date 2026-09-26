import Foundation
import SwiftUI

struct SaveSlot: Identifiable, Equatable {
    var id: String
    var agencyName: String
    var week: Int
    var season: Int
    var modified: Date
}

@MainActor
final class GameStore: ObservableObject {
    @Published private(set) var game: GameState?
    @Published private(set) var slots: [SaveSlot] = []
    @Published private(set) var selectedSlot: String?
    @Published var lastMessage: String?
    @Published var persistentError: String?
    @Published private(set) var isAdvancing = false

    private let directory: URL
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(directory: URL? = nil, fileManager: FileManager = .default, autoLoad: Bool = true) {
        self.fileManager = fileManager
        if let directory {
            self.directory = directory
        } else {
            let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            self.directory = support.appendingPathComponent("FootballAgent/Saves", isDirectory: true)
        }
        encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        decoder = JSONDecoder()
        refreshSlots()
        if autoLoad, let preferred = UserDefaults.standard.string(forKey: "FootballAgent.selectedSlot"),
           slots.contains(where: { $0.id == preferred }) {
            load(slot: preferred)
        } else if autoLoad, let newest = slots.first?.id {
            load(slot: newest)
        }
    }

    func newGame(name: String, seed: UInt64, slot: String? = nil) {
        let id = uniqueSlot(slot ?? name)
        game = GameEngine.newGame(name: name, seed: seed)
        selectedSlot = id
        UserDefaults.standard.set(id, forKey: "FootballAgent.selectedSlot")
        persist()
        lastMessage = "\(game?.agency.name ?? "Agency") is ready for business."
    }

    @discardableResult
    func perform(_ action: GameAction) -> ActionOutcome {
        guard var current = game else { return .failure("Start or load a game first.") }
        let result = GameEngine.perform(action, on: &current)
        if result.ok {
            game = current
            persist()
        }
        lastMessage = result.message
        return result
    }

    func advance(_ mode: AdvanceMode) {
        guard !isAdvancing, var current = game else { return }
        isAdvancing = true
        let events = GameEngine.advance(mode, state: &current)
        game = current
        persist()
        if let important = events.last(where: { $0.tone != .neutral }) ?? events.last {
            lastMessage = important.title + ": " + important.detail
        } else {
            lastMessage = "Advanced to week \(current.week)."
        }
        isAdvancing = false
    }

    func load(slot: String) {
        do {
            let data = try Data(contentsOf: url(for: slot))
            let loaded = try decoder.decode(GameState.self, from: data)
            guard loaded.schemaVersion == 1 else {
                persistentError = "This save was created by a newer version of Football Agent. It has been left untouched."
                return
            }
            game = loaded
            selectedSlot = slot
            persistentError = nil
            UserDefaults.standard.set(slot, forKey: "FootballAgent.selectedSlot")
            lastMessage = "Loaded \(loaded.agency.name)."
        } catch {
            persistentError = "That save could not be opened. The original file is still preserved."
        }
    }

    func delete(slot: String) {
        do {
            try fileManager.removeItem(at: url(for: slot))
            let backup = backupURL(for: slot)
            if fileManager.fileExists(atPath: backup.path) { try? fileManager.removeItem(at: backup) }
            if selectedSlot == slot { game = nil; selectedSlot = nil }
            refreshSlots()
            lastMessage = "Save deleted."
        } catch {
            persistentError = "The save could not be deleted: \(error.localizedDescription)"
        }
    }

    func dismissMessage() { lastMessage = nil }

    func refreshSlots() {
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let files = (try? fileManager.contentsOfDirectory(at: directory,
                                                          includingPropertiesForKeys: [.contentModificationDateKey],
                                                          options: [.skipsHiddenFiles])) ?? []
        slots = files.filter { $0.pathExtension == "json" && !$0.lastPathComponent.hasSuffix(".bak.json") }.compactMap { file in
            guard let data = try? Data(contentsOf: file), let state = try? decoder.decode(GameState.self, from: data) else { return nil }
            let modified = (try? file.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return SaveSlot(id: file.deletingPathExtension().lastPathComponent, agencyName: state.agency.name,
                            week: state.week, season: state.season, modified: modified)
        }.sorted { $0.modified > $1.modified }
    }

    private func persist() {
        guard let game, let selectedSlot else { return }
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            let destination = url(for: selectedSlot)
            let temporary = directory.appendingPathComponent(".\(selectedSlot)-\(UUID().uuidString).tmp")
            let backup = backupURL(for: selectedSlot)
            let data = try encoder.encode(game)
            if fileManager.fileExists(atPath: destination.path) {
                if fileManager.fileExists(atPath: backup.path) { try fileManager.removeItem(at: backup) }
                try fileManager.copyItem(at: destination, to: backup)
            }
            try data.write(to: temporary, options: .atomic)
            if fileManager.fileExists(atPath: destination.path) {
                _ = try fileManager.replaceItemAt(destination, withItemAt: temporary)
            } else {
                try fileManager.moveItem(at: temporary, to: destination)
            }
            persistentError = nil
            refreshSlots()
        } catch {
            persistentError = "Progress is safe in memory, but autosave failed: \(error.localizedDescription)"
        }
    }

    private func url(for slot: String) -> URL { directory.appendingPathComponent(slot).appendingPathExtension("json") }
    private func backupURL(for slot: String) -> URL { directory.appendingPathComponent(slot + ".bak").appendingPathExtension("json") }

    private func uniqueSlot(_ suggestion: String) -> String {
        let base = suggestion.lowercased().unicodeScalars.map { CharacterSet.alphanumerics.contains($0) ? Character(String($0)) : "-" }
        var value = String(base).split(separator: "-").filter { !$0.isEmpty }.joined(separator: "-")
        if value.isEmpty { value = "career" }
        var candidate = value
        var suffix = 2
        while fileManager.fileExists(atPath: url(for: candidate).path) {
            candidate = "\(value)-\(suffix)"
            suffix += 1
        }
        return candidate
    }
}
