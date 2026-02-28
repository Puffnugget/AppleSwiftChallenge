import SwiftUI
import Charts

struct InsightsView: View {
    @EnvironmentObject var sessionStore: SessionStore

    private var sortedSessions: [PulseSession] {
        sessionStore.sessions.sorted { $0.date < $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if sessionStore.sessions.count < 2 {
                    emptyState
                } else {
                    bpmTrendSection
                    if hasBPData {
                        bpTrendSection
                    }
                    statsSection
                }
            }
            .padding()
        }
        .navigationTitle("Insights")
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 60)
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 60))
                .foregroundColor(PulseColors.secondaryLabel)
            Text("More Data Needed")
                .font(PulseTypography.title)
                .foregroundColor(PulseColors.secondaryLabel)
            Text("Complete at least 2 sessions\nto see trends")
                .font(PulseTypography.body)
                .foregroundColor(PulseColors.secondaryLabel)
                .multilineTextAlignment(.center)
        }
    }

    private var bpmTrendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Heart Rate Trend")
                .font(PulseTypography.headline)
                .foregroundColor(PulseColors.label)

            Chart(sortedSessions) { session in
                LineMark(
                    x: .value("Date", session.date),
                    y: .value("BPM", session.bpm)
                )
                .foregroundStyle(PulseColors.primary)
                .lineStyle(StrokeStyle(lineWidth: 2))

                PointMark(
                    x: .value("Date", session.date),
                    y: .value("BPM", session.bpm)
                )
                .foregroundStyle(PulseColors.primary)
                .symbolSize(40)
            }
            .chartYAxisLabel("BPM")
            .frame(height: 200)
        }
        .padding()
        .background(PulseColors.cardBackground, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityLabel("Heart rate trend chart showing \(sortedSessions.count) sessions")
    }

    private var hasBPData: Bool {
        sortedSessions.contains { $0.bloodPressure != nil }
    }

    private var bpSessions: [PulseSession] {
        sortedSessions.filter { $0.bloodPressure != nil }
    }

    private var bpTrendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Blood Pressure Trend")
                .font(PulseTypography.headline)
                .foregroundColor(PulseColors.label)

            Text("From your manual cuff readings")
                .font(PulseTypography.caption)
                .foregroundColor(PulseColors.secondaryLabel)

            Chart {
                ForEach(bpSessions) { session in
                    if let bp = session.bloodPressure {
                        LineMark(
                            x: .value("Date", session.date),
                            y: .value("Systolic", bp.systolic),
                            series: .value("Type", "Systolic")
                        )
                        .foregroundStyle(PulseColors.primary)

                        PointMark(
                            x: .value("Date", session.date),
                            y: .value("Systolic", bp.systolic)
                        )
                        .foregroundStyle(PulseColors.primary)
                        .symbolSize(30)

                        LineMark(
                            x: .value("Date", session.date),
                            y: .value("Diastolic", bp.diastolic),
                            series: .value("Type", "Diastolic")
                        )
                        .foregroundStyle(PulseColors.demoBanner)

                        PointMark(
                            x: .value("Date", session.date),
                            y: .value("Diastolic", bp.diastolic)
                        )
                        .foregroundStyle(PulseColors.demoBanner)
                        .symbolSize(30)
                    }
                }
            }
            .chartYAxisLabel("mmHg")
            .chartForegroundStyleScale([
                "Systolic": PulseColors.primary,
                "Diastolic": PulseColors.demoBanner
            ])
            .frame(height: 200)
        }
        .padding()
        .background(PulseColors.cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(PulseTypography.headline)
                .foregroundColor(PulseColors.label)

            let bpms = sortedSessions.map(\.bpm)
            let avg = bpms.reduce(0, +) / Double(bpms.count)
            let minBPM = bpms.min() ?? 0
            let maxBPM = bpms.max() ?? 0

            HStack(spacing: 0) {
                StatCard(label: "Average", value: "\(Int(avg.rounded()))", unit: "BPM")
                StatCard(label: "Lowest", value: "\(Int(minBPM.rounded()))", unit: "BPM")
                StatCard(label: "Highest", value: "\(Int(maxBPM.rounded()))", unit: "BPM")
            }

            HStack(spacing: 0) {
                StatCard(label: "Sessions", value: "\(sortedSessions.count)", unit: "total")
                StatCard(label: "Demo", value: "\(sortedSessions.filter(\.isDemo).count)", unit: "sessions")
                StatCard(label: "Live", value: "\(sortedSessions.filter { !$0.isDemo }.count)", unit: "sessions")
            }
        }
        .padding()
        .background(PulseColors.cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct StatCard: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(PulseTypography.caption)
                .foregroundColor(PulseColors.secondaryLabel)
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(PulseColors.primary)
            Text(unit)
                .font(.caption2)
                .foregroundColor(PulseColors.secondaryLabel)
        }
        .frame(maxWidth: .infinity)
    }
}
