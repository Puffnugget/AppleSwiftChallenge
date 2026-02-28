import SwiftUI

struct BPMRingView: View {
    let bpm: Double
    let confidence: Double
    var size: CGFloat = 200

    @State private var animatedProgress: Double = 0
    @State private var showBPM = false

    private var ringColor: Color {
        if confidence >= 0.7 { return PulseColors.confidence }
        if confidence >= 0.4 { return PulseColors.warning }
        return PulseColors.primary
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(ringColor.opacity(0.2), lineWidth: 12)
                .frame(width: size, height: size)

            // Animated progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))

            // BPM text
            VStack(spacing: 4) {
                Text(showBPM ? "\(Int(bpm.rounded()))" : "--")
                    .font(PulseTypography.bpmDisplay)
                    .foregroundColor(PulseColors.label)
                    .contentTransition(.numericText())

                Text("BPM")
                    .font(PulseTypography.bpmUnit)
                    .foregroundColor(PulseColors.secondaryLabel)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedProgress = min(1.0, confidence)
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
