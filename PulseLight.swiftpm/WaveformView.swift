import SwiftUI
import Charts

struct WaveformView: View {
    let data: [Double]
    var maxPoints: Int = 200
    var height: CGFloat = 160
    var showGradient: Bool = true

    private var displayData: [(index: Int, value: Double)] {
        let samples: [Double]
        if data.count > maxPoints {
            samples = Array(data.suffix(maxPoints))
        } else {
            samples = data
        }
        return samples.enumerated().map { (index: $0.offset, value: $0.element) }
    }

    var body: some View {
        Chart(displayData, id: \.index) { point in
            LineMark(
                x: .value("Time", point.index),
                y: .value("Amplitude", point.value)
            )
            .foregroundStyle(PulseColors.waveform)
            .lineStyle(StrokeStyle(lineWidth: 2))

            if showGradient {
                AreaMark(
                    x: .value("Time", point.index),
                    y: .value("Amplitude", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [PulseColors.waveformGradientTop, PulseColors.waveformGradientBottom],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: height)
    }
}
