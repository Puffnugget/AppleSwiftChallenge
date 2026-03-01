import Foundation
import SwiftUI

class SessionStore: ObservableObject {
    @Published var sessions: [PulseSession] = []

    private let fileName = "pulse_sessions.json"

    init() {
        load()
    }

    private var fileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(fileName)
    }

    func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            sessions = try JSONDecoder().decode([PulseSession].self, from: data)
            sessions.sort { $0.date > $1.date }
        } catch {
            print("Failed to load sessions: \(error)")
        }
    }

    // MARK: - CRUD

    func create(_ session: PulseSession) {
        upsert(session)
    }

    func read(sessionID: UUID) -> PulseSession? {
        sessions.first(where: { $0.id == sessionID })
    }

    func update(_ session: PulseSession) {
        upsert(session)
    }

    func delete(sessionID: UUID) {
        guard let index = sessions.firstIndex(where: { $0.id == sessionID }) else { return }
        sessions.remove(at: index)
        persist()
    }

    // Backward-compatible alias used by older call sites.
    func save(_ session: PulseSession) {
        create(session)
    }

    func delete(at offsets: IndexSet) {
        sessions.remove(atOffsets: offsets)
        persist()
    }

    func updateBloodPressure(for sessionID: UUID, bp: BloodPressure) {
        guard let index = sessions.firstIndex(where: { $0.id == sessionID }) else { return }
        sessions[index].bloodPressure = bp
        persist()
    }

    private func upsert(_ session: PulseSession) {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
        } else {
            sessions.append(session)
        }
        sessions.sort { $0.date > $1.date }
        persist()
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(sessions)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save sessions: \(error)")
        }
    }
}
