import SwiftUI

struct OnboardingView: View {
    @Binding var showOnboarding: Bool

    @State private var animatePulse = false

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Animated pulse icon
            ZStack {
                Circle()
                    .fill(PulseColors.primary.opacity(0.15))
                    .frame(width: 160, height: 160)
                    .scaleEffect(animatePulse ? 1.2 : 1.0)

                Circle()
                    .fill(PulseColors.primary.opacity(0.3))
                    .frame(width: 120, height: 120)
                    .scaleEffect(animatePulse ? 1.15 : 1.0)

                Image(systemName: "heart.fill")
                    .font(.system(size: 50))
                    .foregroundColor(PulseColors.primary)
                    .scaleEffect(animatePulse ? 1.1 : 1.0)
            }
            .animation(
                .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                value: animatePulse
            )
            .onAppear { animatePulse = true }

            VStack(spacing: 12) {
                Text("PulseLight")
                    .font(PulseTypography.largeTitle)
                    .foregroundColor(PulseColors.label)
                    .shadow(color: PulseColors.primary.opacity(0.1), radius: 4, x: 0, y: 2)

                Text("See your pulse using light")
                    .font(PulseTypography.title2)
                    .foregroundColor(PulseColors.secondaryLabel)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(icon: "camera.fill", text: "Uses your camera and flashlight")
                FeatureRow(icon: "waveform.path.ecg", text: "Detects your pulse in real-time")
                FeatureRow(icon: "chart.xyaxis.line", text: "Track trends over time")
            }
            .padding(.horizontal, 40)

            Spacer()

            Button {
                PulseHaptics.pulse()
                showOnboarding = false
            } label: {
                HStack(spacing: 10) {
                    Text("Get Started")
                        .font(PulseTypography.headline)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
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
            .padding(.bottom, 40)
        }
        .accessibilityElement(children: .contain)
    }
}

private struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(PulseColors.primary.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(PulseColors.primary)
            }
            Text(text)
                .font(PulseTypography.body)
                .foregroundColor(PulseColors.label)
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
