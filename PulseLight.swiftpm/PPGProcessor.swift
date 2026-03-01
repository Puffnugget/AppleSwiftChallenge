import Foundation
import Accelerate

class PPGProcessor: ObservableObject {
    @Published var currentBPM: Double = 0
    @Published var confidence: Double = 0
    @Published var filteredWaveform: [Double] = []
    @Published var hasValidEstimate: Bool = false

    private let bufferSize = PulseConstants.bufferSize

    // Actual sample rate measured from hardware timestamps
    private var measuredSampleRate: Double = PulseConstants.sampleRate
    private var sampleTimestamps: [TimeInterval] = []

    // BPM smoothing
    private var bpmHistory: [Double] = []
    private let bpmHistorySize = 4

    // All smoothed readings across the session, used for final average
    private var allBPMReadings: [Double] = []

    var sessionAverageBPM: Double {
        guard !allBPMReadings.isEmpty else { return currentBPM }
        return allBPMReadings.reduce(0, +) / Double(allBPMReadings.count)
    }

    // IIR bandpass: high-pass 0.5 Hz then low-pass 4 Hz at fs=30 Hz
    private let hpB: [Double] = [0.9695, -1.9391, 0.9695]
    private let hpA: [Double] = [1.0, -1.9380, 0.9401]
    private var hpX: [Double] = [0, 0, 0]
    private var hpY: [Double] = [0, 0, 0]

    private let lpB: [Double] = [0.1296, 0.2592, 0.1296]
    private let lpA: [Double] = [1.0, -0.5095, 0.0280]
    private var lpX: [Double] = [0, 0, 0]
    private var lpY: [Double] = [0, 0, 0]

    // Internal buffer — mutated on whatever thread ingest() is called from
    private var internalFiltered: [Double] = []

    func reset() {
        bpmHistory.removeAll()
        allBPMReadings.removeAll()
        filteredWaveform.removeAll()
        sampleTimestamps.removeAll()
        internalFiltered.removeAll()
        currentBPM = 0
        confidence = 0
        hasValidEstimate = false
        measuredSampleRate = PulseConstants.sampleRate
        hpX = [0, 0, 0]; hpY = [0, 0, 0]
        lpX = [0, 0, 0]; lpY = [0, 0, 0]
    }

    func ingest(_ value: Double, at timestamp: TimeInterval = 0) {
        // Measure real sample rate from hardware timestamps
        if timestamp > 0 {
            sampleTimestamps.append(timestamp)
            if sampleTimestamps.count > bufferSize { sampleTimestamps.removeFirst() }
            if sampleTimestamps.count >= 30 {
                let elapsed = sampleTimestamps.last! - sampleTimestamps.first!
                if elapsed > 0 { measuredSampleRate = Double(sampleTimestamps.count - 1) / elapsed }
            }
        }

        let filtered = applyFilter(value)
        internalFiltered.append(filtered)
        if internalFiltered.count > bufferSize { internalFiltered.removeFirst() }

        // Snapshot for UI and BPM computation — publish to main thread
        let snapshot = internalFiltered
        let fs = measuredSampleRate
        DispatchQueue.main.async {
            self.filteredWaveform = snapshot
            if snapshot.count >= PulseConstants.minimumFramesForEstimate {
                self.computeBPM(signal: snapshot, fs: fs)
            }
        }
    }

    private func applyFilter(_ x: Double) -> Double {
        hpX[0] = x
        let hpOut = hpB[0]*hpX[0] + hpB[1]*hpX[1] + hpB[2]*hpX[2]
                  - hpA[1]*hpY[1] - hpA[2]*hpY[2]
        hpX[2] = hpX[1]; hpX[1] = hpX[0]
        hpY[2] = hpY[1]; hpY[1] = hpOut

        lpX[0] = hpOut
        let lpOut = lpB[0]*lpX[0] + lpB[1]*lpX[1] + lpB[2]*lpX[2]
                  - lpA[1]*lpY[1] - lpA[2]*lpY[2]
        lpX[2] = lpX[1]; lpX[1] = lpX[0]
        lpY[2] = lpY[1]; lpY[1] = lpOut

        return lpOut
    }

    // Called on main thread with a snapshot of the filtered buffer
    private func computeBPM(signal: [Double], fs: Double) {
        let n = signal.count

        // Minimum amplitude check — if the signal is nearly flat, no finger is present.
        // A real PPG signal has an AC amplitude of at least 0.3 units after bandpass filtering.
        let sigMin = signal.min() ?? 0
        let sigMax = signal.max() ?? 0
        guard (sigMax - sigMin) > 0.3 else {
            hasValidEstimate = false
            return
        }

        // Mean-subtract
        var s = signal
        var mean: Double = 0
        vDSP_meanvD(s, 1, &mean, vDSP_Length(n))
        var negMean = -mean
        vDSP_vsaddD(s, 1, &negMean, &s, 1, vDSP_Length(n))

        // Hann window to reduce spectral leakage
        for i in 0..<n {
            s[i] *= 0.5 * (1.0 - cos(2.0 * .pi * Double(i) / Double(n - 1)))
        }

        // Zero-pad to next power of 2
        let fftLength = nextPowerOfTwo(n)
        s.append(contentsOf: [Double](repeating: 0, count: fftLength - n))

        let log2n = vDSP_Length(log2(Double(fftLength)))
        guard let fftSetup = vDSP_create_fftsetupD(log2n, FFTRadix(kFFTRadix2)) else { return }
        defer { vDSP_destroy_fftsetupD(fftSetup) }

        var realPart = [Double](repeating: 0, count: fftLength / 2)
        var imagPart = [Double](repeating: 0, count: fftLength / 2)

        s.withUnsafeBufferPointer { sp in
            realPart.withUnsafeMutableBufferPointer { rp in
                imagPart.withUnsafeMutableBufferPointer { ip in
                    var split = DSPDoubleSplitComplex(realp: rp.baseAddress!, imagp: ip.baseAddress!)
                    sp.baseAddress!.withMemoryRebound(to: DSPDoubleComplex.self, capacity: fftLength / 2) { cp in
                        vDSP_ctozD(cp, 2, &split, 1, vDSP_Length(fftLength / 2))
                    }
                    vDSP_fft_zripD(fftSetup, &split, 1, log2n, FFTDirection(kFFTDirection_Forward))
                }
            }
        }

        var magnitudes = [Double](repeating: 0, count: fftLength / 2)
        realPart.withUnsafeMutableBufferPointer { rp in
            imagPart.withUnsafeMutableBufferPointer { ip in
                var split = DSPDoubleSplitComplex(realp: rp.baseAddress!, imagp: ip.baseAddress!)
                vDSP_zvmagsD(&split, 1, &magnitudes, 1, vDSP_Length(fftLength / 2))
            }
        }

        let freqResolution = fs / Double(fftLength)
        let minBin = max(1, Int((0.67 / freqResolution).rounded()))
        let maxBin = min(fftLength / 2 - 2, Int((3.0 / freqResolution).rounded()))
        guard minBin < maxBin else { return }

        var peakMag: Double = 0
        var peakBin = minBin
        for i in minBin...maxBin {
            if magnitudes[i] > peakMag { peakMag = magnitudes[i]; peakBin = i }
        }

        let bpm = Double(peakBin) * freqResolution * 60.0
        guard bpm >= 40 && bpm <= 180 else { return }

        // Confidence: peak vs band mean
        let bandSlice = Array(magnitudes[minBin...maxBin])
        var bandMean: Double = 0
        vDSP_meanvD(bandSlice, 1, &bandMean, vDSP_Length(bandSlice.count))
        let conf = bandMean > 0 ? min(1.0, peakMag / (bandMean * 10.0)) : 0

        bpmHistory.append(bpm)
        if bpmHistory.count > bpmHistorySize { bpmHistory.removeFirst() }

        let smoothed = bpmHistory.reduce(0, +) / Double(bpmHistory.count)
        currentBPM = smoothed
        allBPMReadings.append(smoothed)
        confidence = conf
        hasValidEstimate = true
    }

    private func nextPowerOfTwo(_ n: Int) -> Int {
        var v = n - 1
        v |= v >> 1; v |= v >> 2; v |= v >> 4; v |= v >> 8; v |= v >> 16
        return v + 1
    }
}
