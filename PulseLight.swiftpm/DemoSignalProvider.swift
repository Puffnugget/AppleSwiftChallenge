import Foundation
import Combine

class DemoSignalProvider: ObservableObject {
    @Published var isRunning = false

    private var timer: AnyCancellable?
    private var index = 0

 
    static let demoSignal: [Double] = {
        var values: [Double] = []
        let sampleRate = 30.0
        let bpm = 72.0
        let freq = bpm / 60.0
        for i in 0..<600 {
            let t = Double(i) / sampleRate
            let phase = (2.0 * .pi * freq * t).truncatingRemainder(dividingBy: 2.0 * .pi)
            
            // Heartbeat pattern: sharp peak (systole) + gentler wave (diastole)
            let heartbeat: Double
            if phase < .pi {
                // Systolic phase: sharp exponential rise and fall
                let normalizedPhase = phase / .pi
                heartbeat = exp(-8.0 * pow(normalizedPhase - 0.3, 2)) + 0.3 * exp(-20.0 * pow(normalizedPhase - 0.5, 2))
            } else {
                // Diastolic phase: gentler decline with dicrotic notch
                let normalizedPhase = (phase - .pi) / .pi
                let dicroticNotch = 0.15 * exp(-30.0 * pow(normalizedPhase - 0.3, 2))
                heartbeat = 0.4 * (1.0 - normalizedPhase) + dicroticNotch
            }
            
            // Add harmonics for more realistic shape
            let harmonic2 = 0.2 * sin(2.0 * .pi * 2.0 * freq * t)
            let harmonic3 = 0.1 * sin(2.0 * .pi * 3.0 * freq * t + 0.5)
            // Small random-ish perturbation using deterministic function
            let noise = 0.03 * sin(Double(i) * 0.7 + 3.14) * cos(Double(i) * 0.3)
            // Base brightness around 180 (typical red channel value)
            let value = 180.0 + 12.0 * heartbeat + 3.0 * (harmonic2 + harmonic3) + noise
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
