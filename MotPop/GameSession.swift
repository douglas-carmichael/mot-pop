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
        #if os(macOS)
        let full = NSFullUserName()
        if !full.isEmpty {
            let first = full.components(separatedBy: " ").first ?? full
            return String(first.prefix(20))
        }
        let host = Host.current().localizedName ?? NSUserName()
        let trimmed = host.replacingOccurrences(of: "'s Mac", with: "")
                          .replacingOccurrences(of: " Mac", with: "")
        return String(trimmed.prefix(20))
        #elseif os(tvOS)
        let deviceName = UIDevice.current.name
        let bareNames = ["Apple TV", "Apple\u{00A0}TV"]
        if bareNames.contains(deviceName) {
            return NSLocalizedString("player.guest", value: "Guest", comment: "")
        }
        let suffixes = ["'s Apple TV", "'s Apple\u{00A0}TV",
                        "\u{2019}s Apple TV", "\u{2019}s Apple\u{00A0}TV",
                        " Apple TV", " Apple\u{00A0}TV"]
        for suffix in suffixes {
            if deviceName.hasSuffix(suffix) {
                let name = String(deviceName.dropLast(suffix.count))
                if !name.isEmpty { return String(name.prefix(20)) }
            }
        }
        return NSLocalizedString("player.guest", value: "Guest", comment: "")
        #else
        let name = ProcessInfo.processInfo.hostName
            .replacingOccurrences(of: ".local", with: "")
            .replacingOccurrences(of: "-", with: " ")
        if name.isEmpty { return NSLocalizedString("player.guest", value: "Guest", comment: "") }
        return String(name.prefix(20))
        #endif
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
