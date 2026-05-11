import SwiftUI

struct GameView: View {
    @EnvironmentObject var session: GameSession
    @State private var answer: String = ""
    @FocusState private var focused: Bool
    @State private var nowTick = Date()
    @State private var lastWarnedSecond: Int = -1

    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 24) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("game.round.label")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(Color.wgMuted)
                        .textCase(.uppercase)
                        .tracking(2)
                    Text("\(session.currentRound) / \(session.totalRounds)")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }
                Spacer()
                StatusPill(
                    text: session.hasSubmittedAnswer
                        ? NSLocalizedString("game.status.waitingOthers", value: "Waiting for others…", comment: "")
                        : NSLocalizedString("game.status.yourTurn", value: "Type your answer", comment: ""),
                    color: session.hasSubmittedAnswer ? .wgWaiting : .wgGood
                )
            }

            Spacer()

            QuestionCard(
                text: session.currentQuestion?.text ?? "",
                answer: answer,
                submitted: session.hasSubmittedAnswer
            )
            .frame(maxWidth: 760)

            Spacer()

            VStack(spacing: 18) {
                CountdownRing(progress: timeProgress, label: "\(remaining)s",
                              size: 120,
                              tint: remaining < 6 ? .wgBad : .wgPrimary)
                    .scaleEffect(remaining < 6 ? 1.04 : 1.0)
                    .animation(.easeOut(duration: 0.3), value: remaining)

                if !session.hasSubmittedAnswer {
                    HStack(spacing: 14) {
                        TextField("game.answer.placeholder", text: $answer)
                            #if os(macOS)
                            .textFieldStyle(.plain)
                            #endif
                            .font(.system(.title2, design: .rounded))
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(.ultraThinMaterial)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(focused ? Color.wgPrimary : Color.white.opacity(0.12), lineWidth: 1.4)
                            )
                            .focused($focused)
                            .onSubmit { submit() }
                        PrimaryButton(title: NSLocalizedString("action.submit", value: "Submit", comment: ""),
                                      systemImage: "paperplane.fill") {
                            submit()
                        }
                    }
                    .frame(maxWidth: 760)
                } else {
                    HStack(spacing: 8) {
                        ProgressView()
                            #if os(macOS)
                            .controlSize(.small)
                            #endif
                            .tint(.wgPrimary)
                        Text("game.waiting.others")
                            .foregroundStyle(Color.wgMuted)
                    }
                }
            }
        }
        .onReceive(timer) { date in
            nowTick = date
            let r = remaining
            if !session.hasSubmittedAnswer && r > 0 && r <= 5 && r != lastWarnedSecond {
                lastWarnedSecond = r
                SoundEngine.shared.timerWarning()
            }
            if !session.hasSubmittedAnswer && r <= 0 {
                submit()
            }
        }
        .onAppear {
            answer = ""
            focused = true
            lastWarnedSecond = -1
            SoundEngine.shared.roundStart()
        }
        .onChange(of: session.currentQuestion?.id) { _, _ in
            answer = ""
            focused = true
            lastWarnedSecond = -1
            SoundEngine.shared.roundStart()
        }
        .onChange(of: session.hasSubmittedAnswer) { _, submitted in
            if submitted { SoundEngine.shared.answerSubmit() }
        }
    }

    private func submit() {
        let value = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty && session.hasSubmittedAnswer { return }
        session.submitAnswer(value)
    }

    private var remaining: Int {
        guard let deadline = session.deadline else { return 0 }
        let r: Double = deadline.timeIntervalSince(nowTick)
        return max(0, Int(r.rounded(.up)))
    }

    private var timeProgress: Double {
        guard let deadline = session.deadline else { return 0 }
        let total = Double(session.config.secondsPerQuestion)
        let leftover: Double = max(0.0, deadline.timeIntervalSince(nowTick))
        let elapsed = total - leftover
        return max(0.0, min(1.0, elapsed / total))
    }
}

private struct QuestionCard: View {
    var text: String
    var answer: String
    var submitted: Bool
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 18) {
            HStack(spacing: 8) {
                Image(systemName: "quote.opening")
                    .foregroundStyle(Color.wgPrimary.opacity(0.6))
                Text("game.completeTheSentence")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Color.wgMuted)
                    .textCase(.uppercase)
                    .tracking(2)
            }
            SentenceText(text: text, blank: blank)
                .frame(maxWidth: .infinity)
        }
        .padding(36)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(colors: [Color.wgPrimary.opacity(0.18), Color.wgAccent.opacity(0.10)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(
                    LinearGradient(colors: [Color.wgPrimary.opacity(0.5), Color.white.opacity(0.06)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1.4
                )
        )
        .shadow(color: Color.wgPrimary.opacity(0.18), radius: 28, y: 14)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 14)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) { appeared = true }
        }
    }

    private var blank: String {
        let trimmed = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return submitted ? "…" : "_____" }
        return trimmed
    }
}
