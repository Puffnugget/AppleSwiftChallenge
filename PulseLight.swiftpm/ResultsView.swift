import SwiftUI

struct ResultsView: View {
    let session: PulseSession
    var onDismiss: () -> Void

    @EnvironmentObject var sessionStore: SessionStore
    @State private var saved = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Your Results")
                    .font(PulseTypography.largeTitle)
                    .padding(.top, 20)

                // BPM Ring
                BPMRingView(bpm: session.bpm, confidence: session.confidence)

                // Confidence badge
                HStack {
                    Image(systemName: confidenceIcon)
                    Text("Signal Quality: \(session.confidenceLabel)")
                }
                .font(PulseTypography.body)
                .foregroundColor(confidenceColor)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(confidenceColor.opacity(0.12), in: Capsule())

                if session.isDemo {
                    HStack {
                        Image(systemName: "play.rectangle.fill")
                        Text("Demo Signal")
                    }
                    .font(PulseTypography.caption)
                    .foregroundColor(PulseColors.demoBanner)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(PulseColors.demoBanner.opacity(0.12), in: Capsule())
                }

                // Full waveform
                VStack(alignment: .leading, spacing: 8) {
                    Text("Waveform")
                        .font(PulseTypography.headline)
                        .foregroundColor(PulseColors.label)
                    WaveformView(data: session.waveform, maxPoints: 300, height: 180)
                }
                .padding()
                .background(PulseColors.cardBackground, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

                // Actions
                VStack(spacing: 12) {
                    if !saved {
                        Button {
                            sessionStore.save(session)
                            saved = true
                            PulseHaptics.success()
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.down.fill")
                                Text("Save Session")
                            }
                            .font(PulseTypography.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(PulseColors.primary, in: RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal, 32)
                    } else {
                        Label("Session Saved", systemImage: "checkmark.circle.fill")
                            .font(PulseTypography.headline)
                            .foregroundColor(PulseColors.confidence)
                    }

                    Button {
                        onDismiss()
                    } label: {
                        Text("Measure Again")
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

                // Disclaimer
                Text(PulseConstants.disclaimer)
                    .font(PulseTypography.caption)
                    .foregroundColor(PulseColors.secondaryLabel)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
            }
        }
    }

    private var confidenceIcon: String {
        if session.confidence >= 0.7 { return "checkmark.seal.fill" }
        if session.confidence >= 0.4 { return "exclamationmark.triangle.fill" }
        return "xmark.seal.fill"
    }

    private var confidenceColor: Color {
        if session.confidence >= 0.7 { return PulseColors.confidence }
        if session.confidence >= 0.4 { return PulseColors.warning }
        return PulseColors.primary
    }
}
