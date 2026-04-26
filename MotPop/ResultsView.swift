import SwiftUI
import AppKit

struct ResultsView: View {
    @EnvironmentObject var session: GameSession

    var body: some View {
        if session.phase == .finalResults {
            FinalResultsView()
        } else {
            RoundResultsView()
        }
    }
}

private struct RoundResultsView: View {
    @EnvironmentObject var session: GameSession

    var body: some View {
        VStack(spacing: 22) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("results.round.title")
                        .font(.system(.caption, design: .rounded))
                        .textCase(.uppercase)
                        .tracking(2)
                        .foregroundStyle(Color.wgMuted)
                    if let result = currentResult {
                        Text("\(result.round) / \(result.total)")
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                    }
                }
                Spacer()
                StatusPill(text: NSLocalizedString("results.round.results", value: "Round results", comment: ""),
                           color: .wgAccent)
            }

            if let result = currentResult {
                QuestionBanner(question: result.question.text)
                AnswerGrid(question: result.question.text, answers: result.answers)
                    .id(result.id)
            }

            HStack {
                GhostButton(title: NSLocalizedString("action.back", value: "Back", comment: ""),
                            systemImage: "chevron.left") {
                    session.leave()
                }
                Spacer()
                if session.isAdmin {
                    PrimaryButton(title: nextLabel, systemImage: "arrow.right.circle.fill") {
                        session.nextSlide()
                    }
                } else {
                    HStack(spacing: 8) {
                        ProgressView().controlSize(.small).tint(.wgPrimary)
                        Text("results.waitingHost")
                            .foregroundStyle(Color.wgMuted)
                    }
                }
            }
        }
    }

    private var currentResult: RoundResult? {
        guard session.presentedRoundIndex < session.roundResults.count else { return nil }
        return session.roundResults[session.presentedRoundIndex]
    }

    private var nextLabel: String {
        guard let result = currentResult else { return "" }
        if result.round < result.total {
            return NSLocalizedString("results.nextRound", value: "Next round", comment: "")
        } else {
            return NSLocalizedString("results.seeFinal", value: "See final results", comment: "")
        }
    }
}

private struct QuestionBanner: View {
    var question: String

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "text.quote")
                .font(.system(size: 22))
                .foregroundStyle(Color.wgPrimary)
            SentenceText(text: question, blank: "______")
                .font(.system(size: 24, weight: .medium, design: .rounded))
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.wgPrimary.opacity(0.3), lineWidth: 1)
        )
    }
}

private struct AnswerGrid: View {
    var question: String
    var answers: [PlayerAnswer]

    var body: some View {
        let columns = [GridItem(.adaptive(minimum: 280), spacing: 16)]
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(Array(answers.enumerated()), id: \.element.id) { index, answer in
                    AnswerCard(question: question, answer: answer, index: index)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

private struct AnswerCard: View {
    var question: String
    var answer: PlayerAnswer
    var index: Int
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Avatar(name: answer.playerName, size: 36)
                Text(answer.playerName)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
            }
            Divider().background(Color.white.opacity(0.06))
            SentenceText(text: question, blank: answer.text)
                .font(.system(size: 19, weight: .regular, design: .rounded))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.avatarColor(seed: answer.playerName.hashValue).opacity(0.18), .clear],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 14, y: 8)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8).delay(Double(index) * 0.06)) {
                appeared = true
            }
        }
    }
}

// MARK: - Final results

private struct FinalResultsView: View {
    @EnvironmentObject var session: GameSession

    var body: some View {
        ZStack {
            ConfettiView()
                .allowsHitTesting(false)

            VStack(spacing: 22) {
                Spacer()
                Image(systemName: "party.popper.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(colors: [.wgPrimary, .wgAccent],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .shadow(color: .wgPrimary.opacity(0.6), radius: 18)
                Text("results.final.title")
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.white, Color.wgMuted.opacity(0.7)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                Text("results.final.subtitle")
                    .font(.system(.title2, design: .rounded))
                    .foregroundStyle(Color.wgMuted)

                Card {
                    ScrollView {
                        VStack(spacing: 14) {
                            ForEach(session.roundResults) { result in
                                FinalRoundRow(result: result)
                            }
                        }
                    }
                    .frame(maxHeight: 320)
                }
                .frame(maxWidth: 720)

                HStack {
                    Spacer()
                    PrimaryButton(title: NSLocalizedString("action.backToMenu", value: "Back to menu", comment: ""),
                                  systemImage: "house.fill") {
                        session.leave()
                    }
                    Spacer()
                }
                Spacer()
            }
        }
    }
}

private struct FinalRoundRow: View {
    var result: RoundResult

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(String(format: NSLocalizedString("results.round.format", value: "Round %d", comment: ""), result.round))
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Color.wgPrimary)
                Spacer()
            }
            SentenceText(text: result.question.text, blank: "______")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .leading, spacing: 6) {
                ForEach(result.answers) { ans in
                    HStack(spacing: 8) {
                        Avatar(name: ans.playerName, size: 22)
                        Text(ans.playerName)
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(.white)
                        Text("→")
                            .foregroundStyle(Color.wgMuted)
                        Text(ans.text)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(Color.wgPrimary)
                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.04)))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}

// MARK: - Confetti (CAEmitterLayer)

private struct ConfettiView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = ConfettiHostView()
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

private final class ConfettiHostView: NSView {
    private var emitter: CAEmitterLayer?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        setupEmitter()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        setupEmitter()
    }

    override func layout() {
        super.layout()
        emitter?.frame = bounds
        emitter?.emitterPosition = CGPoint(x: bounds.midX, y: bounds.height + 12)
        emitter?.emitterSize = CGSize(width: bounds.width, height: 2)
    }

    private func setupEmitter() {
        let layer = CAEmitterLayer()
        layer.emitterShape = .line
        let colors: [NSColor] = [
            NSColor(srgbRed: 0.96, green: 0.47, blue: 1.0, alpha: 1),
            NSColor(srgbRed: 0.47, green: 0.69, blue: 1.0, alpha: 1),
            NSColor(srgbRed: 1.0, green: 0.92, blue: 0.47, alpha: 1),
            NSColor(srgbRed: 0.47, green: 1.0, blue: 0.65, alpha: 1),
            NSColor(srgbRed: 1.0, green: 0.69, blue: 0.47, alpha: 1)
        ]
        let cells: [CAEmitterCell] = colors.map { color in
            let c = CAEmitterCell()
            c.birthRate = 4
            c.lifetime = 6.5
            c.velocity = 160
            c.velocityRange = 60
            c.emissionLongitude = .pi    // downward
            c.emissionRange = .pi / 5
            c.spin = 3
            c.spinRange = 3
            c.scale = 0.5
            c.scaleRange = 0.25
            c.contents = ConfettiHostView.makeRect(color: color).cgImage(forProposedRect: nil, context: nil, hints: nil)
            return c
        }
        layer.emitterCells = cells
        if let host = self.layer {
            host.addSublayer(layer)
        }
        emitter = layer

        // Burst then taper
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { [weak self] in
            self?.emitter?.birthRate = 0.4
        }
    }

    private static func makeRect(color: NSColor) -> NSImage {
        let size = NSSize(width: 8, height: 14)
        let image = NSImage(size: size)
        image.lockFocus()
        color.setFill()
        NSBezierPath(roundedRect: NSRect(origin: .zero, size: size), xRadius: 1.5, yRadius: 1.5).fill()
        image.unlockFocus()
        return image
    }
}
