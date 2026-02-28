import SwiftUI

struct HowItWorksView: View {
    var onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Text("How It Works")
                    .font(PulseTypography.largeTitle)
                    .padding(.top, 20)

                // PPG Diagram
                VStack(spacing: 24) {
                    StepCard(
                        number: 1,
                        icon: "flashlight.on.fill",
                        title: "Light Shines Through",
                        description: "The flashlight illuminates your fingertip. Blood absorbs some of the light."
                    )

                    Image(systemName: "arrow.down")
                        .font(.title2)
                        .foregroundColor(PulseColors.secondaryLabel)

                    StepCard(
                        number: 2,
                        icon: "camera.fill",
                        title: "Camera Captures Changes",
                        description: "Each heartbeat pushes more blood through your finger, changing how much light is absorbed."
                    )

                    Image(systemName: "arrow.down")
                        .font(.title2)
                        .foregroundColor(PulseColors.secondaryLabel)

                    StepCard(
                        number: 3,
                        icon: "waveform.path.ecg",
                        title: "Signal Processing",
                        description: "The app analyzes brightness changes frame-by-frame to find the rhythmic pulse pattern."
                    )

                    Image(systemName: "arrow.down")
                        .font(.title2)
                        .foregroundColor(PulseColors.secondaryLabel)

                    StepCard(
                        number: 4,
                        icon: "heart.fill",
                        title: "Heart Rate Estimated",
                        description: "Using frequency analysis (FFT), the dominant pulse frequency is converted to beats per minute."
                    )
                }
                .padding(.horizontal)

                Text("This technique is called\nPhotoplethysmography (PPG)")
                    .font(PulseTypography.caption)
                    .foregroundColor(PulseColors.secondaryLabel)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)

                Button {
                    PulseHaptics.pulse()
                    onContinue()
                } label: {
                    Text("Try It")
                        .font(PulseTypography.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(PulseColors.primary, in: RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }
}

private struct StepCard: View {
    let number: Int
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(PulseColors.primary.opacity(0.15))
                    .frame(width: 50, height: 50)
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(PulseColors.primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(PulseTypography.headline)
                    .foregroundColor(PulseColors.label)
                Text(description)
                    .font(PulseTypography.caption)
                    .foregroundColor(PulseColors.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PulseColors.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }
}
