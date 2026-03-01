import SwiftUI

struct HowItWorksView: View {
    var onContinue: () -> Void

    @State private var showWelcome = true

    private let compactHeightThreshold: CGFloat = 760
    private let steps: [HowItWorksStep] = [
        .init(
            icon: "flashlight.on.fill",
            title: "Light Shines Through",
            description: "The flashlight illuminates your fingertip. Blood absorbs some of the light."
        ),
        .init(
            icon: "camera.fill",
            title: "Camera Captures Changes",
            description: "Each heartbeat pushes more blood through your finger, changing how much light is absorbed."
        ),
        .init(
            icon: "waveform.path.ecg",
            title: "Signal Processing",
            description: "The app analyzes brightness changes frame-by-frame to find the rhythmic pulse pattern."
        ),
        .init(
            icon: "heart.fill",
            title: "Heart Rate Estimated",
            description: "Using frequency analysis (FFT), the dominant pulse frequency is converted to beats per minute."
        )
    ]

    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.height < compactHeightThreshold
            let bottomInset = max(geometry.safeAreaInsets.bottom, 8)

            ZStack {
                if showWelcome {
                    welcomeContent(isCompact: isCompact, bottomInset: bottomInset)
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                } else {
                    stepsContent(isCompact: isCompact, bottomInset: bottomInset)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(
                    colors: [
                        PulseColors.background,
                        PulseColors.primary.opacity(0.03)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.88), value: showWelcome)
        }
    }

    private func welcomeContent(isCompact: Bool, bottomInset: CGFloat) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            VStack(spacing: isCompact ? 18 : 24) {
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: isCompact ? 96 : 120, height: isCompact ? 96 : 120)
                    .clipShape(RoundedRectangle(cornerRadius: isCompact ? 24 : 28, style: .continuous))
                    .shadow(color: PulseColors.primary.opacity(0.2), radius: 10, x: 0, y: 4)

                VStack(spacing: isCompact ? 10 : 14) {
                    Text("Welcome to PulseLight")
                        .font(isCompact ? PulseTypography.title : PulseTypography.largeTitle)
                        .foregroundColor(PulseColors.label)
                        .multilineTextAlignment(.center)

                    Text("Quickly check your pulse\nusing your camera and flashlight.")
                        .font(isCompact ? PulseTypography.subheadline : PulseTypography.callout)
                        .foregroundColor(PulseColors.label)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .lineSpacing(2)
                }

                VStack(alignment: .leading, spacing: isCompact ? 10 : 14) {
                    WelcomeTip(icon: "clock.fill", text: "Takes around 20 seconds", isCompact: isCompact)
                    WelcomeTip(icon: "camera.fill", text: "No external device needed", isCompact: isCompact)
                    WelcomeTip(icon: "heart.fill", text: "See live pulse signal and BPM", isCompact: isCompact)
                }
                .padding(.horizontal, isCompact ? 24 : 32)
                .padding(.top, isCompact ? 4 : 8)

                VStack(spacing: 14) {
                    Button {
                        PulseHaptics.pulse()
                        showWelcome = false
                    } label: {
                        Text("How It Works")
                            .font(PulseTypography.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, isCompact ? 12 : 16)
                            .background(
                                RoundedRectangle(cornerRadius: isCompact ? 14 : 16)
                                    .fill(PulseColors.primaryGradient)
                            )
                            .shadow(color: PulseColors.primary.opacity(0.28), radius: isCompact ? 6 : 8, x: 0, y: 4)
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button {
                        PulseHaptics.pulse()
                        onContinue()
                    } label: {
                        Text("Skip")
                            .font(PulseTypography.subheadline)
                            .foregroundColor(PulseColors.label)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(.top, isCompact ? 18 : 24)
                .padding(.horizontal, isCompact ? 20 : 32)
            }

            Spacer(minLength: bottomInset + 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func stepsContent(isCompact: Bool, bottomInset: CGFloat) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: isCompact ? 8 : 16)

            VStack(spacing: isCompact ? 14 : 18) {
                Text("How It Works")
                    .font(isCompact ? PulseTypography.title : PulseTypography.largeTitle)
                    .foregroundColor(PulseColors.label)

                VStack(spacing: isCompact ? 8 : 11) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        StepCard(
                            number: index + 1,
                            icon: step.icon,
                            title: step.title,
                            description: step.description,
                            isCompact: isCompact
                        )

                        if index < steps.count - 1 {
                            Image(systemName: "arrow.down")
                                .font(isCompact ? .footnote : .subheadline)
                                .foregroundColor(PulseColors.secondaryLabel.opacity(0.85))
                                .padding(.vertical, isCompact ? 1 : 2)
                        }
                    }
                }
                .padding(.horizontal, isCompact ? 16 : 24)

                Text("This technique is called Photoplethysmography (PPG)")
                    .font(isCompact ? PulseTypography.caption2 : PulseTypography.caption)
                    .foregroundColor(PulseColors.secondaryLabel)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                    .padding(.horizontal, isCompact ? 22 : 32)

                Button {
                    PulseHaptics.pulse()
                    onContinue()
                } label: {
                    Text("Try It")
                        .font(PulseTypography.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, isCompact ? 12 : 16)
                        .background(
                            RoundedRectangle(cornerRadius: isCompact ? 14 : 16)
                                .fill(PulseColors.primaryGradient)
                        )
                        .shadow(color: PulseColors.primary.opacity(0.28), radius: isCompact ? 6 : 8, x: 0, y: 4)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, isCompact ? 20 : 32)
            }

            Spacer(minLength: bottomInset + 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct StepCard: View {
    let number: Int
    let icon: String
    let title: String
    let description: String
    let isCompact: Bool

    var body: some View {
        HStack(alignment: .top, spacing: isCompact ? 10 : 12) {
            ZStack {
                Circle()
                    .fill(PulseColors.primary.opacity(0.15))
                    .frame(width: isCompact ? 34 : 44, height: isCompact ? 34 : 44)

                Text("\(number)")
                    .font(isCompact ? PulseTypography.subheadline : PulseTypography.headline)
                    .foregroundColor(PulseColors.primary)
            }

            VStack(alignment: .leading, spacing: isCompact ? 4 : 6) {
                HStack(alignment: .center, spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(PulseColors.primary.opacity(0.12))
                            .frame(width: isCompact ? 18 : 22, height: isCompact ? 18 : 22)

                        Image(systemName: icon)
                            .font(.system(size: isCompact ? 9 : 11, weight: .semibold))
                            .foregroundColor(PulseColors.primary)
                    }

                    Text(title)
                        .font(isCompact ? PulseTypography.bodyBold : PulseTypography.headline)
                        .foregroundColor(PulseColors.label)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)
                }

                Text(description)
                    .font(isCompact ? PulseTypography.caption : PulseTypography.footnote)
                    .foregroundColor(PulseColors.secondaryLabel)
                    .lineLimit(isCompact ? 3 : 4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, isCompact ? 10 : 12)
        .padding(.vertical, isCompact ? 9 : 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: isCompact ? 14 : 16, style: .continuous)
                .fill(PulseColors.cardBackground)
        )
    }
}

private struct WelcomeTip: View {
    let icon: String
    let text: String
    let isCompact: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(PulseColors.primary.opacity(0.12))
                    .frame(width: isCompact ? 24 : 28, height: isCompact ? 24 : 28)

                Image(systemName: icon)
                    .font(.system(size: isCompact ? 11 : 13, weight: .semibold))
                    .foregroundColor(PulseColors.primary)
            }

            Text(text)
                .font(isCompact ? PulseTypography.footnote : PulseTypography.subheadline)
                .foregroundColor(PulseColors.label)

            Spacer(minLength: 0)
        }
        .padding(.vertical, isCompact ? 1 : 2)
    }
}

private struct HowItWorksStep {
    let icon: String
    let title: String
    let description: String
}
