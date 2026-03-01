import AVFoundation
import SwiftUI

class CameraEngine: NSObject, ObservableObject {
    @Published var brightness: Double = 0
    @Published var isAuthorized: Bool = false
    @Published var isRunning: Bool = false

    let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.pulselight.camera")
    private var videoOutput: AVCaptureVideoDataOutput?
    private var sampleCallback: ((Double, TimeInterval) -> Void)?

    override init() {
        super.init()
        checkAuthorization()
    }

    func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                }
            }
        default:
            isAuthorized = false
        }
    }

    func start(onSample: @escaping (Double, TimeInterval) -> Void) {
        guard isAuthorized else { return }
        sampleCallback = onSample
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.configureSession()
            self.captureSession.startRunning()
            // Ensure torch is on after session starts
            self.setTorch(on: true)
            DispatchQueue.main.async {
                self.isRunning = true
            }
        }
    }
    
    func start() {
        start(onSample: { _, _ in })
    }

    func stop() {
        sessionQueue.async { [weak self] in
            self?.captureSession.stopRunning()
            self?.setTorch(on: false)
            DispatchQueue.main.async {
                self?.isRunning = false
            }
        }
    }

    private func configureSession() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .low

        // Remove existing inputs/outputs
        captureSession.inputs.forEach { captureSession.removeInput($0) }
        captureSession.outputs.forEach { captureSession.removeOutput($0) }

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            captureSession.commitConfiguration()
            return
        }

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.setSampleBufferDelegate(self, queue: sessionQueue)
        output.alwaysDiscardsLateVideoFrames = true

        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
        }

        // Configure frame rate
        do {
            try device.lockForConfiguration()
            device.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: 30)
            device.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: 30)
            device.unlockForConfiguration()
        } catch {
            print("Could not configure frame rate: \(error)")
        }

        captureSession.commitConfiguration()
    }

    private func setTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            if on {
                try device.setTorchModeOn(level: AVCaptureDevice.maxAvailableTorchLevel)
            }
            device.unlockForConfiguration()
        } catch {
            print("Torch error: \(error)")
        }
    }
}

extension CameraEngine: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Extract hardware presentation timestamp for accurate sample rate measurement
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds

        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return }
        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)

        // Sample center region for red channel mean
        let centerX = width / 2
        let centerY = height / 2
        let regionSize = min(width, height) / 4

        var totalRed: Double = 0
        var count: Double = 0

        let startY = max(0, centerY - regionSize)
        let endY = min(height, centerY + regionSize)
        let startX = max(0, centerX - regionSize)
        let endX = min(width, centerX + regionSize)

        // BGRA format: stride by 8 pixels for performance
        for y in stride(from: startY, to: endY, by: 4) {
            for x in stride(from: startX, to: endX, by: 4) {
                let offset = y * bytesPerRow + x * 4
                let red = Double(buffer[offset + 2])
                totalRed += red
                count += 1
            }
        }

        let meanRed = count > 0 ? totalRed / count : 0

        DispatchQueue.main.async {
            self.brightness = meanRed
        }
        
        // Call callback with both brightness and timestamp
        sampleCallback?(meanRed, timestamp)
    }
}
