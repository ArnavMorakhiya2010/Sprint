import SwiftUI
import SwiftData

/// The Sessions-style dashboard: total time focused, a per-subject breakdown, and the
/// success/failure rate across every logged attempt — Pomodoro and FocusFlight alike.
struct AnalyticsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \FocusSession.startedAt, order: .reverse) private var sessions: [FocusSession]

    private var loggedSessions: [FocusSession] {
        sessions.filter { $0.outcomeValue != .inProgress }
    }

    private var successSessions: [FocusSession] {
        sessions.filter { $0.outcomeValue == .success }
    }

    private var failureSessions: [FocusSession] {
        sessions.filter { $0.outcomeValue == .failure }
    }

    private var totalFocusedMinutes: Int {
        successSessions.reduce(0) { $0 + $1.actualDurationSeconds } / 60
    }

    private var successRatePercent: Int {
        guard !loggedSessions.isEmpty else { return 0 }
        return Int((Double(successSessions.count) / Double(loggedSessions.count) * 100).rounded())
    }

    private var subjectBreakdown: [(name: String, minutes: Int)] {
        let grouped = Dictionary(grouping: successSessions) { $0.subject?.name ?? "General" }
        return grouped
            .map { (name: $0.key, minutes: $0.value.reduce(0) { $0 + $1.actualDurationSeconds } / 60) }
            .filter { $0.minutes > 0 }
            .sorted { $0.minutes > $1.minutes }
    }

    var body: some View {
        ZStack {
            Color.theme.pearl.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header

                    if loggedSessions.isEmpty {
                        emptyState
                    } else {
                        statTiles
                        if !subjectBreakdown.isEmpty {
                            subjectSection
                        }
                        recentSessionsSection
                    }
                }
                .padding(24)
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Analytics")
                .font(.theme.display(30))
                .foregroundStyle(Color.theme.leather)
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.theme.leather)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.theme.khaki))
            }
        }
        .padding(.top, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color.theme.taupe)
            Text("No sessions yet")
                .font(.theme.header(20))
                .foregroundStyle(Color.theme.leather)
            Text("Run a Pomodoro or a FocusFlight and your stats will show up here.")
                .font(.theme.body(14))
                .foregroundStyle(Color.theme.leather.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private var statTiles: some View {
        HStack(spacing: 12) {
            statTile(title: "FOCUSED", value: focusedLabel, systemImage: "clock.fill")
            statTile(title: "SUCCESS RATE", value: "\(successRatePercent)%", systemImage: "checkmark.seal.fill")
            statTile(title: "SESSIONS", value: "\(loggedSessions.count)", systemImage: "list.bullet")
        }
    }

    private var focusedLabel: String {
        let hours = totalFocusedMinutes / 60
        let minutes = totalFocusedMinutes % 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }

    private func statTile(title: String, value: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 16))
                .foregroundStyle(Color.theme.taupe)
            Text(value)
                .font(.theme.header(20))
                .monospacedDigit()
                .foregroundStyle(Color.theme.leather)
            Text(title)
                .font(.theme.caption(10))
                .foregroundStyle(Color.theme.leather.opacity(0.5))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.theme.white))
    }

    private var subjectSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By subject")
                .font(.theme.header(18))
                .foregroundStyle(Color.theme.leather)

            let maxMinutes = subjectBreakdown.first?.minutes ?? 1

            VStack(spacing: 10) {
                ForEach(subjectBreakdown, id: \.name) { entry in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(entry.name)
                                .font(.theme.body(14))
                                .foregroundStyle(Color.theme.leather)
                            Spacer()
                            Text("\(entry.minutes)m")
                                .font(.theme.caption(12))
                                .foregroundStyle(Color.theme.leather.opacity(0.6))
                        }

                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.theme.taupe)
                                .frame(width: geo.size.width * CGFloat(entry.minutes) / CGFloat(maxMinutes), height: 8)
                        }
                        .frame(height: 8)
                    }
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.theme.white))
        }
    }

    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent sessions")
                .font(.theme.header(18))
                .foregroundStyle(Color.theme.leather)

            VStack(spacing: 1) {
                ForEach(loggedSessions.prefix(20)) { session in
                    sessionRow(session)
                }
            }
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.theme.white))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func sessionRow(_ session: FocusSession) -> some View {
        HStack(spacing: 12) {
            Image(systemName: session.outcomeValue == .success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(session.outcomeValue == .success ? Color.theme.taupe : Color.theme.cacao)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.subject?.name ?? "General")
                    .font(.theme.body(14))
                    .foregroundStyle(Color.theme.leather)
                Text(session.modeValue.displayName)
                    .font(.theme.caption(11))
                    .foregroundStyle(Color.theme.leather.opacity(0.5))
            }

            Spacer()

            Text("\(session.plannedDurationSeconds / 60)m")
                .font(.theme.caption(12))
                .monospacedDigit()
                .foregroundStyle(Color.theme.leather.opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.theme.white)
    }
}
