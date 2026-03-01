import SwiftUI
import Charts

struct InsightsView: View {
    @EnvironmentObject var sessionStore: SessionStore
    @State private var selectedSession: PulseSession?
    @State private var systolicText = ""
    @State private var diastolicText = ""
    @State private var pendingDeleteSession: PulseSession?

    private var sortedSessions: [PulseSession] {
        sessionStore.sessions.sorted { $0.date < $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if sessionStore.sessions.isEmpty {
                    emptyState
                } else {
                    if sessionStore.sessions.count < 2 {
                        emptyState
                    } else {
                        bpmTrendSection
                        if hasBPData {
                            bpTrendSection
                        }
                        statsSection
                    }
                    sessionManagementSection
                }
            }
            .padding()
        }
        .navigationTitle("Insights")
        .sheet(item: $selectedSession) { session in
            bpEntrySheet(for: session)
        }
        .alert(item: $pendingDeleteSession) { session in
            Alert(
                title: Text("Delete Session?"),
                message: Text("This removes the session from Insights and Logbook."),
                primaryButton: .destructive(Text("Delete")) {
                    sessionStore.delete(sessionID: session.id)
                },
                secondaryButton: .cancel()
            )
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 60)
            ZStack {
                Circle()
                    .fill(PulseColors.primary.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(PulseColors.primary)
            }
            .shadow(color: PulseColors.primary.opacity(0.15), radius: 8, x: 0, y: 4)
            
            VStack(spacing: 8) {
                Text("More Data Needed")
                    .font(PulseTypography.title)
                    .foregroundColor(PulseColors.label)
                Text("Complete at least 2 sessions\nto see trends")
                    .font(PulseTypography.body)
                    .foregroundColor(PulseColors.secondaryLabel)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
        }
    }

    private var bpmTrendSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(PulseColors.primary)
                Text("Heart Rate Trend")
                    .font(PulseTypography.headline)
                    .foregroundColor(PulseColors.label)
            }

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
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(PulseColors.cardBackground)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .accessibilityLabel("Heart rate trend chart showing \(sortedSessions.count) sessions")
    }

    private var hasBPData: Bool {
        sortedSessions.contains { $0.bloodPressure != nil }
    }

    private var bpSessions: [PulseSession] {
        sortedSessions.filter { $0.bloodPressure != nil }
    }

    private var bpTrendSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(PulseColors.primary)
                Text("Blood Pressure Trend")
                    .font(PulseTypography.headline)
                    .foregroundColor(PulseColors.label)
            }

            Text("From your manual cuff readings")
                .font(PulseTypography.footnote)
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
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(PulseColors.cardBackground)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(PulseColors.primary)
                Text("Statistics")
                    .font(PulseTypography.headline)
                    .foregroundColor(PulseColors.label)
            }

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
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(PulseColors.cardBackground)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }

    private var sessionManagementSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "folder.badge.gearshape")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(PulseColors.primary)
                Text("Session Management")
                    .font(PulseTypography.headline)
                    .foregroundColor(PulseColors.label)
            }

            Text("Create from Measure, update BP, and delete sessions here.")
                .font(PulseTypography.footnote)
                .foregroundColor(PulseColors.secondaryLabel)

            VStack(spacing: 10) {
                ForEach(sessionStore.sessions) { session in
                    InsightSessionRow(
                        session: session,
                        onEditBP: { startEditingBP(session) },
                        onDelete: { pendingDeleteSession = session }
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(PulseColors.cardBackground)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }

    private func bpEntrySheet(for session: PulseSession) -> some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("\(session.formattedBPM) BPM")
                        .font(PulseTypography.title)
                        .foregroundColor(PulseColors.primary)
                    Text(session.formattedDate)
                        .font(PulseTypography.caption)
                        .foregroundColor(PulseColors.secondaryLabel)
                }
                .padding(.top)

                VStack(spacing: 18) {
                    Text("Blood Pressure")
                        .font(PulseTypography.headline)
                        .foregroundColor(PulseColors.label)

                    HStack(spacing: 16) {
                        VStack {
                            Text("Systolic")
                                .font(PulseTypography.caption)
                                .foregroundColor(PulseColors.secondaryLabel)
                            TextField("120", text: $systolicText)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                                .multilineTextAlignment(.center)
                                .frame(width: 100)
                        }

                        Text("/")
                            .font(PulseTypography.title)
                            .foregroundColor(PulseColors.secondaryLabel)

                        VStack {
                            Text("Diastolic")
                                .font(PulseTypography.caption)
                                .foregroundColor(PulseColors.secondaryLabel)
                            TextField("80", text: $diastolicText)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                                .multilineTextAlignment(.center)
                                .frame(width: 100)
                        }
                    }

                    Text("mmHg")
                        .font(PulseTypography.caption)
                        .foregroundColor(PulseColors.secondaryLabel)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(PulseColors.secondaryBackground)
                )
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Edit Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { selectedSession = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveBP()
                    }
                    .disabled(!isValidBP)
                }
            }
        }
    }

    private var isValidBP: Bool {
        guard let sys = Int(systolicText), let dia = Int(diastolicText) else { return false }
        return sys > 50 && sys < 300 && dia > 30 && dia < 200 && sys > dia
    }

    private func startEditingBP(_ session: PulseSession) {
        if let bp = session.bloodPressure {
            systolicText = "\(bp.systolic)"
            diastolicText = "\(bp.diastolic)"
        } else {
            systolicText = ""
            diastolicText = ""
        }
        selectedSession = session
    }

    private func saveBP() {
        guard let session = selectedSession,
              let sys = Int(systolicText),
              let dia = Int(diastolicText) else { return }

        sessionStore.updateBloodPressure(
            for: session.id,
            bp: BloodPressure(systolic: sys, diastolic: dia)
        )
        PulseHaptics.success()
        selectedSession = nil
    }
}

private struct StatCard: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .font(PulseTypography.caption2)
                .foregroundColor(PulseColors.secondaryLabel)
                .textCase(.uppercase)
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(PulseColors.primary)
            Text(unit)
                .font(PulseTypography.caption2)
                .foregroundColor(PulseColors.secondaryLabel)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

private struct InsightSessionRow: View {
    let session: PulseSession
    var onEditBP: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.formattedDate)
                    .font(PulseTypography.subheadline)
                    .foregroundColor(PulseColors.label)

                HStack(spacing: 8) {
                    Text("\(session.formattedBPM) BPM")
                        .font(PulseTypography.caption)
                        .foregroundColor(PulseColors.primary)
                    Text("•")
                        .font(PulseTypography.caption)
                        .foregroundColor(PulseColors.secondaryLabel)
                    Text(session.confidenceLabel)
                        .font(PulseTypography.caption)
                        .foregroundColor(PulseColors.secondaryLabel)
                    if let bp = session.bloodPressure {
                        Text("•")
                            .font(PulseTypography.caption)
                            .foregroundColor(PulseColors.secondaryLabel)
                        Text(bp.formatted)
                            .font(PulseTypography.caption)
                            .foregroundColor(PulseColors.demoBanner)
                    }
                }
            }

            Spacer()

            Button(action: onEditBP) {
                Image(systemName: "pencil")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(PulseColors.primary)
                    .padding(8)
                    .background(PulseColors.primary.opacity(0.12), in: Circle())
            }
            .buttonStyle(.plain)

            Button(action: onDelete) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.red)
                    .padding(8)
                    .background(Color.red.opacity(0.12), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(PulseColors.secondaryBackground)
        )
    }
}
