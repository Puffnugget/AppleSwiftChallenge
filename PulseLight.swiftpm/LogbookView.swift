import SwiftUI

struct LogbookView: View {
    @EnvironmentObject var sessionStore: SessionStore
    @State private var selectedSession: PulseSession?
    @State private var systolicText = ""
    @State private var diastolicText = ""

    var body: some View {
        Group {
            if sessionStore.sessions.isEmpty {
                emptyState
            } else {
                sessionList
            }
        }
        .navigationTitle("Logbook")
        .sheet(item: $selectedSession) { session in
            bpEntrySheet(for: session)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(PulseColors.primary.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "heart.text.square")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(PulseColors.primary)
            }
            .shadow(color: PulseColors.primary.opacity(0.15), radius: 8, x: 0, y: 4)
            
            VStack(spacing: 8) {
                Text("No sessions yet")
                    .font(PulseTypography.title)
                    .foregroundColor(PulseColors.label)
                Text("Complete a measurement to see it here")
                    .font(PulseTypography.body)
                    .foregroundColor(PulseColors.secondaryLabel)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
        }
        .padding(.top, 60)
    }

    private var sessionList: some View {
        List {
            ForEach(sessionStore.sessions) { session in
                SessionRow(session: session)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if let bp = session.bloodPressure {
                            systolicText = "\(bp.systolic)"
                            diastolicText = "\(bp.diastolic)"
                        } else {
                            systolicText = ""
                            diastolicText = ""
                        }
                        selectedSession = session
                    }
                    .accessibilityLabel("Session on \(session.formattedDate), \(session.formattedBPM) BPM")
                    .accessibilityHint("Tap to add blood pressure reading")
            }
            .onDelete { offsets in
                sessionStore.delete(at: offsets)
            }
        }
        .listStyle(.insetGrouped)
    }

    private func bpEntrySheet(for session: PulseSession) -> some View {
        NavigationView {
            VStack(spacing: 24) {
                // Session summary
                VStack(spacing: 8) {
                    Text("\(session.formattedBPM) BPM")
                        .font(PulseTypography.title)
                        .foregroundColor(PulseColors.primary)
                    Text(session.formattedDate)
                        .font(PulseTypography.caption)
                        .foregroundColor(PulseColors.secondaryLabel)
                }
                .padding(.top)

                // Waveform preview
                WaveformView(data: session.waveform, maxPoints: 200, height: 100)
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(PulseColors.cardBackground)
                            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
                    )
                    .padding(.horizontal)

                // BP entry
                VStack(spacing: 18) {
                    HStack(spacing: 8) {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(PulseColors.primary)
                        Text("Add Blood Pressure Reading")
                            .font(PulseTypography.headline)
                    }

                    Text("Enter your cuff measurement")
                        .font(PulseTypography.footnote)
                        .foregroundColor(PulseColors.secondaryLabel)

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
                        .fill(PulseColors.cardBackground)
                        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
                )
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Session Details")
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

    private func saveBP() {
        guard let session = selectedSession,
              let sys = Int(systolicText),
              let dia = Int(diastolicText) else { return }
        let bp = BloodPressure(systolic: sys, diastolic: dia)
        sessionStore.updateBloodPressure(for: session.id, bp: bp)
        PulseHaptics.success()
        selectedSession = nil
    }
}

private struct SessionRow: View {
    let session: PulseSession

    var body: some View {
        HStack(spacing: 16) {
            // BPM badge
            VStack(spacing: 2) {
                Text(session.formattedBPM)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(PulseColors.primary)
                Text("BPM")
                    .font(PulseTypography.caption2)
                    .foregroundColor(PulseColors.secondaryLabel)
            }
            .frame(width: 64)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(PulseColors.primary.opacity(0.1))
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(session.formattedDate)
                    .font(PulseTypography.body)
                    .foregroundColor(PulseColors.label)

                HStack(spacing: 8) {
                    Text("Quality: \(session.confidenceLabel)")
                        .font(PulseTypography.caption)
                        .foregroundColor(PulseColors.secondaryLabel)

                    if session.isDemo {
                        Text("Demo")
                            .font(.caption2)
                            .foregroundColor(PulseColors.demoBanner)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(PulseColors.demoBanner.opacity(0.12), in: Capsule())
                    }

                    if let bp = session.bloodPressure {
                        Text(bp.formatted)
                            .font(PulseTypography.caption)
                            .foregroundColor(PulseColors.primary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(PulseColors.primary.opacity(0.12), in: Capsule())
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(PulseColors.secondaryLabel)
        }
        .padding(.vertical, 4)
    }
}
