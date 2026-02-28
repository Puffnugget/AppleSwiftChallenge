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

            VStack(spacing: 16) {
                Text("PulseLight")
                    .font(PulseTypography.largeTitle)
                    .foregroundColor(PulseColors.label)

                Text("See your pulse using light")
                    .font(PulseTypography.title)
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
                Text("Get Started")
                    .font(PulseTypography.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(PulseColors.primary, in: RoundedRectangle(cornerRadius: 16))
            }
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
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(PulseColors.primary)
                .frame(width: 32)
            Text(text)
                .font(PulseTypography.body)
                .foregroundColor(PulseColors.label)
        }
    }
}
