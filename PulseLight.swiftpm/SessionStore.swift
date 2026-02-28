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

    func save(_ session: PulseSession) {
        sessions.insert(session, at: 0)
        persist()
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

    private func persist() {
        do {
            let data = try JSONEncoder().encode(sessions)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save sessions: \(error)")
        }
    }
}
