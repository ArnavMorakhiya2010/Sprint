import SwiftUI
import SwiftData

/// The Home/Focus tab — portrait, reachable from the tab bar rather than gated behind
/// physically rotating the device. Hosts session setup (subject, duration, mode); once
/// `engine.start()` is called, the deep-focus phases (armed/running/forfeited/audit/
/// cooldown, where the leaning/landscape enforcement actually happens) take over as a
/// full-screen cover.
struct HomeTabView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var soundscape: SoundscapePlayer
    @Query(sort: \Subject.name) private var subjects: [Subject]
    @StateObject private var engine = FocusEngine()
    @State private var showingChatbot = false

    private var isSessionPresented: Binding<Bool> {
        Binding(
            get: { engine.phase != .configuring },
            set: { presented in if !presented { engine.reset() } }
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header

                if engine.selectedMode == .pomodoro {
                    subjectPicker

                    PomodoroCardView(
                        fraction: dialFraction,
                        timeText: formatted(seconds: engine.plannedMinutes * 60),
                        onReset: { engine.setPlannedMinutes(25) },
                        onDrag: { location, center in
                            let fraction = PomTimerRing<Color>.resolvedFraction(for: location, center: center)
                            let minutes = engine.minMinutes + Int((fraction * Double(engine.maxMinutes - engine.minMinutes)).rounded())
                            engine.setPlannedMinutes(minutes)
                        }
                    )
                } else {
                    flightBoardingPass
                }

                modeToggle
                startButton
            }
            .padding(24)
            .padding(.bottom, 90)
        }
        .background(Color.theme.cream.ignoresSafeArea())
        .onAppear { engine.configure(context: modelContext) }
        .fullScreenCover(isPresented: isSessionPresented) {
            FocusSessionView(engine: engine)
                .environmentObject(soundscape)
        }
        .sheet(isPresented: $showingChatbot) {
            ChatbotView()
        }
    }

    private var header: some View {
        HStack {
            PomMascotView(pose: .idle, size: 56)
            VStack(alignment: .leading, spacing: 2) {
                Text("Ready to focus?")
                    .font(.theme.h2())
                    .foregroundStyle(Color.theme.espresso)
                Text(engine.selectedMode == .focusFlight ? "Pick a route and check in." : "Set your duration and go.")
                    .font(.theme.bodyMedium2())
                    .foregroundStyle(Color.theme.espresso.opacity(0.6))
            }
            Spacer()
            Button(action: { showingChatbot = true }) {
                Image(systemName: "message.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.theme.espresso)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color.white))
            }
            soundscapeControl
        }
    }

    private var soundscapeControl: some View {
        Menu {
            ForEach(Soundscape.allCases) { option in
                Button {
                    soundscape.current = option
                } label: {
                    Label(option.label, systemImage: option.systemImage)
                }
            }
        } label: {
            Image(systemName: soundscape.current.systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.theme.espresso)
                .frame(width: 38, height: 38)
                .background(Circle().fill(Color.white))
        }
    }

    private var dialFraction: Double {
        Double(engine.plannedMinutes - engine.minMinutes) / Double(engine.maxMinutes - engine.minMinutes)
    }

    private var subjectPicker: some View {
        Menu {
            Button("General") { engine.selectedSubject = nil }
            ForEach(subjects) { subject in
                Button(subject.name) { engine.selectedSubject = subject }
            }
        } label: {
            HStack(spacing: 6) {
                Text((engine.selectedSubject?.name ?? "GENERAL").uppercased())
                    .font(.theme.bodySmall())
                    .foregroundStyle(Color.theme.espresso.opacity(0.6))
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.theme.espresso.opacity(0.6))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.white))
        }
    }

    private var modeToggle: some View {
        HStack(spacing: 0) {
            modeButton(.pomodoro, label: "POMODORO")
            modeButton(.focusFlight, label: "FOCUSFLIGHT")
        }
        .padding(4)
        .background(Capsule().fill(Color.theme.peach.opacity(0.4)))
    }

    private func modeButton(_ mode: SessionMode, label: String) -> some View {
        let isSelected = engine.selectedMode == mode
        return Button {
            engine.selectedMode = mode
        } label: {
            Text(label)
                .font(.theme.bodySmall())
                .foregroundStyle(isSelected ? Color.theme.cream : Color.theme.espresso.opacity(0.6))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(isSelected ? Color.theme.orange : Color.clear))
        }
    }

    // MARK: - FocusFlight boarding pass

    private var flightBoardingPass: some View {
        VStack(spacing: 20) {
            HStack(spacing: 0) {
                codeColumn(title: "DEPARTURE", selection: $engine.departure)

                VStack(spacing: 6) {
                    Image(systemName: "airplane")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.theme.orange)
                    Rectangle()
                        .fill(Color.theme.peach)
                        .frame(height: 1)
                }
                .frame(width: 56)

                codeColumn(title: "ARRIVAL", selection: $engine.arrival)
            }

            if let departure = engine.departure, let arrival = engine.arrival {
                HStack {
                    flightStat(title: "DURATION", value: FlightCalculator.durationLabel(from: departure, to: arrival), alignment: .leading)
                    Spacer()
                    flightStat(title: "DISTANCE", value: "\(Int(FlightCalculator.distanceKm(from: departure, to: arrival))) km", alignment: .trailing)
                }
            }

            barcode
        }
        .padding(24)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color.white))
        .shadow(color: Color.theme.espresso.opacity(0.1), radius: 12, y: 6)
    }

    private func codeColumn(title: String, selection: Binding<Destination?>) -> some View {
        Menu {
            ForEach(Destination.all) { destination in
                Button("\(destination.flag) \(destination.name)") {
                    selection.wrappedValue = destination
                }
            }
        } label: {
            VStack(spacing: 6) {
                Text(title)
                    .font(.theme.bodySmall())
                    .foregroundStyle(Color.theme.espresso.opacity(0.5))
                Text(selection.wrappedValue?.code ?? "---")
                    .font(.theme.h1Small())
                    .foregroundStyle(Color.theme.espresso)
                Text(selection.wrappedValue?.name ?? "Select")
                    .font(.theme.bodyMedium2())
                    .foregroundStyle(Color.theme.orange)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func flightStat(title: String, value: String, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(title)
                .font(.theme.bodySmall())
                .foregroundStyle(Color.theme.espresso.opacity(0.45))
            Text(value)
                .font(.theme.h3())
                .foregroundStyle(Color.theme.espresso)
        }
    }

    private var barcode: some View {
        HStack(spacing: 3) {
            ForEach(0..<28, id: \.self) { index in
                Rectangle()
                    .fill(Color.theme.espresso)
                    .frame(width: barWidth(for: index))
            }
        }
        .frame(height: 32)
    }

    private func barWidth(for index: Int) -> CGFloat {
        let pattern: [CGFloat] = [2, 1, 3, 1, 1, 2, 3, 1, 2, 1]
        return pattern[index % pattern.count]
    }

    private var startButton: some View {
        Button(action: engine.start) {
            Text(engine.selectedMode == .focusFlight ? "CHECK IN" : "START")
                .font(.theme.button())
                .foregroundStyle(Color.theme.cream)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Capsule().fill(engine.canStart ? Color.theme.orange : Color.theme.peach))
        }
        .disabled(!engine.canStart)
    }

    private func formatted(seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
