import SwiftUI

struct LogbookView: View {
    @EnvironmentObject var sessionStore: SessionStore
    @State private var selectedSession: PulseSession?
    @State private var showBPSheet = false
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
        .sheet(isPresented: $showBPSheet) {
            bpEntrySheet
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 60))
                .foregroundColor(PulseColors.secondaryLabel)
            Text("No sessions yet")
                .font(PulseTypography.title)
                .foregroundColor(PulseColors.secondaryLabel)
            Text("Complete a measurement to see it here")
                .font(PulseTypography.body)
                .foregroundColor(PulseColors.secondaryLabel)
        }
    }

    private var sessionList: some View {
        List {
            ForEach(sessionStore.sessions) { session in
                SessionRow(session: session)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedSession = session
                        if let bp = session.bloodPressure {
                            systolicText = "\(bp.systolic)"
                            diastolicText = "\(bp.diastolic)"
                        } else {
                            systolicText = ""
                            diastolicText = ""
                        }
                        showBPSheet = true
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

    private var bpEntrySheet: some View {
        NavigationView {
            VStack(spacing: 24) {
                if let session = selectedSession {
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

                    // BP entry
                    VStack(spacing: 16) {
                        Text("Add Blood Pressure Reading")
                            .font(PulseTypography.headline)

                        Text("Enter your cuff measurement")
                            .font(PulseTypography.caption)
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
                    .padding()
                    .background(PulseColors.cardBackground, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }

                Spacer()
            }
            .navigationTitle("Session Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showBPSheet = false }
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
        showBPSheet = false
    }
}

private struct SessionRow: View {
    let session: PulseSession

    var body: some View {
        HStack(spacing: 16) {
            // BPM badge
            VStack {
                Text(session.formattedBPM)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(PulseColors.primary)
                Text("BPM")
                    .font(PulseTypography.caption)
                    .foregroundColor(PulseColors.secondaryLabel)
            }
            .frame(width: 60)

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
