import SwiftUI
import Combine
import AVFoundation
import UIKit

// Small live camera preview — confirms the camera feed is active
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView(session: session)
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {}

    // Custom UIView so layoutSubviews keeps the preview layer filling the view
    class PreviewUIView: UIView {
        private let previewLayer: AVCaptureVideoPreviewLayer

        init(session: AVCaptureSession) {
            previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            super.init(frame: .zero)
            layer.addSublayer(previewLayer)
        }

        required init?(coder: NSCoder) { fatalError() }

        override func layoutSubviews() {
            super.layoutSubviews()
            previewLayer.frame = bounds
        }
    }
}

struct CaptureView: View {
    @EnvironmentObject var sessionStore: SessionStore
    @StateObject private var processor = PPGProcessor()
    @StateObject private var demoProvider = DemoSignalProvider()
    @StateObject private var cameraEngine = CameraEngine()
    
    @Binding var hasCompletedHowItWorks: Bool

    @State private var isCapturing = false
    @State private var isDemoMode = false
    @State private var timeRemaining: Double = PulseConstants.sessionDuration
    @State private var showResults = false
    @State private var completedSession: PulseSession?
    @State private var cameraCancellable: AnyCancellable?
    @State private var timerCancellable: AnyCancellable?
    @State private var showHowItWorks = true

    var body: some View {
        ZStack {
            if showHowItWorks {
                HowItWorksView {
                    showHowItWorks = false
                    hasCompletedHowItWorks = true
                }
            } else if let session = completedSession, showResults {
                ResultsView(session: session) {
                    resetCapture()
                }
            } else {
                captureContent
            }
        }
        .navigationBarHidden(showHowItWorks || showResults)
    }

    private var captureContent: some View {
        VStack(spacing: 24) {
            // Demo mode banner
            if isDemoMode {
                HStack(spacing: 8) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Running Demo Signal")
                        .font(PulseTypography.footnote)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [PulseColors.demoBanner, PulseColors.demoBanner.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: PulseColors.demoBanner.opacity(0.3), radius: 6, x: 0, y: 3)
                )
                .accessibilityLabel("Demo mode active")
                .padding(.top, 8)
            }

            Spacer()

            // Countdown / status
            if isCapturing {
                VStack(spacing: 12) {
                    Text("\(Int(timeRemaining))s")
                        .font(PulseTypography.countdownDisplay)
                        .foregroundColor(PulseColors.label)
                        .contentTransition(.numericText())
                        .shadow(color: PulseColors.primary.opacity(0.2), radius: 8, x: 0, y: 4)

                    if processor.hasValidEstimate {
                        HStack(spacing: 8) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(PulseColors.primary)
                            Text("\(Int(processor.currentBPM.rounded())) BPM")
                                .font(PulseTypography.title)
                                .foregroundColor(PulseColors.primary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(PulseColors.primary.opacity(0.12))
                                .shadow(color: PulseColors.primary.opacity(0.2), radius: 4, x: 0, y: 2)
                        )
                    } else {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Analyzing...")
                                .font(PulseTypography.bodyBold)
                                .foregroundColor(PulseColors.secondaryLabel)
                        }
                    }

                    if processor.confidence > 0 && processor.confidence < 0.4 {
                        Label("Hold still for better accuracy", systemImage: "hand.raised.fill")
                            .font(PulseTypography.footnote)
                            .foregroundColor(PulseColors.warning)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(PulseColors.warning.opacity(0.15))
                            )
                    }
                }

                // Camera preview + waveform
                if !isDemoMode {
                    VStack(spacing: 8) {
                        ZStack {
                            CameraPreviewView(session: cameraEngine.captureSession)
                                .frame(width: 220, height: 220)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(PulseColors.primary.opacity(0.3), lineWidth: 1.5))

                            // Placement label at bottom
                            VStack {
                                Spacer()
                                Text("Place fingertip over lens")
                                    .font(PulseTypography.caption)
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.black.opacity(0.45), in: Capsule())
                                    .padding(.bottom, 10)
                            }
                        }

                        Text("The flickering brightness shows your pulse rhythm")
                            .font(PulseTypography.caption)
                            .foregroundColor(PulseColors.secondaryLabel)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                }

                // Live waveform
                WaveformView(data: processor.filteredWaveform, maxPoints: 150, height: 100)
                    .padding(.horizontal)
            } else {
                // Instructions
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(PulseColors.primary.opacity(0.1))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "hand.point.up.fill")
                            .font(.system(size: 56, weight: .medium))
                            .foregroundStyle(PulseColors.primaryGradient)
                    }
                    .shadow(color: PulseColors.primary.opacity(0.2), radius: 12, x: 0, y: 6)

                    VStack(spacing: 8) {
                        if !cameraEngine.isAuthorized && !isDemoMode {
                            Text("Camera access is needed for live measurement")
                                .font(PulseTypography.body)
                                .foregroundColor(PulseColors.secondaryLabel)
                                .multilineTextAlignment(.center)
                        } else if !isDemoMode {
                            Text("Place your fingertip over the\nrear camera and flashlight")
                                .font(PulseTypography.body)
                                .foregroundColor(PulseColors.label)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("Demo mode will simulate a pulse signal")
                                .font(PulseTypography.body)
                                .foregroundColor(PulseColors.secondaryLabel)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 32)
                }
            }

            Spacer()

            // Controls
            VStack(spacing: 16) {
                if !isCapturing {
                    Button {
                        startCapture()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: isDemoMode ? "play.fill" : "heart.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text(isDemoMode ? "Start Demo" : "Start Capture")
                                .font(PulseTypography.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(PulseColors.primaryGradient)
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(
                                        LinearGradient(
                                            colors: [.white.opacity(0.2), .clear],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            }
                        )
                        .shadow(color: PulseColors.primary.opacity(0.4), radius: 12, x: 0, y: 6)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 32)

                    // Demo mode toggle
                    Button {
                        isDemoMode.toggle()
                    } label: {
                        Text(isDemoMode ? "Use Camera Instead" : "Use Demo Mode")
                            .font(PulseTypography.footnote)
                            .foregroundColor(PulseColors.demoBanner)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                } else {
                    Button {
                        stopCapture()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Stop")
                                .font(PulseTypography.headline)
                        }
                        .foregroundColor(PulseColors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(PulseColors.primary.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(PulseColors.primary, lineWidth: 2)
                                )
                        )
                        .shadow(color: PulseColors.primary.opacity(0.15), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .padding(.horizontal, 32)
                }
            }
            .padding(.bottom, 32)
        }
        .onAppear {
            cameraEngine.checkAuthorization()
            #if targetEnvironment(simulator)
            isDemoMode = true
            #else
            isDemoMode = false
            #endif
        }
        .onDisappear {
            stopCapture()
        }
    }

    private func startCapture() {
        processor.reset()
        timeRemaining = PulseConstants.sessionDuration
        isCapturing = true
        PulseHaptics.pulse()

        if isDemoMode {
            let startTime = Date().timeIntervalSince1970
            demoProvider.start { value in
                let timestamp = Date().timeIntervalSince1970
                processor.ingest(value, at: timestamp)
            }
        } else {
            cameraEngine.start(onSample: { brightness, timestamp in
                processor.ingest(brightness, at: timestamp)
            })
            // Keep the Combine sink for UI updates
            cameraCancellable = cameraEngine.$brightness
                .dropFirst()
                .sink { _ in }
        }

        // Countdown timer
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if timeRemaining > 1 {
                    timeRemaining -= 1
                } else {
                    finishCapture()
                }
            }
    }

    private func stopCapture() {
        demoProvider.stop()
        cameraEngine.stop()
        cameraCancellable?.cancel()
        timerCancellable?.cancel()
        isCapturing = false
    }

    private func finishCapture() {
        stopCapture()
        PulseHaptics.success()

        let session = PulseSession(
            id: UUID(),
            date: Date(),
            bpm: processor.sessionAverageBPM,
            confidence: processor.confidence,
            waveform: processor.filteredWaveform,
            isDemo: isDemoMode,
            bloodPressure: nil
        )

        sessionStore.create(session)
        completedSession = session
        showResults = true
    }

    private func resetCapture() {
        completedSession = nil
        showResults = false
        processor.reset()
    }
}
