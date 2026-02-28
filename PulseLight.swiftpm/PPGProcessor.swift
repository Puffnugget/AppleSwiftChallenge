import Foundation
import Accelerate

class PPGProcessor: ObservableObject {
    @Published var currentBPM: Double = 0
    @Published var confidence: Double = 0
    @Published var filteredWaveform: [Double] = []
    @Published var hasValidEstimate: Bool = false

    private var ringBuffer: [Double] = []
    private let bufferSize = PulseConstants.bufferSize
    private let sampleRate = PulseConstants.sampleRate

    // IIR filter state (2nd order biquad sections)
    // High-pass 0.5 Hz at fs=30 Hz
    private let hpB: [Double] = [0.9695, -1.9391, 0.9695]
    private let hpA: [Double] = [1.0, -1.9380, 0.9401]
    private var hpX: [Double] = [0, 0, 0]
    private var hpY: [Double] = [0, 0, 0]

    // Low-pass 4 Hz at fs=30 Hz
    private let lpB: [Double] = [0.1296, 0.2592, 0.1296]
    private let lpA: [Double] = [1.0, -0.5095, 0.0280]
    private var lpX: [Double] = [0, 0, 0]
    private var lpY: [Double] = [0, 0, 0]

    func reset() {
        ringBuffer.removeAll()
        filteredWaveform.removeAll()
        currentBPM = 0
        confidence = 0
        hasValidEstimate = false
        hpX = [0, 0, 0]
        hpY = [0, 0, 0]
        lpX = [0, 0, 0]
        lpY = [0, 0, 0]
    }

    func ingest(_ value: Double) {
        ringBuffer.append(value)
        if ringBuffer.count > bufferSize {
            ringBuffer.removeFirst(ringBuffer.count - bufferSize)
        }

        // Apply IIR filter to latest sample
        let filtered = applyFilter(value)
        filteredWaveform.append(filtered)
        if filteredWaveform.count > bufferSize {
            filteredWaveform.removeFirst(filteredWaveform.count - bufferSize)
        }

        if ringBuffer.count >= PulseConstants.minimumFramesForEstimate {
            computeBPM()
        }
    }

    private func applyFilter(_ x: Double) -> Double {
        // High-pass
        hpX[0] = x
        let hpOut = hpB[0] * hpX[0] + hpB[1] * hpX[1] + hpB[2] * hpX[2]
                  - hpA[1] * hpY[1] - hpA[2] * hpY[2]
        hpX[2] = hpX[1]; hpX[1] = hpX[0]
        hpY[2] = hpY[1]; hpY[1] = hpOut

        // Low-pass
        lpX[0] = hpOut
        let lpOut = lpB[0] * lpX[0] + lpB[1] * lpX[1] + lpB[2] * lpX[2]
                  - lpA[1] * lpY[1] - lpA[2] * lpY[2]
        lpX[2] = lpX[1]; lpX[1] = lpX[0]
        lpY[2] = lpY[1]; lpY[1] = lpOut

        return lpOut
    }

    private func computeBPM() {
        let n = ringBuffer.count
        guard n >= PulseConstants.minimumFramesForEstimate else { return }

        // Detrend: subtract mean
        var signal = ringBuffer
        var mean: Double = 0
        vDSP_meanvD(signal, 1, &mean, vDSP_Length(n))
        var negMean = -mean
        vDSP_vsaddD(signal, 1, &negMean, &signal, 1, vDSP_Length(n))

        // Zero-pad to next power of 2
        let fftLength = nextPowerOfTwo(n)
        signal.append(contentsOf: [Double](repeating: 0, count: fftLength - n))

        // FFT
        let log2n = vDSP_Length(log2(Double(fftLength)))
        guard let fftSetup = vDSP_create_fftsetupD(log2n, FFTRadix(kFFTRadix2)) else { return }
        defer { vDSP_destroy_fftsetupD(fftSetup) }

        var realPart = [Double](repeating: 0, count: fftLength / 2)
        var imagPart = [Double](repeating: 0, count: fftLength / 2)

        signal.withUnsafeBufferPointer { signalPtr in
            realPart.withUnsafeMutableBufferPointer { realPtr in
                imagPart.withUnsafeMutableBufferPointer { imagPtr in
                    var splitComplex = DSPDoubleSplitComplex(
                        realp: realPtr.baseAddress!,
                        imagp: imagPtr.baseAddress!
                    )
                    signalPtr.baseAddress!.withMemoryRebound(to: DSPDoubleComplex.self, capacity: fftLength / 2) { complexPtr in
                        vDSP_ctozD(complexPtr, 2, &splitComplex, 1, vDSP_Length(fftLength / 2))
                    }
                    vDSP_fft_zripD(fftSetup, &splitComplex, 1, log2n, FFTDirection(kFFTDirection_Forward))
                }
            }
        }

        // Magnitude spectrum
        var magnitudes = [Double](repeating: 0, count: fftLength / 2)
        realPart.withUnsafeMutableBufferPointer { realPtr in
            imagPart.withUnsafeMutableBufferPointer { imagPtr in
                var splitComplex = DSPDoubleSplitComplex(
                    realp: realPtr.baseAddress!,
                    imagp: imagPtr.baseAddress!
                )
                vDSP_zvmagsD(&splitComplex, 1, &magnitudes, 1, vDSP_Length(fftLength / 2))
            }
        }

        // Frequency resolution
        let freqResolution = sampleRate / Double(fftLength)

        // Find peak in 0.5–4 Hz range (30–240 BPM)
        let minBin = max(1, Int(0.5 / freqResolution))
        let maxBin = min(fftLength / 2 - 1, Int(4.0 / freqResolution))

        guard minBin < maxBin else { return }

        var peakMag: Double = 0
        var peakBin: Int = minBin
        for i in minBin...maxBin {
            if magnitudes[i] > peakMag {
                peakMag = magnitudes[i]
                peakBin = i
            }
        }

        let peakFreq = Double(peakBin) * freqResolution
        let bpm = peakFreq * 60.0

        // Confidence: peak-to-mean ratio in the search band
        let bandSlice = Array(magnitudes[minBin...maxBin])
        var bandMean: Double = 0
        vDSP_meanvD(bandSlice, 1, &bandMean, vDSP_Length(bandSlice.count))

        let conf: Double
        if bandMean > 0 {
            conf = min(1.0, peakMag / (bandMean * 10.0))
        } else {
            conf = 0
        }

        DispatchQueue.main.async {
            self.currentBPM = bpm
            self.confidence = conf
            self.hasValidEstimate = true
        }
    }

    private func nextPowerOfTwo(_ n: Int) -> Int {
        var v = n - 1
        v |= v >> 1; v |= v >> 2; v |= v >> 4; v |= v >> 8; v |= v >> 16
        return v + 1
    }
}
