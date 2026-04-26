import Foundation
import Network
import SwiftUI

// MARK: - Host

@MainActor
final class HostDriver: SessionDriver {

    private weak var session: GameSession?
    private var hostService: HostService?
    private var peers: [PeerConnection] = []
    private var pendingAnswers: [PlayerAnswer] = []
    private var questions: [Question] = []
    private var roundIndex: Int = 0
    private var presetPool: [String] = []
    private var startCountdownTimer: Timer?
    private var questionTimer: Timer?

    init(session: GameSession) {
        self.session = session
    }

    func bootstrap() {
        guard let session else { return }
        presetPool = LocalizedContent.presets()
        let me = Player(id: session.localPlayerID, name: session.localPlayerName, isHost: true)
        session.players = [me]
        session.config = GameConfig()
        session.hostServiceName = HostDriver.makeServiceName(for: session.localPlayerName)
        session.phase = .hostLobby

        let service = HostService(serviceName: session.hostServiceName)
        service.onAccepted = { [weak self] peer in self?.handleNewPeer(peer) }
        service.onError = { [weak self] error in
            self?.session?.errorMessage = error.localizedDescription
        }
        service.start()
        hostService = service
        broadcastLobby()
    }

    private static func makeServiceName(for hostName: String) -> String {
        let trimmed = hostName.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = trimmed.isEmpty ? NSUserName() : trimmed
        let format = NSLocalizedString("host.service.name", value: "%@'s Mot Pop", comment: "Bonjour service name")
        return String(format: format, base)
    }

    private func handleNewPeer(_ peer: PeerConnection) {
        peers.append(peer)
        peer.onMessage = { [weak self, weak peer] msg in
            guard let self, let peer else { return }
            self.handleClientMessage(msg, from: peer)
        }
        peer.onClosed = { [weak self, weak peer] _ in
            guard let self, let peer else { return }
            self.peers.removeAll { $0 === peer }
            if let pid = peer.playerID {
                self.session?.players.removeAll { $0.id == pid }
                self.broadcastLobby()
            }
        }
    }

    private func handleClientMessage(_ msg: WireMessage, from peer: PeerConnection) {
        guard let session else { return }
        switch msg {
        case .hello(let name, let playerID):
            if session.players.count >= session.config.maxPlayers {
                peer.send(.error(message: NSLocalizedString("error.lobbyFull", value: "The lobby is full.", comment: "")))
                peer.close()
                return
            }
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanName = trimmed.isEmpty ? NSLocalizedString("player.guest", value: "Guest", comment: "") : trimmed
            peer.playerID = playerID
            peer.playerName = cleanName
            let player = Player(id: playerID, name: cleanName, isHost: false)
            session.players.append(player)
            peer.send(.youAre(playerID: playerID, isAdmin: false))
            broadcastLobby()

        case .answer(let questionID, let text):
            guard session.phase == .playing,
                  let q = session.currentQuestion, q.id == questionID,
                  let pid = peer.playerID,
                  let name = peer.playerName,
                  !pendingAnswers.contains(where: { $0.playerID == pid }) else { return }
            let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            let final = cleanText.isEmpty ? NSLocalizedString("answer.empty.placeholder", value: "(no answer)", comment: "") : cleanText
            pendingAnswers.append(PlayerAnswer(playerID: pid, playerName: name, questionID: q.id, text: final))
            checkRoundComplete()

        default:
            break
        }
    }

    func updateConfig(_ config: GameConfig) {
        session?.config = config
        broadcastLobby()
    }

    func startGame() {
        guard let session, !session.players.isEmpty else { return }
        let pool = presetPool.isEmpty ? Self.fallbackPresets : presetPool
        questions = Array(pool.shuffled().prefix(session.config.rounds)).map { Question(text: $0) }
        roundIndex = 0
        session.totalRounds = questions.count
        session.roundResults = []
        session.phase = .countdown
        session.countdownSeconds = 5
        broadcast(.startCountdown(seconds: session.countdownSeconds))
        startCountdownTimer?.invalidate()
        startCountdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            Task { @MainActor [weak self] in
                guard let self, let session = self.session else { timer.invalidate(); return }
                session.countdownSeconds -= 1
                self.broadcast(.startCountdown(seconds: session.countdownSeconds))
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
            broadcast(.gameOver)
            return
        }
        let q = questions[roundIndex]
        pendingAnswers = []
        session.currentQuestion = q
        session.currentRound = roundIndex + 1
        session.hasSubmittedAnswer = false
        let deadline = Date().addingTimeInterval(TimeInterval(session.config.secondsPerQuestion))
        session.deadline = deadline
        session.phase = .playing
        broadcast(.question(round: session.currentRound, total: questions.count, question: q,
                            deadlineEpoch: deadline.timeIntervalSince1970))
        startQuestionTimer()
    }

    private func startQuestionTimer() {
        questionTimer?.invalidate()
        questionTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] timer in
            Task { @MainActor [weak self] in
                guard let self, let session = self.session, let deadline = session.deadline else {
                    timer.invalidate(); return
                }
                // Grace window so late-but-real client submits always beat the
                // (timeout) placeholder.
                if Date() >= deadline.addingTimeInterval(1.5) {
                    timer.invalidate()
                    self.timeoutCurrentRound()
                }
            }
        }
    }

    func submitAnswer(_ text: String) {
        guard let session, let q = session.currentQuestion else { return }
        let me = session.localPlayerID
        if pendingAnswers.contains(where: { $0.playerID == me }) { return }
        session.hasSubmittedAnswer = true
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let final = trimmed.isEmpty ? NSLocalizedString("answer.empty.placeholder", value: "(no answer)", comment: "") : trimmed
        pendingAnswers.append(PlayerAnswer(playerID: me, playerName: session.localPlayerName, questionID: q.id, text: final))
        checkRoundComplete()
    }

    private func checkRoundComplete() {
        guard let session else { return }
        if pendingAnswers.count >= session.players.count {
            commitRound()
        }
    }

    private func timeoutCurrentRound() {
        guard let session, let q = session.currentQuestion else { return }
        for player in session.players where !pendingAnswers.contains(where: { $0.playerID == player.id }) {
            let placeholder = NSLocalizedString("answer.timeout.placeholder", value: "(timeout)", comment: "")
            pendingAnswers.append(PlayerAnswer(playerID: player.id, playerName: player.name, questionID: q.id, text: placeholder))
        }
        commitRound()
    }

    private func commitRound() {
        guard let session, let q = session.currentQuestion else { return }
        questionTimer?.invalidate()
        questionTimer = nil
        let result = RoundResult(round: roundIndex + 1, total: questions.count, question: q, answers: pendingAnswers)
        session.roundResults.append(result)
        session.deadline = nil
        session.phase = .roundResults
        session.presentedRoundIndex = session.roundResults.count - 1
        roundIndex += 1
        broadcast(.roundResults(round: result.round, total: result.total, question: q, answers: pendingAnswers))
    }

    func nextSlide() {
        guard let session else { return }
        if session.presentedRoundIndex + 1 < session.roundResults.count {
            session.presentedRoundIndex += 1
            session.phase = .roundResults
            let r = session.roundResults[session.presentedRoundIndex]
            broadcast(.roundResults(round: r.round, total: r.total, question: r.question, answers: r.answers))
        } else if roundIndex < questions.count {
            beginNextRound()
        } else {
            session.phase = .finalResults
            broadcast(.gameOver)
        }
    }

    func kick(_ player: Player) {
        guard let session else { return }
        if player.id == session.localPlayerID { return }
        if let peer = peers.first(where: { $0.playerID == player.id }) {
            peer.send(.kick(playerID: player.id))
            peer.close()
        }
        session.players.removeAll { $0.id == player.id }
        broadcastLobby()
    }

    func leave() {
        startCountdownTimer?.invalidate()
        questionTimer?.invalidate()
        for peer in peers { peer.close() }
        peers = []
        hostService?.stop()
        hostService = nil
    }

    // MARK: - Broadcasting

    private func broadcastLobby() {
        guard let session else { return }
        let msg = WireMessage.lobby(players: session.players, config: session.config, status: phaseString(session.phase))
        for peer in peers { peer.send(msg) }
    }

    private func broadcast(_ msg: WireMessage) {
        for peer in peers { peer.send(msg) }
    }

    private func phaseString(_ phase: SessionPhase) -> String {
        switch phase {
        case .menu, .singlePlayerSetup: return "menu"
        case .hostLobby, .browsing, .clientLobby: return "lobby"
        case .countdown: return "starting"
        case .playing: return "playing"
        case .roundResults, .finalResults: return "results"
        }
    }

    private static let fallbackPresets = [
        "I looked at the bottom of the hole and saw §.",
        "My greatest dream is to §."
    ]
}

// MARK: - Client

@MainActor
final class ClientDriver: SessionDriver {

    private weak var session: GameSession?
    private var browser: BrowserService?
    private var endpoints: [String: NWEndpoint] = [:]
    private var peer: PeerConnection?

    init(session: GameSession) {
        self.session = session
    }

    func bootstrap() {
        guard let session else { return }
        session.phase = .browsing
        session.discoveredHosts = []
        let svc = BrowserService()
        svc.onChange = { [weak self] hosts, eps in
            self?.session?.discoveredHosts = hosts
            self?.endpoints = eps
        }
        svc.start()
        browser = svc
    }

    func connect(to host: DiscoveredHost) {
        guard let endpoint = endpoints[host.id] else { return }
        browser?.stop()
        browser = nil

        let peer = PeerConnection(endpoint: endpoint)
        self.peer = peer
        peer.onReady = { [weak self] in
            guard let self, let session = self.session else { return }
            peer.send(.hello(name: session.localPlayerName, playerID: session.localPlayerID))
            session.phase = .clientLobby
        }
        peer.onMessage = { [weak self] msg in
            self?.handleHostMessage(msg)
        }
        peer.onClosed = { [weak self] _ in
            guard let session = self?.session else { return }
            session.errorMessage = NSLocalizedString("error.disconnected", value: "Disconnected from host.", comment: "")
            session.resetForMenu()
        }
        peer.start()
    }

    private func handleHostMessage(_ msg: WireMessage) {
        guard let session else { return }
        switch msg {
        case .youAre(_, let isAdmin):
            session.isAdmin = isAdmin

        case .lobby(let players, let config, _):
            session.players = players
            session.config = config

        case .startCountdown(let seconds):
            session.countdownSeconds = seconds
            if seconds > 0 { session.phase = .countdown }

        case .question(let round, let total, let q, let deadlineEpoch):
            session.currentQuestion = q
            session.currentRound = round
            session.totalRounds = total
            session.deadline = Date(timeIntervalSince1970: deadlineEpoch)
            session.hasSubmittedAnswer = false
            session.phase = .playing

        case .roundResults(let round, let total, let q, let answers):
            let result = RoundResult(round: round, total: total, question: q, answers: answers)
            if let existing = session.roundResults.firstIndex(where: { $0.round == round }) {
                session.roundResults[existing] = result
                session.presentedRoundIndex = existing
            } else {
                session.roundResults.append(result)
                session.presentedRoundIndex = session.roundResults.count - 1
            }
            session.phase = .roundResults

        case .gameOver:
            session.phase = .finalResults

        case .kick(let pid):
            if pid == session.localPlayerID {
                session.errorMessage = NSLocalizedString("error.kicked", value: "You were removed by the host.", comment: "")
                session.resetForMenu()
            }

        case .error(let m):
            session.errorMessage = m

        default:
            break
        }
    }

    func submitAnswer(_ text: String) {
        guard let session, let q = session.currentQuestion else { return }
        // Mark locally so the UI flips to "waiting for others"; the host has
        // the authoritative record.
        session.hasSubmittedAnswer = true
        peer?.send(.answer(questionID: q.id, text: text))
    }

    func leave() {
        browser?.stop()
        browser = nil
        peer?.close()
        peer = nil
    }
}
