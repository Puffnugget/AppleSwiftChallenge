import SwiftUI
import Charts

struct WaveformView: View {
    let data: [Double]
    var maxPoints: Int = 200
    var height: CGFloat = 160
    var showGradient: Bool = true
    var showYAxis: Bool = false

    private var samples: [Double] {
        data.count > maxPoints ? Array(data.suffix(maxPoints)) : data
    }

    // Scale signal to fill the chart — even tiny PPG amplitudes become visible
    private var displayData: [(index: Int, value: Double)] {
        let s = samples
        guard let lo = s.min(), let hi = s.max(), hi > lo else {
            return s.enumerated().map { (index: $0.offset, value: 50) }
        }
        let range = hi - lo
        return s.enumerated().map { (index: $0.offset, value: ($0.element - lo) / range * 100) }
    }

    var body: some View {
        Chart(displayData, id: \.index) { point in
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
            LineMark(
                x: .value("Time", point.index),
                y: .value("Amplitude", point.value)
            )
            .foregroundStyle(PulseColors.waveform)
            .lineStyle(StrokeStyle(lineWidth: 2))
        }
        .chartXAxis(.hidden)
        .chartYAxis {
            if showYAxis {
                AxisMarks(position: .leading, values: [0, 25, 50, 75, 100]) { value in
                    AxisGridLine()
                        .foregroundStyle(PulseColors.secondaryLabel.opacity(0.2))
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(String(format: "%.0f", v))
                                .font(PulseTypography.caption2)
                                .foregroundStyle(PulseColors.secondaryLabel)
                        }
                    }
                }
            } else {
                AxisMarks { _ in }
            }
        }
        .chartYScale(domain: 0...100)
        .frame(height: height)
    }
}
