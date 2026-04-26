import Foundation
import SwiftUI
import Combine
import Network

@MainActor
final class GameSession: ObservableObject {

    // MARK: - Published state

    @Published var phase: SessionPhase = .menu
    @Published var mode: SessionMode = .none

    @Published var localPlayerName: String = GameSession.defaultPlayerName()
    @Published var localPlayerID: UUID = UUID()

    @Published var players: [Player] = []
    @Published var config: GameConfig = GameConfig()
    @Published var hostServiceName: String = ""

    // Browse / connect
    @Published var discoveredHosts: [DiscoveredHost] = []

    // Active round
    @Published var currentQuestion: Question?
    @Published var currentRound: Int = 0
    @Published var totalRounds: Int = 0
    @Published var deadline: Date?
    @Published var hasSubmittedAnswer: Bool = false

    // Results
    @Published var roundResults: [RoundResult] = []
    @Published var presentedRoundIndex: Int = 0

    // Errors / status
    @Published var errorMessage: String?
    @Published var statusMessage: String?
    @Published var countdownSeconds: Int = 0
    @Published var isAdmin: Bool = false

    // UI overlays
    @Published var showHowToPlay: Bool = false

    // MARK: - Driver

    private(set) var driver: SessionDriver?

    // MARK: - Lifecycle

    func resetForMenu() {
        driver?.leave()
        driver = nil
        mode = .none
        players = []
        currentQuestion = nil
        currentRound = 0
        totalRounds = 0
        deadline = nil
        hasSubmittedAnswer = false
        roundResults = []
        presentedRoundIndex = 0
        errorMessage = nil
        statusMessage = nil
        countdownSeconds = 0
        discoveredHosts = []
        isAdmin = false
        phase = .menu
    }

    // MARK: - Mode entry points

    func startSinglePlayer(rounds: Int, bots: Int) {
        resetForMenu()
        mode = .singlePlayer
        config = GameConfig(rounds: rounds, secondsPerQuestion: 25, maxPlayers: bots + 1)
        let driver = SinglePlayerDriver(session: self, botCount: bots)
        self.driver = driver
        isAdmin = true
        driver.bootstrap()
    }

    func startHosting() {
        resetForMenu()
        mode = .host
        let driver = HostDriver(session: self)
        self.driver = driver
        isAdmin = true
        driver.bootstrap()
    }

    func startBrowsing() {
        resetForMenu()
        mode = .client
        let driver = ClientDriver(session: self)
        self.driver = driver
        isAdmin = false
        driver.bootstrap()
    }

    // MARK: - Forwarded actions

    func joinHost(_ host: DiscoveredHost) {
        (driver as? ClientDriver)?.connect(to: host)
    }

    func startGame() { driver?.startGame() }
    func submitAnswer(_ text: String) {
        // The driver is responsible for setting `hasSubmittedAnswer` once the
        // answer has actually been recorded. Setting it here would race with
        // the driver's own re-entrancy guard and silently drop the answer.
        driver?.submitAnswer(text)
    }
    func nextSlide() { driver?.nextSlide() }
    func kick(_ player: Player) { driver?.kick(player) }
    func leave() { resetForMenu() }

    func updateConfig(_ new: GameConfig) {
        config = new
        driver?.updateConfig(new)
    }

    // MARK: - Helpers

    static func defaultPlayerName() -> String {
        let host = Host.current().localizedName ?? NSUserName()
        let trimmed = host.replacingOccurrences(of: "'s Mac", with: "")
                          .replacingOccurrences(of: " Mac", with: "")
        return String(trimmed.prefix(20))
    }
}

@MainActor
protocol SessionDriver: AnyObject {
    func bootstrap()
    func startGame()
    func submitAnswer(_ text: String)
    func nextSlide()
    func kick(_ player: Player)
    func updateConfig(_ config: GameConfig)
    func leave()
}

extension SessionDriver {
    func startGame() {}
    func submitAnswer(_ text: String) {}
    func nextSlide() {}
    func kick(_ player: Player) {}
    func updateConfig(_ config: GameConfig) {}
    func leave() {}
}
