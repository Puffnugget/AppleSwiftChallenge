import SwiftUI

struct ResultsView: View {
    let session: PulseSession
    var onDismiss: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Text("Your Results")
                    .font(PulseTypography.largeTitle)
                    .foregroundColor(PulseColors.label)
                    .padding(.top, 20)

                // BPM Ring
                BPMRingView(bpm: session.bpm, confidence: session.confidence)

                // Confidence badge
                HStack(spacing: 10) {
                    Image(systemName: confidenceIcon)
                        .font(.system(size: 16, weight: .semibold))
                    Text("Signal Quality: \(session.confidenceLabel)")
                        .font(PulseTypography.bodyBold)
                }
                .foregroundColor(confidenceColor)
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(confidenceColor.opacity(0.15))
                        .shadow(color: confidenceColor.opacity(0.2), radius: 6, x: 0, y: 3)
                )

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
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(PulseColors.primary)
                        Text("Waveform")
                            .font(PulseTypography.headline)
                            .foregroundColor(PulseColors.label)
                    }
                    WaveformView(data: session.waveform, maxPoints: 300, height: 180, showYAxis: true)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(PulseColors.cardBackground)
                        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
                )
                .padding(.horizontal)

                // Actions
                VStack(spacing: 14) {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Session Saved")
                            .font(PulseTypography.headline)
                    }
                    .foregroundColor(PulseColors.confidence)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(PulseColors.confidence.opacity(0.15))
                    )

                    Button {
                        onDismiss()
                    } label: {
                        Text("Measure Again")
                            .font(PulseTypography.headline)
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
