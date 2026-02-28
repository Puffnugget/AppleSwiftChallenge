import Foundation

struct BloodPressure: Codable, Equatable {
    var systolic: Int
    var diastolic: Int

    var formatted: String {
        "\(systolic)/\(diastolic)"
    }
}

struct PulseSession: Codable, Identifiable, Equatable {
    var id: UUID
    var date: Date
    var bpm: Double
    var confidence: Double
    var waveform: [Double]
    var isDemo: Bool
    var bloodPressure: BloodPressure?

    var formattedBPM: String {
        "\(Int(bpm.rounded()))"
    }

    var confidenceLabel: String {
        if confidence >= 0.7 { return "Good" }
        if confidence >= 0.4 { return "Fair" }
        return "Poor"
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
