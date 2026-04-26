import Foundation
import SwiftUI

@MainActor
final class SinglePlayerDriver: SessionDriver {

    private weak var session: GameSession?
    private let botCount: Int
    private var bots: [Player] = []
    private var questions: [Question] = []
    private var roundIndex: Int = 0
    private var pendingAnswers: [PlayerAnswer] = []
    private var countdownTimer: Timer?
    private var startTimer: Timer?
    private var presetPool: [String] = []
    private var botPool: BotAnswerPool = BotAnswerPool()

    init(session: GameSession, botCount: Int) {
        self.session = session
        self.botCount = max(1, min(7, botCount))
    }

    func bootstrap() {
        guard let session else { return }
        presetPool = LocalizedContent.presets()
        botPool = LocalizedContent.botAnswerPool()

        let me = Player(id: session.localPlayerID, name: session.localPlayerName, isHost: true, isBot: false)
        bots = SinglePlayerDriver.generateBots(count: botCount)

        session.players = [me] + bots
        session.config = GameConfig(
            rounds: session.config.rounds == 0 ? 5 : session.config.rounds,
            secondsPerQuestion: session.config.secondsPerQuestion == 0 ? 25 : session.config.secondsPerQuestion,
            maxPlayers: bots.count + 1
        )
        session.phase = .singlePlayerSetup
    }

    func startGame() {
        guard let session else { return }
        // Pick N random questions.
        let pool = presetPool.isEmpty ? Self.fallbackPresets : presetPool
        let chosen = pool.shuffled().prefix(session.config.rounds).map { Question(text: $0) }
        questions = Array(chosen)
        roundIndex = 0
        session.totalRounds = questions.count
        session.roundResults = []
        session.phase = .countdown
        session.countdownSeconds = 3
        runStartCountdown()
    }

    private func runStartCountdown() {
        guard session != nil else { return }
        startTimer?.invalidate()
        startTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            Task { @MainActor [weak self] in
                guard let self, let session = self.session else { timer.invalidate(); return }
                session.countdownSeconds -= 1
                if session.countdownSeconds <= 0 {
                    timer.invalidate()
                    self.beginNextRound()
                }
            }
        }
    }

    private func beginNextRound() {
        guard let session else { return }
        if roundIndex >= questions.count {
            session.phase = .finalResults
            session.presentedRoundIndex = 0
            return
        }
        let q = questions[roundIndex]
        pendingAnswers = []
        session.currentQuestion = q
        session.currentRound = roundIndex + 1
        session.hasSubmittedAnswer = false
        session.deadline = Date().addingTimeInterval(TimeInterval(session.config.secondsPerQuestion))
        session.phase = .playing
        scheduleBotAnswers(for: q)
        startQuestionTimer()
    }

    private func scheduleBotAnswers(for q: Question) {
        let perQuestion = session?.config.secondsPerQuestion ?? 20
        let timeBudget = Double(max(3, perQuestion - 2))
        let lang = LocalizedContent.languageCode
        let slot = SlotClassifier.classify(q.text, language: lang)
        var pool = botPool.answers(for: slot)
        if pool.isEmpty { pool = Self.fallbackBotAnswers }

        for bot in bots {
            let delay = Double.random(in: 1.5...timeBudget)
            let answer = pool.randomElement() ?? "…"
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.recordAnswer(player: bot, text: answer, question: q)
            }
        }
    }

    private func startQuestionTimer() {
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] timer in
            Task { @MainActor [weak self] in
                guard let self, let session = self.session, let deadline = session.deadline else {
                    timer.invalidate(); return
                }
                // Grace period: the GameView auto-submits at the deadline, but there's
                // a small lag between the user's last keystroke and the answer being
                // recorded. We wait an extra 1.5s before forcing a (timeout) so a
                // late-but-real submit always wins over the placeholder.
                if Date() >= deadline.addingTimeInterval(1.5) {
                    timer.invalidate()
                    self.timeoutCurrentRound()
                }
            }
        }
    }

    func submitAnswer(_ text: String) {
        guard let session, let q = session.currentQuestion else { return }
        guard !session.hasSubmittedAnswer else { return }
        session.hasSubmittedAnswer = true
        let me = Player(id: session.localPlayerID, name: session.localPlayerName, isHost: true)
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let final = trimmed.isEmpty ? String(localized: "answer.empty.placeholder") : trimmed
        recordAnswer(player: me, text: final, question: q)
    }

    private func recordAnswer(player: Player, text: String, question: Question) {
        guard let session, let q = session.currentQuestion, q.id == question.id else { return }
        if pendingAnswers.contains(where: { $0.playerID == player.id }) { return }
        pendingAnswers.append(PlayerAnswer(playerID: player.id, playerName: player.name, questionID: q.id, text: text))
        if pendingAnswers.count >= session.players.count {
            commitRound()
        }
    }

    private func timeoutCurrentRound() {
        guard let session, let q = session.currentQuestion else { return }
        // Auto-fill any missing answers.
        for player in session.players where !pendingAnswers.contains(where: { $0.playerID == player.id }) {
            let placeholder = String(localized: "answer.timeout.placeholder")
            pendingAnswers.append(PlayerAnswer(playerID: player.id, playerName: player.name, questionID: q.id, text: placeholder))
        }
        commitRound()
    }

    private func commitRound() {
        guard let session, let q = session.currentQuestion else { return }
        countdownTimer?.invalidate()
        countdownTimer = nil
        let result = RoundResult(round: roundIndex + 1, total: questions.count, question: q, answers: pendingAnswers)
        session.roundResults.append(result)
        session.deadline = nil
        session.phase = .roundResults
        session.presentedRoundIndex = session.roundResults.count - 1
        roundIndex += 1
    }

    func nextSlide() {
        guard let session else { return }
        if session.presentedRoundIndex + 1 < session.roundResults.count {
            session.presentedRoundIndex += 1
            session.phase = .roundResults
        } else if roundIndex < questions.count {
            beginNextRound()
        } else {
            session.phase = .finalResults
        }
    }

    func leave() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        startTimer?.invalidate()
        startTimer = nil
    }

    func updateConfig(_ config: GameConfig) {
        session?.config = config
    }

    // MARK: - Bot generation

    private static func generateBots(count: Int) -> [Player] {
        let names = LocalizedContent.botNames()
        let pool = names.isEmpty ? fallbackBotNames : names
        var picked: [String] = []
        var available = pool.shuffled()
        for _ in 0..<count {
            if available.isEmpty { available = pool.shuffled() }
            picked.append(available.removeFirst())
        }
        return picked.map { Player(name: $0, isHost: false, isBot: true) }
    }

    private static let fallbackPresets = [
        "I looked at the bottom of the hole and saw §.",
        "My greatest dream is to §.",
        "If I had a superpower, it would be §."
    ]
    private static let fallbackBotAnswers = ["something strange", "a banana", "the answer to life"]
    private static let fallbackBotNames = ["Robo", "Echo", "Pixel", "Nova"]
}

