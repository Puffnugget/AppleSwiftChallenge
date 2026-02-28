import Foundation
import Combine

class DemoSignalProvider: ObservableObject {
    @Published var isRunning = false

    private var timer: AnyCancellable?
    private var index = 0

    // Precomputed 600 brightness values simulating ~72 BPM pulse at 30 fps
    // 72 BPM = 1.2 Hz, period = 25 frames at 30 fps
    static let demoSignal: [Double] = {
        var values: [Double] = []
        let sampleRate = 30.0
        let bpm = 72.0
        let freq = bpm / 60.0
        for i in 0..<600 {
            let t = Double(i) / sampleRate
            // Simulate PPG: fundamental + harmonics + noise
            let fundamental = sin(2.0 * .pi * freq * t)
            let harmonic2 = 0.3 * sin(2.0 * .pi * 2.0 * freq * t)
            let harmonic3 = 0.15 * sin(2.0 * .pi * 3.0 * freq * t + 0.5)
            // Small random-ish perturbation using deterministic function
            let noise = 0.05 * sin(Double(i) * 0.7 + 3.14) * cos(Double(i) * 0.3)
            // Base brightness around 180 (typical red channel value)
            let value = 180.0 + 8.0 * (fundamental + harmonic2 + harmonic3) + noise
            values.append(value)
        }
        return values
    }()

    func start(onSample: @escaping (Double) -> Void) {
        index = 0
        isRunning = true
        timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.isRunning else { return }
                if self.index < DemoSignalProvider.demoSignal.count {
                    onSample(DemoSignalProvider.demoSignal[self.index])
                    self.index += 1
                } else {
                    self.stop()
                }
            }
    }

    func stop() {
        timer?.cancel()
        timer = nil
        isRunning = false
    }
}
