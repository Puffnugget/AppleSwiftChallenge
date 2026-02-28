import SwiftUI
import Combine

struct CaptureView: View {
    @EnvironmentObject var sessionStore: SessionStore
    @StateObject private var processor = PPGProcessor()
    @StateObject private var demoProvider = DemoSignalProvider()
    @StateObject private var cameraEngine = CameraEngine()

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
                HStack {
                    Image(systemName: "play.rectangle.fill")
                    Text("Running Demo Signal")
                }
                .font(PulseTypography.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(PulseColors.demoBanner, in: Capsule())
                .accessibilityLabel("Demo mode active")
            }

            Spacer()

            // Countdown / status
            if isCapturing {
                VStack(spacing: 8) {
                    Text("\(Int(timeRemaining))s")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(PulseColors.label)
                        .contentTransition(.numericText())

                    if processor.hasValidEstimate {
                        Text("\(Int(processor.currentBPM.rounded())) BPM")
                            .font(PulseTypography.title)
                            .foregroundColor(PulseColors.primary)
                    } else {
                        Text("Analyzing...")
                            .font(PulseTypography.body)
                            .foregroundColor(PulseColors.secondaryLabel)
                    }

                    if processor.confidence > 0 && processor.confidence < 0.4 {
                        Label("Hold still for better accuracy", systemImage: "hand.raised.fill")
                            .font(PulseTypography.caption)
                            .foregroundColor(PulseColors.warning)
                    }
                }

                // Live waveform
                WaveformView(data: processor.filteredWaveform, maxPoints: 150, height: 140)
                    .padding(.horizontal)
            } else {
                // Instructions
                VStack(spacing: 16) {
                    Image(systemName: "hand.point.up.fill")
                        .font(.system(size: 60))
                        .foregroundColor(PulseColors.primary)

                    if !cameraEngine.isAuthorized && !isDemoMode {
                        Text("Camera access is needed for live measurement")
                            .font(PulseTypography.body)
                            .foregroundColor(PulseColors.secondaryLabel)
                            .multilineTextAlignment(.center)
                    } else if !isDemoMode {
                        Text("Place your fingertip over the\nrear camera and flashlight")
                            .font(PulseTypography.body)
                            .foregroundColor(PulseColors.secondaryLabel)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("Demo mode will simulate a pulse signal")
                            .font(PulseTypography.body)
                            .foregroundColor(PulseColors.secondaryLabel)
                            .multilineTextAlignment(.center)
                    }
                }
            }

            Spacer()

            // Controls
            VStack(spacing: 16) {
                if !isCapturing {
                    Button {
                        startCapture()
                    } label: {
                        HStack {
                            Image(systemName: isDemoMode ? "play.fill" : "heart.fill")
                            Text(isDemoMode ? "Start Demo" : "Start Capture")
                        }
                        .font(PulseTypography.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(PulseColors.primary, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 32)

                    // Demo mode toggle
                    Button {
                        isDemoMode.toggle()
                    } label: {
                        Text(isDemoMode ? "Use Camera Instead" : "Use Demo Mode")
                            .font(PulseTypography.caption)
                            .foregroundColor(PulseColors.demoBanner)
                    }
                } else {
                    Button {
                        stopCapture()
                    } label: {
                        Text("Stop")
                            .font(PulseTypography.headline)
                            .foregroundColor(PulseColors.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(PulseColors.primary, lineWidth: 2)
                            )
                    }
                    .padding(.horizontal, 32)
                }
            }
            .padding(.bottom, 32)
        }
        .onAppear {
            // Auto-detect simulator / no camera
            #if targetEnvironment(simulator)
            isDemoMode = true
            #else
            if !cameraEngine.isAuthorized {
                isDemoMode = true
            }
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
            demoProvider.start { value in
                processor.ingest(value)
            }
        } else {
            cameraEngine.start()
            cameraCancellable = cameraEngine.$brightness
                .dropFirst()
                .sink { value in
                    processor.ingest(value)
                }
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
            bpm: processor.currentBPM,
            confidence: processor.confidence,
            waveform: processor.filteredWaveform,
            isDemo: isDemoMode,
            bloodPressure: nil
        )

        completedSession = session
        showResults = true
    }

    private func resetCapture() {
        completedSession = nil
        showResults = false
        processor.reset()
    }
}
