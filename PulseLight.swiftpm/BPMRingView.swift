import SwiftUI

struct BPMRingView: View {
    let bpm: Double
    let confidence: Double
    var size: CGFloat = 200

    @State private var animatedProgress: Double = 0
    @State private var showBPM = false

    private let ringColor: Color = PulseColors.primary

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(ringColor.opacity(0.15), lineWidth: 14)
                .frame(width: size, height: size)

            // Animated progress ring with gradient
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        colors: [ringColor, ringColor.opacity(0.7)],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .shadow(color: ringColor.opacity(0.3), radius: 8, x: 0, y: 4)

            // BPM text
            VStack(spacing: 6) {
                Text(showBPM ? "\(Int(bpm.rounded()))" : "--")
                    .font(PulseTypography.bpmDisplay)
                    .foregroundColor(PulseColors.label)
                    .contentTransition(.numericText())
                    .shadow(color: PulseColors.primary.opacity(0.15), radius: 4, x: 0, y: 2)

                Text("BPM")
                    .font(PulseTypography.bpmUnit)
                    .foregroundColor(PulseColors.secondaryLabel)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedProgress = 1.0
            }
            withAnimation(.easeIn(duration: 0.5).delay(0.3)) {
                showBPM = true
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Heart rate: \(Int(bpm.rounded())) beats per minute. Confidence: \(confidenceText)")
    }

    private var confidenceText: String {
        if confidence >= 0.7 { return "Good" }
        if confidence >= 0.4 { return "Fair" }
        return "Poor"
    }
}
